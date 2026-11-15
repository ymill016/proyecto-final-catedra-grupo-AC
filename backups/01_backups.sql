/* ===============================================================
   HOTEL GRUPO AC - RESPALDOS INICIALES (PRIMERA INSTALACION)
   Ejecutar UNA SOLA VEZ y en el orden indicado, como sysadmin.
   Requiere: carpeta /backup/HotelGrupoAC creada en Docker.
   Rutas del SERVIDOR Linux, no rutas de Windows.
   ADVERTENCIA: INIT reemplaza el contenido de un archivo del mismo nombre.
   NO repetir si esos archivos ya se estan usando para restauracion.
   =============================================================== */
USE master;
GO

-- Modelo FULL: permite generar respaldos del log.
ALTER DATABASE bd_hotel_grupoAC SET RECOVERY FULL;
GO

-- 1. BACKUP COMPLETO (base para los diferenciales y cadena de log).
BACKUP DATABASE bd_hotel_grupoAC
TO DISK = '/backup/HotelGrupoAC/hotel_full.bak'
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10,
     NAME = N'Backup Completo Inicial Hotel Grupo AC';
GO
RESTORE VERIFYONLY
FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak'
WITH CHECKSUM;
GO

-- 2. BACKUP DIFERENCIAL (cambios desde el FULL base).
BACKUP DATABASE bd_hotel_grupoAC
TO DISK = '/backup/HotelGrupoAC/hotel_diff.bak'
WITH DIFFERENTIAL, INIT, CHECKSUM, COMPRESSION, STATS = 10,
     NAME = N'Backup Diferencial Inicial Hotel Grupo AC';
GO
RESTORE VERIFYONLY
FROM DISK = '/backup/HotelGrupoAC/hotel_diff.bak'
WITH CHECKSUM;
GO

-- 3. BACKUP DEL LOG (registros del log desde el respaldo anterior).
BACKUP LOG bd_hotel_grupoAC
TO DISK = '/backup/HotelGrupoAC/hotel_log.trn'
WITH INIT, CHECKSUM, COMPRESSION, STATS = 10,
     NAME = N'Backup Log Inicial Hotel Grupo AC';
GO
RESTORE VERIFYONLY
FROM DISK = '/backup/HotelGrupoAC/hotel_log.trn'
WITH CHECKSUM;
GO

RESTORE VERIFYONLY FROM DISK = @archivo WITH CHECKSUM;

SELECT @archivo AS archivo_respaldo;
GO
