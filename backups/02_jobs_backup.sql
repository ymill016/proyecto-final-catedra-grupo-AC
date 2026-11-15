/* ===============================================================
   HOTEL GRUPO AC - CREACION INICIAL DE JOBS SQL SERVER AGENT

   Ejecutar UNA SOLA VEZ como sysadmin.
   No elimina ni modifica jobs existentes.

   REQUISITOS:
   - bd_hotel_grupoAC en modelo FULL.
   - Backup FULL inicial realizado.
   - Carpeta /backup/HotelGrupoAC existente.
   - SQL Server Agent activo.
   - Login de servidor login_jobs_hotel existente.
   - Usuario en bd_hotel_grupoAC con db_backupoperator.
   - Usuario en msdb con SQLAgentUserRole.
   - Servidor configurado en UTC.

   PROPIETARIO: login_jobs_hotel.

   PROGRAMACION:
   FULL: domingo 08:00 UTC (02:00 El Salvador).
   DIFF: lunes a sabado 08:00 UTC (02:00 El Salvador).
   LOG: todos los dias, 00:05-23:50 UTC, cada 15 minutos.

   Los respaldos tienen nombres unicos.
   Utilizan CHECKSUM, COMPRESSION y hasta 2 reintentos.
   No utilizan RESTORE VERIFYONLY.
   =============================================================== */

USE msdb;
GO

-- VALIDACIONES INICIALES
IF IS_SRVROLEMEMBER(N'sysadmin') <> 1
    THROW 50001, N'Este script requiere sysadmin.', 1;

IF SUSER_ID(N'login_jobs_hotel') IS NULL
    THROW 50002, N'No existe login_jobs_hotel.', 1;

IF DB_ID(N'bd_hotel_grupoAC') IS NULL
    THROW 50003, N'No existe bd_hotel_grupoAC.', 1;

IF EXISTS (
    SELECT 1
    FROM dbo.sysjobs
    WHERE name IN (
        N'HotelAC_FULL_semanal',
        N'HotelAC_DIFF_diario',
        N'HotelAC_LOG_15min'
    )
)
    THROW 50004, N'Uno o mas jobs ya existen. No ejecutar nuevamente.', 1;

DECLARE @fecha_inicio INT =
    CONVERT(INT, CONVERT(CHAR(8), GETDATE(), 112));


/* ===============================================================
   1. BACKUP COMPLETO - DOMINGO
   =============================================================== */

EXEC dbo.sp_add_job
    @job_name = N'HotelAC_FULL_semanal',
    @enabled = 1,
    @description = N'Respaldo completo semanal de bd_hotel_grupoAC',
    @owner_login_name = N'login_jobs_hotel',
    @notify_level_eventlog = 2;

EXEC dbo.sp_add_jobstep
    @job_name = N'HotelAC_FULL_semanal',
    @step_name = N'Ejecutar respaldo FULL',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
