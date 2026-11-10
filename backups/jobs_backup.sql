/* ============================================================
   HOTEL GRUPO AC - JOBS DE SQL SERVER AGENT

   Crea tres jobs: completo, diferencial y log.
   Requisitos: SQL Server Developer/Standard con SQL Server Agent
   iniciado; usuario con permisos para crear jobs (ideal: sysadmin).
   Ejecutar una unica vez, DESPUES de full_backup.sql.

   IMPORTANTE: Este script crea jobs y sus calendarios; para probar
   cada job manualmente: SQL Server Agent > Jobs > Start Job at Step.
   ============================================================ */
USE msdb;
GO

-- Backup completo semanal. Domingos a las 02:00.
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'AC_Backup_FULL')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = N'AC_Backup_FULL',
        @enabled = 1,
        @description = N'Backup completo semanal. Domingos a las 02:00.';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'AC_Backup_FULL',
        @step_name = N'Crear y verificar backup completo',
        @subsystem = N'TSQL',
        @database_name = N'master',
        @on_success_action = 1,  -- finalizar OK
        @on_fail_action = 2,     -- finalizar con fallo
        @command = N'SET NOCOUNT ON;
IF DB_ID(N''bd_hotel_grupoAC'') IS NULL
    THROW 51000, ''No existe bd_hotel_grupoAC.'', 1;
-- El modelo FULL permite respaldar el registro de transacciones.
IF (SELECT recovery_model_desc FROM sys.databases
    WHERE name = N''bd_hotel_grupoAC'') <> N''FULL''
BEGIN
    ALTER DATABASE [bd_hotel_grupoAC] SET RECOVERY FULL;
END;
-- Carpeta del propio servidor SQL Server (no la carpeta del proyecto Git).
DECLARE @ruta NVARCHAR(4000) =
    CONVERT(NVARCHAR(4000), SERVERPROPERTY(''InstanceDefaultBackupPath''));
IF NULLIF(@ruta, N'''') IS NULL
    THROW 51002, ''No se detecto ruta de backups. Revise la configuracion del servidor.'', 1;
IF RIGHT(@ruta, 1) NOT IN (N''\'', N''/'')
    SET @ruta = @ruta + CASE WHEN CHARINDEX(N''/'', @ruta) > 0 THEN N''/'' ELSE N''\'' END;

-- Cada ejecucion crea su propio archivo y no sobrescribe los anteriores.
DECLARE @ahora DATETIME2(0) = SYSDATETIME();
DECLARE @fecha CHAR(15) = CONVERT(CHAR(8), @ahora, 112) + ''_''
    + REPLACE(CONVERT(CHAR(8), @ahora, 108), '':'', '''');
DECLARE @archivo NVARCHAR(4000) = @ruta + N''bd_hotel_grupoAC_FULL_'' + @fecha + N''.bak'';

BACKUP DATABASE [bd_hotel_grupoAC]
TO DISK = @archivo
WITH INIT, CHECKSUM, STATS = 10,
     NAME = N''Hotel Grupo AC - Completo'';
-- Verifica que SQL Server pueda leer el respaldo.
RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
PRINT N''OK - Backup FULL: '' + @archivo;
';

    EXEC msdb.dbo.sp_add_jobserver @job_name = N'AC_Backup_FULL';
    PRINT N'Job creado: AC_Backup_FULL';
END
ELSE
    PRINT N'El job AC_Backup_FULL ya existe; se revisara su horario.';

-- Calendario semanal: se crea incluso si el job ya existia sin horario.
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'AC_Backup_FULL')
AND NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs AS j
    INNER JOIN msdb.dbo.sysjobschedules AS js ON j.job_id = js.job_id
    INNER JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
    WHERE j.name = N'AC_Backup_FULL' AND s.name = N'AC_FULL_domingo_0200'
)
BEGIN
    EXEC msdb.dbo.sp_add_jobschedule
        @job_name = N'AC_Backup_FULL',
        @name = N'AC_FULL_domingo_0200',
        @enabled = 1,
        @freq_type = 8,
        @freq_interval = 1,
        @freq_recurrence_factor = 1, -- cada semana (obligatorio para freq_type=8)
        @active_start_time = 20000;
    PRINT N'Horario configurado para AC_Backup_FULL.';
END;
GO

-- Backup diferencial, lunes a sabado a las 02:00.
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'AC_Backup_DIFF')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = N'AC_Backup_DIFF',
        @enabled = 1,
        @description = N'Backup diferencial, lunes a sabado a las 02:00.';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'AC_Backup_DIFF',
        @step_name = N'Crear y verificar backup diferencial',
        @subsystem = N'TSQL',
        @database_name = N'master',
        @on_success_action = 1,  -- finalizar OK
        @on_fail_action = 2,     -- finalizar con fallo
        @command = N'SET NOCOUNT ON;
IF DB_ID(N''bd_hotel_grupoAC'') IS NULL
    THROW 51000, ''No existe bd_hotel_grupoAC.'', 1;
-- Carpeta del propio servidor SQL Server (no la carpeta del proyecto Git).
DECLARE @ruta NVARCHAR(4000) =
    CONVERT(NVARCHAR(4000), SERVERPROPERTY(''InstanceDefaultBackupPath''));
