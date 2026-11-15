/* ===============================================================
   HOTEL GRUPO AC - CREACION INICIAL DE JOBS EN SQL SERVER AGENT
   NO ES UN SCRIPT DE ACTUALIZACION NI UN SCRIPT IDEMPOTENTE.
   Ejecutar UNA SOLA VEZ en un servidor sin estos tres jobs.
   Si los jobs ya existen, NO ejecutar: no se eliminan ni duplican.

   Se requiere: bd_hotel_grupoAC, modelo FULL y backup FULL inicial,
   carpeta /backup/HotelGrupoAC existente y SQL Server Agent activo.
   Servidor configurado en UTC (comprobado en el entorno del proyecto).

   FULL: domingo 08:00 UTC = domingo 02:00 de El Salvador.
   DIFF: lunes a sabado 08:00 UTC = 02:00 de El Salvador.
   LOG: todos los dias 00:05-23:50 UTC, cada 15 min.

   Usa nombres unicos: NO sobrescribe respaldos anteriores.
   Cada job verifica el respaldo y reintenta hasta dos veces.
   =============================================================== */
USE msdb;
GO

DECLARE @fecha_inicio INT = CONVERT(INT, CONVERT(CHAR(8), GETDATE(), 112));

-- 1. COMPLETO SEMANAL
EXEC dbo.sp_add_job
    @job_name = N'HotelAC_FULL_semanal',
    @enabled = 1,
    @description = N'Completo semanal y verificacion de bd_hotel_grupoAC',
    @notify_level_eventlog = 2;

EXEC dbo.sp_add_jobstep
    @job_name = N'HotelAC_FULL_semanal',
    @step_name = N'Respaldar y verificar',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'DECLARE @archivo NVARCHAR(4000) = CONCAT(
    N''/backup/HotelGrupoAC/HotelGrupoAC_FULL_'',
    CONVERT(CHAR(8), SYSDATETIME(), 112), N''_'',
    REPLACE(CONVERT(CHAR(8), SYSDATETIME(), 108), N'':'', N''''), N''_'',
    CONVERT(NVARCHAR(36), NEWID()), N''.bak'');

BACKUP DATABASE bd_hotel_grupoAC
TO DISK = @archivo
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10,
     NAME = N''Backup Completo Hotel Grupo AC'';

RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
SELECT @archivo AS archivo_respaldo;',
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

-- 2. DIFERENCIAL LUNES A SABADO
EXEC dbo.sp_add_job
    @job_name = N'HotelAC_DIFF_diario',
    @enabled = 1,
    @description = N'Diferencial diario y verificacion de bd_hotel_grupoAC',
    @notify_level_eventlog = 2;

EXEC dbo.sp_add_jobstep
    @job_name = N'HotelAC_DIFF_diario',
    @step_name = N'Respaldar y verificar',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'DECLARE @archivo NVARCHAR(4000) = CONCAT(
    N''/backup/HotelGrupoAC/HotelGrupoAC_DIFF_'',
    CONVERT(CHAR(8), SYSDATETIME(), 112), N''_'',
    REPLACE(CONVERT(CHAR(8), SYSDATETIME(), 108), N'':'', N''''), N''_'',
    CONVERT(NVARCHAR(36), NEWID()), N''.bak'');

BACKUP DATABASE bd_hotel_grupoAC
TO DISK = @archivo
WITH DIFFERENTIAL, INIT, COMPRESSION, CHECKSUM, STATS = 10,
     NAME = N''Backup Diferencial Hotel Grupo AC'';

RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
SELECT @archivo AS archivo_respaldo;',
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

-- 3. LOG CADA 15 MINUTOS
EXEC dbo.sp_add_job
    @job_name = N'HotelAC_LOG_15min',
    @enabled = 1,
    @description = N'Log cada 15 minutos y verificacion de bd_hotel_grupoAC',
    @notify_level_eventlog = 2;

EXEC dbo.sp_add_jobstep
    @job_name = N'HotelAC_LOG_15min',
    @step_name = N'Respaldar y verificar',
    @subsystem = N'TSQL',
    @database_name = N'master',
    @command = N'DECLARE @archivo NVARCHAR(4000) = CONCAT(
    N''/backup/HotelGrupoAC/HotelGrupoAC_LOG_'',
    CONVERT(CHAR(8), SYSDATETIME(), 112), N''_'',
    REPLACE(CONVERT(CHAR(8), SYSDATETIME(), 108), N'':'', N''''), N''_'',
    CONVERT(NVARCHAR(36), NEWID()), N''.trn'');

BACKUP LOG bd_hotel_grupoAC
TO DISK = @archivo
WITH INIT, COMPRESSION, CHECKSUM, STATS = 10,
     NAME = N''Backup Log Hotel Grupo AC'';

RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
SELECT @archivo AS archivo_respaldo;',
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
