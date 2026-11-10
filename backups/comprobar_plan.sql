/* ============================================================
   HOTEL GRUPO AC - COMPROBAR QUE EL PLAN DE BACKUP FUNCIONA
   Solo LEE: no crea respaldos, no restaura, no cambia jobs.
   Ejecutar completo en SSMS (o sqlcmd) despues de la demo.

   1. Los jobs existen, tienen horario y su ultimo resultado.
   2. La cadena de respaldos no tiene huecos (LSN).
   3. Los ultimos archivos FULL / DIFF / LOG se pueden leer.
   4. La base restaurada esta sana (DBCC CHECKDB) y con datos.
   ============================================================ */
USE msdb;
GO
SET NOCOUNT ON;

PRINT N'== 1. Jobs, horario y ultimo resultado ==';
SELECT
    j.name AS job,
    CASE j.enabled WHEN 1 THEN 'Habilitado' ELSE 'Deshabilitado' END AS estado,
    s.name AS calendario,
    CASE WHEN h.run_status IS NULL THEN 'Aun no ejecutado'
         WHEN h.run_status = 1 THEN 'Correcto'
         WHEN h.run_status = 0 THEN 'Fallido'
         ELSE 'Revisar historial' END AS ultimo_resultado,
    msdb.dbo.agent_datetime(h.run_date, h.run_time) AS ultima_ejecucion
FROM msdb.dbo.sysjobs AS j
LEFT JOIN msdb.dbo.sysjobschedules AS js ON js.job_id = j.job_id
LEFT JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
OUTER APPLY (
    SELECT TOP (1) run_status, run_date, run_time
    FROM msdb.dbo.sysjobhistory
    WHERE job_id = j.job_id AND step_id = 0
    ORDER BY instance_id DESC
) AS h
WHERE j.name IN (N'AC_Backup_FULL', N'AC_Backup_DIFF', N'AC_Backup_LOG')
ORDER BY j.name;

PRINT N'== 2. Cadena de respaldos (cada LOG debe empezar donde termino el anterior) ==';
WITH respaldos AS (
    SELECT
        b.backup_set_id,
        CASE b.type WHEN 'D' THEN 'FULL' WHEN 'I' THEN 'DIFF' WHEN 'L' THEN 'LOG' END AS tipo,
        b.backup_start_date AS inicio,
        b.first_lsn, b.last_lsn, b.checkpoint_lsn, b.database_backup_lsn,
        b.has_backup_checksums,
        m.physical_device_name AS archivo,
        -- ultimo LSN del LOG anterior (funcion ventana sobre los logs)
        LAG(CASE WHEN b.type = 'L' THEN b.last_lsn END) OVER (
            PARTITION BY CASE WHEN b.type = 'L' THEN 1 ELSE 0 END
            ORDER BY b.backup_set_id) AS last_lsn_log_anterior
    FROM msdb.dbo.backupset AS b
    INNER JOIN msdb.dbo.backupmediafamily AS m ON m.media_set_id = b.media_set_id
    WHERE b.database_name = N'bd_hotel_grupoAC'
)
SELECT
    r.tipo, r.inicio, r.has_backup_checksums AS con_checksum,
    CASE
        WHEN r.tipo = 'LOG' AND r.last_lsn_log_anterior IS NULL THEN 'OK (primer log)'
        WHEN r.tipo = 'LOG' AND r.first_lsn = r.last_lsn_log_anterior THEN 'OK (continua)'
        WHEN r.tipo = 'LOG' THEN 'HUECO EN LA CADENA'
        WHEN r.tipo = 'DIFF' AND EXISTS (SELECT 1 FROM respaldos AS f
             WHERE f.tipo = 'FULL' AND f.checkpoint_lsn = r.database_backup_lsn) THEN 'OK (su FULL existe)'
        WHEN r.tipo = 'DIFF' THEN 'FALTA SU FULL'
        ELSE 'OK (inicio de cadena)'
    END AS cadena,
    r.archivo
FROM respaldos AS r
ORDER BY r.backup_set_id;

PRINT N'== 3. Lectura de los ultimos archivos FULL, DIFF y LOG ==';
DECLARE @tipo CHAR(1), @archivo NVARCHAR(4000), @sql NVARCHAR(MAX);
DECLARE ultimos CURSOR LOCAL FAST_FORWARD FOR
    SELECT t.type, t.physical_device_name
    FROM (
        SELECT b.type, m.physical_device_name,
               ROW_NUMBER() OVER (PARTITION BY b.type ORDER BY b.backup_set_id DESC) AS n
        FROM msdb.dbo.backupset AS b
        INNER JOIN msdb.dbo.backupmediafamily AS m ON m.media_set_id = b.media_set_id
        WHERE b.database_name = N'bd_hotel_grupoAC'
    ) AS t
    WHERE t.n = 1;
OPEN ultimos;
FETCH NEXT FROM ultimos INTO @tipo, @archivo;
WHILE @@FETCH_STATUS = 0
BEGIN
    PRINT N'Verificando (' + @tipo + N'): ' + @archivo;
    SET @sql = N'RESTORE VERIFYONLY FROM DISK = N''' + REPLACE(@archivo, N'''', N'''''') + N''' WITH CHECKSUM;';
    EXEC sys.sp_executesql @sql;
    FETCH NEXT FROM ultimos INTO @tipo, @archivo;
END;
CLOSE ultimos;
DEALLOCATE ultimos;
GO

PRINT N'== 4. Base restaurada: integridad y datos ==';
IF DB_ID(N'bd_hotel_grupoAC_prueba') IS NULL
    PRINT N'No existe bd_hotel_grupoAC_prueba: ejecute primero restore_database.sql.';
ELSE
BEGIN
    DBCC CHECKDB (N'bd_hotel_grupoAC_prueba') WITH NO_INFOMSGS;
    PRINT N'DBCC CHECKDB sin errores en bd_hotel_grupoAC_prueba.';
    SELECT 'original' AS base,
           (SELECT COUNT(*) FROM bd_hotel_grupoAC.operaciones.reservacion) AS reservas,
           (SELECT COUNT(*) FROM bd_hotel_grupoAC.operaciones.huesped) AS huespedes
    UNION ALL
    SELECT 'restaurada',
           (SELECT COUNT(*) FROM bd_hotel_grupoAC_prueba.operaciones.reservacion),
           (SELECT COUNT(*) FROM bd_hotel_grupoAC_prueba.operaciones.huesped);
    IF OBJECT_ID(N'bd_hotel_grupoAC_prueba.dbo.demo_backup_AC', N'U') IS NOT NULL
        SELECT id, etapa, fecha FROM bd_hotel_grupoAC_prueba.dbo.demo_backup_AC ORDER BY id;
END;
GO
