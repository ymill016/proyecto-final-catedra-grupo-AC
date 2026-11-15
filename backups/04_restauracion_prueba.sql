/* ===============================================================
   HOTEL GRUPO AC - RESTAURACION (FULL + DIFF + LOG)
   Ejecutar conectado como login_restore_hotel (rol dbcreator).
   Restaura en una base NUEVA: bd_hotel_grupoAC_prueba.
   NO modifica la base original bd_hotel_grupoAC.

   Requisitos:
   - Archivos en /backup/HotelGrupoAC: hotel_full.bak, hotel_diff.bak,
     hotel_log.trn (generados por los jobs en este orden: FULL, DIFF, LOG).
   - El usuario mssql del contenedor debe poder leer esa carpeta.
   - Que NO corra otro job FULL/DIFF/LOG entre generar los archivos y
     restaurarlos, porque INIT sobrescribe los archivos y rompe la cadena.
   =============================================================== */
USE master;
GO

-- 1. Revisar los nombres LOGICOS de los archivos del backup.
--    Deben ser bd_hotel_grupoAC y bd_hotel_grupoAC_log; si difieren,
--    cambiar los dos MOVE del paso 3.
RESTORE FILELISTONLY
FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak';
GO

-- 2. Revisar que los tres archivos forman una cadena valida.
RESTORE HEADERONLY FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak';
RESTORE HEADERONLY FROM DISK = '/backup/HotelGrupoAC/hotel_diff.bak';
RESTORE HEADERONLY FROM DISK = '/backup/HotelGrupoAC/hotel_log.trn';
GO

-- 3. Restaurar. La base destino NO debe existir.
IF DB_ID(N'bd_hotel_grupoAC_prueba') IS NOT NULL
    THROW 50011, N'bd_hotel_grupoAC_prueba ya existe; no se sobrescribira.', 1;

-- 3.1 FULL: base queda en RESTORING (NORECOVERY)
RESTORE DATABASE bd_hotel_grupoAC_prueba
FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak'
WITH FILE = 1, NORECOVERY, STATS = 10,
     MOVE N'bd_hotel_grupoAC'
       TO N'/var/opt/mssql/data/bd_hotel_grupoAC_prueba.mdf',
     MOVE N'bd_hotel_grupoAC_log'
       TO N'/var/opt/mssql/data/bd_hotel_grupoAC_prueba_log.ldf';

-- 3.2 DIFF: sigue en RESTORING (NORECOVERY)
RESTORE DATABASE bd_hotel_grupoAC_prueba
FROM DISK = '/backup/HotelGrupoAC/hotel_diff.bak'
WITH FILE = 1, NORECOVERY, STATS = 10;

-- 3.3 LOG: cierra la cadena y deja la base ONLINE (RECOVERY)
RESTORE LOG bd_hotel_grupoAC_prueba
FROM DISK = '/backup/HotelGrupoAC/hotel_log.trn'
WITH FILE = 1, RECOVERY, STATS = 10;
GO

/* Si el RESTORE LOG falla (log fuera de secuencia o demasiado reciente),
   la base queda en RESTORING. Cerrarla con FULL + DIFF solamente:

RESTORE DATABASE bd_hotel_grupoAC_prueba WITH RECOVERY;
*/

-- 4. Verificar
SELECT name, state_desc
FROM sys.databases
WHERE name IN (N'bd_hotel_grupoAC', N'bd_hotel_grupoAC_prueba');
GO

DBCC CHECKDB (N'bd_hotel_grupoAC_prueba') WITH NO_INFOMSGS;
GO

USE bd_hotel_grupoAC_prueba;
SELECT s.name AS esquema, t.name AS tabla
FROM sys.tables AS t
JOIN sys.schemas AS s ON s.schema_id = t.schema_id
ORDER BY s.name, t.name;
GO

/* ===============================================================
   OPCIONAL - RESTAURAR SOBRE LA BASE REAL (simulacion de falla)
   Solo si el profesor pide recuperar bd_hotel_grupoAC despues de
   perderla. Descomentar y ejecutar manualmente, en orden.
   Si la base fue eliminada con DROP DATABASE, quitar REPLACE y los MOVE.

USE master;
RESTORE DATABASE bd_hotel_grupoAC
FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak'
WITH FILE = 1, REPLACE, NORECOVERY, STATS = 10;

RESTORE DATABASE bd_hotel_grupoAC
FROM DISK = '/backup/HotelGrupoAC/hotel_diff.bak'
WITH FILE = 1, NORECOVERY, STATS = 10;

RESTORE LOG bd_hotel_grupoAC
FROM DISK = '/backup/HotelGrupoAC/hotel_log.trn'
WITH FILE = 1, RECOVERY, STATS = 10;
   =============================================================== */
