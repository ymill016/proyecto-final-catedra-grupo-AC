/* ===============================================================
   HOTEL GRUPO AC - EVIDENCIA DE RESPALDOS Y JOBS
   Solo lectura: no modifica los trabajos ni borra archivos.
   Ejecute despues de 01, 02 y de iniciar los jobs manualmente.
   =============================================================== */
USE master;
GO

-- 1. Modelo de recuperacion y zona horaria del servidor.
SELECT name, recovery_model_desc, state_desc
FROM sys.databases
WHERE name = N'bd_hotel_grupoAC';

SELECT SYSDATETIMEOFFSET() AS hora_del_servidor;
GO

USE msdb;
GO

-- 2. Jobs, calendario y horario del servidor (formato HHMMSS).
SELECT
    j.name AS job,
    j.enabled AS job_habilitado,
    SUSER_SNAME(j.owner_sid) AS propietario,
    s.name AS programacion,
    s.enabled AS horario_habilitado,
    s.freq_type, s.freq_interval,
    s.freq_subday_type, s.freq_subday_interval,
    s.active_start_time, s.active_end_time
FROM dbo.sysjobs AS j
INNER JOIN dbo.sysjobschedules AS js ON j.job_id = js.job_id
INNER JOIN dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
WHERE j.name IN (
    N'HotelAC_FULL_semanal', N'HotelAC_DIFF_diario', N'HotelAC_LOG_15min'
)
ORDER BY j.name;
GO

-- 3. Comprobar que TODOS los pasos usen la carpeta del hotel.
SELECT
    j.name AS job, s.step_name AS paso,
    CASE WHEN s.command LIKE N'%/backup/HotelGrupoAC/%'
         THEN N'OK: carpeta del hotel' ELSE N'REVISAR RUTA' END AS ruta,
    s.retry_attempts AS reintentos,
    s.retry_interval AS minutos_entre_reintentos,
    s.command AS codigo_job
FROM dbo.sysjobs AS j
INNER JOIN dbo.sysjobsteps AS s ON s.job_id = j.job_id
WHERE j.name IN (
    N'HotelAC_FULL_semanal', N'HotelAC_DIFF_diario', N'HotelAC_LOG_15min'
)
ORDER BY j.name;
GO

-- 4. Historial global: step_id=0, run_status=1 significa SUCCEEDED.
SELECT TOP (30)
    j.name AS job,
    h.run_date, h.run_time, h.run_duration,
    h.run_status, h.message
FROM dbo.sysjobhistory AS h
INNER JOIN dbo.sysjobs AS j ON h.job_id = j.job_id
WHERE h.step_id = 0
  AND j.name IN (
    N'HotelAC_FULL_semanal', N'HotelAC_DIFF_diario', N'HotelAC_LOG_15min'
  )
ORDER BY h.instance_id DESC;
GO

-- 5. Archivos realmente registrados por SQL Server.
-- D=FULL; I=DIFF; L=LOG.
SELECT TOP (100)
    b.type AS tipo,
    b.backup_start_date, b.backup_finish_date,
    b.has_backup_checksums,
    CAST(b.compressed_backup_size / 1048576.0 AS DECIMAL(18,3)) AS tamano_mb,
    f.physical_device_name AS archivo
FROM dbo.backupset AS b
INNER JOIN dbo.backupmediafamily AS f ON b.media_set_id = f.media_set_id
WHERE b.database_name = N'bd_hotel_grupoAC'
ORDER BY b.backup_finish_date DESC;
GO
