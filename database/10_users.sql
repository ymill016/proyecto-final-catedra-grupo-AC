/*============================================================
USUARIOS (BASE DE DATOS AUTOCONTENIDA) - bd_hotel_grupoAC
carlos-> rol_programador
maria-> rol_gerente
luis-> rol_contador
ana-> rol_recepcionista
james-> rol_profesor
============================================================*/

-- Habilitar la autenticación autocontenida en el servidor
USE master;
GO
EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

-- Convertir la base del hotel en autocontenida
ALTER DATABASE bd_hotel_grupoAA SET CONTAINMENT = PARTIAL;
GO

-- Crear usuarios con contraseña dentro de la base de datos
USE bd_hotel_grupoAC;
GO

CREATE USER carlos WITH PASSWORD = '1234!';
CREATE USER maria WITH PASSWORD = '1234!';
CREATE USER luis WITH PASSWORD = '1234!';
CREATE USER ana WITH PASSWORD = '1234!';
CREATE USER james WITH PASSWORD = '123!';
GO

-- Asignar cada usuario a su rol
ALTER ROLE rol_programador ADD MEMBER carlos;
ALTER ROLE rol_gerente ADD MEMBER maria;
ALTER ROLE rol_contador ADD MEMBER luis;
ALTER ROLE rol_recepcionista ADD MEMBER ana;
ALTER ROLE rol_profesor ADD MEMBER james;
GO

-- Verificar que la base quedó autocontenida
SELECT name, containment_desc
FROM sys.databases
WHERE name = 'bd_hotel_grupoAC';
GO

-- Probar los permisos (ejecutar de uno en uno)
-- EXECUTE AS USER = 'james';
-- SELECT TOP 5 * FROM operaciones.huesped;        -- funciona
-- DELETE FROM operaciones.huesped WHERE 1 = 0;    -- error: permiso denegado
-- REVERT;