IF NULLIF(@ruta, N'''') IS NULL
    THROW 51002, ''No se detecto ruta de backups. Revise la configuracion del servidor.'', 1;
IF RIGHT(@ruta, 1) NOT IN (N''\'', N''/'')
    SET @ruta = @ruta + CASE WHEN CHARINDEX(N''/'', @ruta) > 0 THEN N''/'' ELSE N''\'' END;

-- Cada ejecucion crea su propio archivo y no sobrescribe los anteriores.
DECLARE @ahora DATETIME2(0) = SYSDATETIME();
DECLARE @fecha CHAR(15) = CONVERT(CHAR(8), @ahora, 112) + ''_''
    + REPLACE(CONVERT(CHAR(8), @ahora, 108), '':'', '''');
DECLARE @archivo NVARCHAR(4000) = @ruta + N''bd_hotel_grupoAC_DIFF_'' + @fecha + N''.bak'';

-- Requiere un respaldo FULL previo (sin COPY_ONLY).
BACKUP DATABASE [bd_hotel_grupoAC]
TO DISK = @archivo
WITH DIFFERENTIAL, INIT, CHECKSUM, STATS = 10,
     NAME = N''Hotel Grupo AC - Diferencial'';
-- Verifica que SQL Server pueda leer el respaldo.
RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
PRINT N''OK - Backup DIFF: '' + @archivo;
';

    EXEC msdb.dbo.sp_add_jobserver @job_name = N'AC_Backup_DIFF';
    PRINT N'Job creado: AC_Backup_DIFF';
END
ELSE
    PRINT N'El job AC_Backup_DIFF ya existe; se revisara su horario.';

-- Calendario semanal: se crea incluso si el job ya existia sin horario.
IF EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'AC_Backup_DIFF')
AND NOT EXISTS (
    SELECT 1
    FROM msdb.dbo.sysjobs AS j
    INNER JOIN msdb.dbo.sysjobschedules AS js ON j.job_id = js.job_id
    INNER JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
    WHERE j.name = N'AC_Backup_DIFF' AND s.name = N'AC_DIFF_lunes_sabado_0200'
)
BEGIN
    EXEC msdb.dbo.sp_add_jobschedule
        @job_name = N'AC_Backup_DIFF',
        @name = N'AC_DIFF_lunes_sabado_0200',
        @enabled = 1,
        @freq_type = 8,
        @freq_interval = 126,
        @freq_recurrence_factor = 1, -- cada semana (obligatorio para freq_type=8)
        @active_start_time = 20000;
    PRINT N'Horario configurado para AC_Backup_DIFF.';
END;
GO

-- Backup de log cada 30 minutos, a las :15 y :45.
IF NOT EXISTS (SELECT 1 FROM msdb.dbo.sysjobs WHERE name = N'AC_Backup_LOG')
BEGIN
    EXEC msdb.dbo.sp_add_job
        @job_name = N'AC_Backup_LOG',
        @enabled = 1,
        @description = N'Backup de log cada 30 minutos, a las :15 y :45.';

    EXEC msdb.dbo.sp_add_jobstep
        @job_name = N'AC_Backup_LOG',
        @step_name = N'Crear y verificar backup de log',
        @subsystem = N'TSQL',
        @database_name = N'master',
        @on_success_action = 1,  -- finalizar OK
        @on_fail_action = 2,     -- finalizar con fallo
        @command = N'SET NOCOUNT ON;
IF DB_ID(N''bd_hotel_grupoAC'') IS NULL
    THROW 51000, ''No existe bd_hotel_grupoAC.'', 1;
IF (SELECT recovery_model_desc FROM sys.databases
    WHERE name = N''bd_hotel_grupoAC'') <> N''FULL''
    THROW 51001, ''Ejecute primero full_backup.sql para activar FULL y crear la base del log.'', 1;
-- Carpeta del propio servidor SQL Server (no la carpeta del proyecto Git).
DECLARE @ruta NVARCHAR(4000) =
    CONVERT(NVARCHAR(4000), SERVERPROPERTY(''InstanceDefaultBackupPath''));
IF NULLIF(@ruta, N'''') IS NULL
    THROW 51002, ''No se detecto ruta de backups. Revise la configuracion del servidor.'', 1;
IF RIGHT(@ruta, 1) NOT IN (N''\'', N''/'')
    SET @ruta = @ruta + CASE WHEN CHARINDEX(N''/'', @ruta) > 0 THEN N''/'' ELSE N''\'' END;

-- Cada ejecucion crea su propio archivo y no sobrescribe los anteriores.
DECLARE @ahora DATETIME2(0) = SYSDATETIME();
DECLARE @fecha CHAR(15) = CONVERT(CHAR(8), @ahora, 112) + ''_''
    + REPLACE(CONVERT(CHAR(8), @ahora, 108), '':'', '''');
DECLARE @archivo NVARCHAR(4000) = @ruta + N''bd_hotel_grupoAC_LOG_'' + @fecha + N''.trn'';

-- Requiere FULL recovery y un respaldo completo inicial.
BACKUP LOG [bd_hotel_grupoAC]
TO DISK = @archivo
WITH INIT, CHECKSUM, STATS = 10,
     NAME = N''Hotel Grupo AC - Log'';
-- Verifica que SQL Server pueda leer el respaldo.
RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
PRINT N''OK - Backup LOG: '' + @archivo;
';

    EXEC msdb.dbo.sp_add_jobschedule
        @job_name = N'AC_Backup_LOG',
        @name = N'AC_LOG_cada_30_min',
        @enabled = 1,
        @freq_type = 4,
        @freq_interval = 1,
        @active_start_time = 1500,
        @freq_subday_type = 4,
        @freq_subday_interval = 30,
        @active_end_time = 234500;

    EXEC msdb.dbo.sp_add_jobserver @job_name = N'AC_Backup_LOG';
    PRINT N'Job creado: AC_Backup_LOG';
END
ELSE
    PRINT N'El job AC_Backup_LOG ya existe; no se modifica.';
GO
