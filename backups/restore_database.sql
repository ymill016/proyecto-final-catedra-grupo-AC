/* ============================================================
   HOTEL GRUPO AC - RESTAURACION DE PRUEBA

   El origen bd_hotel_grupoAC NUNCA se borra ni sobrescribe.
   Destino nuevo: bd_hotel_grupoAC_prueba.

   DEMO CORTA: FULL > cambio > DIFF > cambio > LOG > RESTORE.
   Este script restaura UN solo archivo log. Solo sirve cuando
   ese log es el primero necesario despues del diferencial.
   Si hay otros logs intermedios, RESTAURARLOS TODOS en orden
   antes de WITH RECOVERY (ver README.md).

   Reemplace tres rutas obtenidas al ejecutar los backups.
   ============================================================ */
USE master;
GO
SET NOCOUNT ON;

DECLARE @full NVARCHAR(4000) = N'PEGAR_RUTA_DEL_FULL';
DECLARE @diff NVARCHAR(4000) = N'PEGAR_RUTA_DEL_DIFF';
DECLARE @log  NVARCHAR(4000) = N'PEGAR_RUTA_DEL_LOG';
DECLARE @destino SYSNAME = N'bd_hotel_grupoAC_prueba';

IF @full LIKE N'PEGAR_RUTA%' OR @diff LIKE N'PEGAR_RUTA%'
   OR @log LIKE N'PEGAR_RUTA%'
    THROW 51100, 'Pegue las rutas de los tres archivos de respaldo.', 1;
IF DB_ID(N'bd_hotel_grupoAC') IS NULL
    THROW 51101, 'La base original debe estar disponible para esta demostracion.', 1;
IF DB_ID(@destino) IS NOT NULL
    THROW 51102, 'La base de prueba ya existe. No se sobrescribe.', 1;

-- El backup conserva los nombres logicos de los archivos de origen.
-- El proyecto utiliza un archivo de datos (.mdf) y uno de log (.ldf).
DECLARE @logicoDatos SYSNAME, @logicoLog SYSNAME;
SELECT TOP (1) @logicoDatos = name
FROM sys.master_files
WHERE database_id = DB_ID(N'bd_hotel_grupoAC') AND type_desc = N'ROWS'
ORDER BY file_id;
SELECT TOP (1) @logicoLog = name
FROM sys.master_files
WHERE database_id = DB_ID(N'bd_hotel_grupoAC') AND type_desc = N'LOG'
ORDER BY file_id;
IF @logicoDatos IS NULL OR @logicoLog IS NULL
    THROW 51103, 'No se encontraron nombres logicos de datos/log.', 1;

DECLARE @datosDir NVARCHAR(4000) =
    CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultDataPath'));
DECLARE @logDir NVARCHAR(4000) =
    CONVERT(NVARCHAR(4000), SERVERPROPERTY('InstanceDefaultLogPath'));
IF NULLIF(@datosDir, N'') IS NULL OR NULLIF(@logDir, N'') IS NULL
    THROW 51104, 'No se detectaron carpetas DATA y LOG del servidor.', 1;
IF RIGHT(@datosDir, 1) NOT IN (N'\', N'/')
    SET @datosDir = @datosDir + CASE WHEN CHARINDEX(N'/', @datosDir) > 0 THEN N'/' ELSE N'\' END;
IF RIGHT(@logDir, 1) NOT IN (N'\', N'/')
    SET @logDir = @logDir + CASE WHEN CHARINDEX(N'/', @logDir) > 0 THEN N'/' ELSE N'\' END;

DECLARE @archivoDatos NVARCHAR(4000) = @datosDir + @destino + N'.mdf';
DECLARE @archivoLog NVARCHAR(4000) = @logDir + @destino + N'_log.ldf';
DECLARE @inicio DATETIME2(3) = SYSDATETIME();
DECLARE @sql NVARCHAR(MAX);

PRINT N'1/4 Restaurando respaldo completo...';
SET @sql = N'RESTORE DATABASE ' + QUOTENAME(@destino)
    + N' FROM DISK = N''' + REPLACE(@full, N'''', N'''''') + N'''
       WITH MOVE N''' + REPLACE(@logicoDatos, N'''', N'''''')
    + N''' TO N''' + REPLACE(@archivoDatos, N'''', N'''''')
    + N''', MOVE N''' + REPLACE(@logicoLog, N'''', N'''''')
    + N''' TO N''' + REPLACE(@archivoLog, N'''', N'''''')
    + N''', NORECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @sql;

PRINT N'2/4 Restaurando respaldo diferencial...';
SET @sql = N'RESTORE DATABASE ' + QUOTENAME(@destino)
    + N' FROM DISK = N''' + REPLACE(@diff, N'''', N'''''')
    + N''' WITH NORECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @sql;

PRINT N'3/4 Restaurando respaldo de log...';
SET @sql = N'RESTORE LOG ' + QUOTENAME(@destino)
    + N' FROM DISK = N''' + REPLACE(@log, N'''', N'''''')
    + N''' WITH NORECOVERY, CHECKSUM, STATS = 10;';
EXEC sys.sp_executesql @sql;

PRINT N'4/4 Abriendo la base de prueba...';
SET @sql = N'RESTORE DATABASE ' + QUOTENAME(@destino) + N' WITH RECOVERY;';
EXEC sys.sp_executesql @sql;

SELECT name AS base_restaurada, state_desc,
       DATEDIFF(SECOND, @inicio, SYSDATETIME()) AS segundos_restauracion
FROM sys.databases
WHERE name = @destino;

-- Evidencia de la demo: deben aparecer las 3 etapas si se hizo el Paso A.
IF OBJECT_ID(N'bd_hotel_grupoAC_prueba.dbo.demo_backup_AC', N'U') IS NOT NULL
    SELECT id, etapa, fecha
    FROM bd_hotel_grupoAC_prueba.dbo.demo_backup_AC
    ORDER BY id;
ELSE
    PRINT N'Base restaurada. No se encontro la tabla de demo (es opcional).';
GO
