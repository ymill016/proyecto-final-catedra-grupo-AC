/* =====================================================
   HOTEL GRUPO AC - RESPALDOS MANUALES

   Usuario: login_jobs_hotel
   Rol: db_backupoperator

   Requisitos:
   - Base de datos en modelo FULL.
   - Carpeta /backup/HotelGrupoAC existente.
   - Permisos de escritura en el servidor.

   Respaldos:
   1. Completo
   2. Diferencial
   3. Log de transacciones
   ===================================================== */

USE bd_hotel_grupoAC;
GO

-- Verificar usuario y permisos
SELECT
    SUSER_SNAME() AS login_actual,
    USER_NAME() AS usuario_base,
    IS_MEMBER('db_backupoperator') AS autorizado_backup;
GO

-- 1. RESPALDO COMPLETO
BACKUP DATABASE bd_hotel_grupoAC
TO DISK = '/backup/HotelGrupoAC/hotel_full.bak'
WITH CHECKSUM, COMPRESSION, STATS = 10;
GO

-- 2. RESPALDO DIFERENCIAL
BACKUP DATABASE bd_hotel_grupoAC
TO DISK = '/backup/HotelGrupoAC/hotel_diff.bak'
WITH DIFFERENTIAL, CHECKSUM, COMPRESSION, STATS = 10;
GO

-- 3. RESPALDO DEL LOG
BACKUP LOG bd_hotel_grupoAC
TO DISK = '/backup/HotelGrupoAC/hotel_log.trn'
WITH CHECKSUM, COMPRESSION, STATS = 10;
GO
