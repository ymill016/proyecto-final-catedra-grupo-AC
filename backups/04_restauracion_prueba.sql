/* ===============================================================
   HOTEL GRUPO AC - PRUEBA DE RESTAURACION SIN BORRAR LA ORIGINAL
   EJECUCION MANUAL Y CONTROLADA.

   1) Primero ejecutar RESTORE FILELISTONLY y confirmar los nombres
      LOGICOS de los archivos en el backup completo.
   2) Revisar/ajustar los dos MOVE siguientes si difieren.
   3) Requiere archivos INICIALES del script 01 compatibles.
   4) Crea bd_hotel_grupoAC_prueba; NO modifica la original.
   5) No ejecutar si ya existe bd_hotel_grupoAC_prueba.
   =============================================================== */
USE master;
GO
RESTORE FILELISTONLY
FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak';
GO

-- Revisar los nombres LOGICOS en la salida anterior.
-- El CREATE DATABASE original usa bd_hotel_grupoAC, pero si
-- FILELISTONLY muestra otros nombres, cambiar los MOVE.
IF DB_ID(N'bd_hotel_grupoAC_prueba') IS NOT NULL
    THROW 50011, N'La base de prueba ya existe; no se sobrescribira.', 1;

-- EJECUTAR solo despues de comprobar los nombres de FILELISTONLY.
RESTORE DATABASE bd_hotel_grupoAC_prueba
FROM DISK = '/backup/HotelGrupoAC/hotel_full.bak'
WITH NORECOVERY,
     MOVE N'bd_hotel_grupoAC'
       TO N'/var/opt/mssql/data/bd_hotel_grupoAC_prueba.mdf',
     MOVE N'bd_hotel_grupoAC_log'
       TO N'/var/opt/mssql/data/bd_hotel_grupoAC_prueba_log.ldf';

RESTORE DATABASE bd_hotel_grupoAC_prueba
FROM DISK = '/backup/HotelGrupoAC/hotel_diff.bak'
WITH NORECOVERY;

RESTORE LOG bd_hotel_grupoAC_prueba
FROM DISK = '/backup/HotelGrupoAC/hotel_log.trn'
WITH RECOVERY;

DBCC CHECKDB (N'bd_hotel_grupoAC_prueba') WITH NO_INFOMSGS;
SELECT name, state_desc
FROM sys.databases
WHERE name IN (N'bd_hotel_grupoAC', N'bd_hotel_grupoAC_prueba');
GO

-- No hay DROP DATABASE: la base de prueba se conserva para evidencia.
-- NOTA: para restaurar respaldos periodicos de los jobs se debe
-- identificar el FULL base, su DIFF compatible y TODOS los LOG
-- necesarios en orden; no basta tomar los archivos mas recientes.
