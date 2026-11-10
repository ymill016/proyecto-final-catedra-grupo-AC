/* ============================================================
   HOTEL GRUPO AC - BACKUP LOG
   Base: bd_hotel_grupoAC
   Plan: Todos los dias, cada 30 minutos (:15 y :45).
   Ejecutar en SSMS con permisos de respaldo.
   ============================================================ */
USE master;
GO
SET NOCOUNT ON;
IF DB_ID(N'bd_hotel_grupoAC') IS NULL
    THROW 51000, 'No existe bd_hotel_grupoAC.', 1;
IF (SELECT recovery_model_desc FROM sys.databases
    WHERE name = N'bd_hotel_grupoAC') <> N'FULL'
    THROW 51001, 'Ejecute primero full_backup.sql para activar FULL y crear la base del log.', 1;
-- Carpeta del propio servidor SQL Server (no la carpeta del proyecto Git).
DECLARE @ruta NVARCHAR(4000) =
    CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultBackupPath'));
IF NULLIF(@ruta, N'') IS NULL
    THROW 51002, 'No se detecto ruta de backups. Revise la configuracion del servidor.', 1;
IF RIGHT(@ruta, 1) NOT IN (N'\', N'/')
    SET @ruta = @ruta + CASE WHEN CHARINDEX(N'/', @ruta) > 0 THEN N'/' ELSE N'\' END;

-- Cada ejecucion crea su propio archivo y no sobrescribe los anteriores.
DECLARE @ahora DATETIME2(0) = SYSDATETIME();
DECLARE @fecha CHAR(15) = CONVERT(CHAR(8), @ahora, 112) + '_'
    + REPLACE(CONVERT(CHAR(8), @ahora, 108), ':', '');
DECLARE @archivo NVARCHAR(4000) = @ruta + N'bd_hotel_grupoAC_LOG_' + @fecha + N'.trn';

-- Requiere FULL recovery y un respaldo completo inicial.
BACKUP LOG [bd_hotel_grupoAC]
TO DISK = @archivo
WITH INIT, CHECKSUM, STATS = 10,
     NAME = N'Hotel Grupo AC - Log';
-- Verifica que SQL Server pueda leer el respaldo.
RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;
PRINT N'OK - Backup LOG: ' + @archivo;
GO