DECLARE @archivo NVARCHAR(4000) = CONCAT(
    N''/backup/HotelGrupoAC/HotelGrupoAC_FULL_'',
    CONVERT(CHAR(8), SYSDATETIME(), 112),
    N''_'',
    REPLACE(CONVERT(CHAR(8), SYSDATETIME(), 108), N'':'', N''''),
    N''_'',
    CONVERT(NVARCHAR(36), NEWID()),
    N''.bak''
);

BACKUP DATABASE bd_hotel_grupoAC
TO DISK = @archivo
WITH INIT,
     COMPRESSION,
     CHECKSUM,
     STATS = 10,
     NAME = N''Backup Completo Hotel Grupo AC'';

SELECT @archivo AS archivo_respaldo;
',
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 2,
    @retry_interval = 1;

EXEC dbo.sp_add_jobschedule
    @job_name = N'HotelAC_FULL_semanal',
    @name = N'HotelAC_Domingo_0800_UTC',
    @enabled = 1,
    @freq_type = 8,
    @freq_interval = 1,
    @freq_recurrence_factor = 1,
    @freq_subday_type = 1,
    @active_start_time = 80000,
    @active_start_date = @fecha_inicio;

EXEC dbo.sp_add_jobserver
    @job_name = N'HotelAC_FULL_semanal',
    @server_name = N'(LOCAL)';


/* ===============================================================
   2. BACKUP DIFERENCIAL - LUNES A SABADO
   =============================================================== */

EXEC dbo.sp_add_job
    @job_name = N'HotelAC_DIFF_diario',
    @enabled = 1,
    @description = N'Respaldo diferencial de lunes a sabado',
    @owner_login_name = N'login_jobs_hotel',
    @notify_level_eventlog = 2;

EXEC dbo.sp_add_jobstep
    @job_name = N'HotelAC_DIFF_diario',
    @step_name = N'Ejecutar respaldo DIFF',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
DECLARE @archivo NVARCHAR(4000) = CONCAT(
    N''/backup/HotelGrupoAC/HotelGrupoAC_DIFF_'',
    CONVERT(CHAR(8), SYSDATETIME(), 112),
    N''_'',
    REPLACE(CONVERT(CHAR(8), SYSDATETIME(), 108), N'':'', N''''),
    N''_'',
    CONVERT(NVARCHAR(36), NEWID()),
    N''.bak''
);

BACKUP DATABASE bd_hotel_grupoAC
TO DISK = @archivo
WITH DIFFERENTIAL,
     INIT,
     COMPRESSION,
     CHECKSUM,
     STATS = 10,
     NAME = N''Backup Diferencial Hotel Grupo AC'';

SELECT @archivo AS archivo_respaldo;
',
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 2,
    @retry_interval = 1;

EXEC dbo.sp_add_jobschedule
    @job_name = N'HotelAC_DIFF_diario',
    @name = N'HotelAC_Lunes_Sabado_0800_UTC',
    @enabled = 1,
    @freq_type = 8,
    @freq_interval = 126,
    @freq_recurrence_factor = 1,
    @freq_subday_type = 1,
    @active_start_time = 80000,
    @active_start_date = @fecha_inicio;

EXEC dbo.sp_add_jobserver
    @job_name = N'HotelAC_DIFF_diario',
    @server_name = N'(LOCAL)';


/* ===============================================================
   3. BACKUP DEL LOG - CADA 15 MINUTOS
   =============================================================== */

EXEC dbo.sp_add_job
    @job_name = N'HotelAC_LOG_15min',
    @enabled = 1,
    @description = N'Respaldo del log de transacciones cada 15 minutos',
    @owner_login_name = N'login_jobs_hotel',
    @notify_level_eventlog = 2;

EXEC dbo.sp_add_jobstep
    @job_name = N'HotelAC_LOG_15min',
    @step_name = N'Ejecutar respaldo LOG',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'
DECLARE @archivo NVARCHAR(4000) = CONCAT(
    N''/backup/HotelGrupoAC/HotelGrupoAC_LOG_'',
    CONVERT(CHAR(8), SYSDATETIME(), 112),
    N''_'',
    REPLACE(CONVERT(CHAR(8), SYSDATETIME(), 108), N'':'', N''''),
    N''_'',
    CONVERT(NVARCHAR(36), NEWID()),
    N''.trn''
);

BACKUP LOG bd_hotel_grupoAC
TO DISK = @archivo
WITH INIT,
     COMPRESSION,
     CHECKSUM,
     STATS = 10,
     NAME = N''Backup Log Hotel Grupo AC'';

SELECT @archivo AS archivo_respaldo;
',
    @on_success_action = 1,
    @on_fail_action = 2,
    @retry_attempts = 2,
    @retry_interval = 1;

EXEC dbo.sp_add_jobschedule
    @job_name = N'HotelAC_LOG_15min',
    @name = N'HotelAC_Diario_cada15min_0005_2350_UTC',
    @enabled = 1,
    @freq_type = 4,
    @freq_interval = 1,
    @freq_subday_type = 4,
    @freq_subday_interval = 15,
    @active_start_time = 500,
    @active_end_time = 235000,
    @active_start_date = @fecha_inicio;

EXEC dbo.sp_add_jobserver
    @job_name = N'HotelAC_LOG_15min',
    @server_name = N'(LOCAL)';

GO

/* ===============================================================
   VERIFICACION DE LOS JOBS
   =============================================================== */

SELECT
    j.name AS nombre_job,
    SUSER_SNAME(j.owner_sid) AS propietario,
    CASE
        WHEN j.enabled = 1 THEN N'Habilitado'
        ELSE N'Deshabilitado'
    END AS estado
FROM msdb.dbo.sysjobs AS j
WHERE j.name IN (
    N'HotelAC_FULL_semanal',
    N'HotelAC_DIFF_diario',
    N'HotelAC_LOG_15min'
)
ORDER BY j.name;
GO
