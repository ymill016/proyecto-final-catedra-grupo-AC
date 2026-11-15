
/* ============================================================
   SEGURIDAD - HOTEL GRUPO AC
============================================================ */

USE master;
GO

-- 1. Autenticación contenida
EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

ALTER DATABASE bd_hotel_grupoAC SET CONTAINMENT = PARTIAL;
GO

-- 2. Logins de servidor
CREATE LOGIN login_jobs_hotel
WITH PASSWORD = '1SxksKrVUA#kDIKDkNS!', CHECK_POLICY = ON;

CREATE LOGIN login_restore_hotel
WITH PASSWORD = 'ld3svZw6te#q5MXpbod!', CHECK_POLICY = ON;
GO

ALTER SERVER ROLE dbcreator ADD MEMBER login_restore_hotel;
GO

-- 3. Roles de base de datos
USE bd_hotel_grupoAC;
GO

CREATE ROLE rol_recepcionista;
CREATE ROLE rol_gerente;
CREATE ROLE rol_contador;
CREATE ROLE rol_analista_bi;
CREATE ROLE rol_profesor;
GO

-- 4. Usuarios contenidos
CREATE USER carlos WITH PASSWORD = 'Hotel#Owner2026!';
CREATE USER ana WITH PASSWORD = 'Hotel#Recep2026!';
CREATE USER maria WITH PASSWORD = 'Hotel#Gerente2026!';
CREATE USER luis WITH PASSWORD = 'Hotel#Conta2026!';
CREATE USER sofia WITH PASSWORD = 'Hotel#Analisis2026!';
CREATE USER james WITH PASSWORD = 'Hotel#Profe2026!';
GO

-- Usuario de respaldos
CREATE USER login_jobs_hotel FOR LOGIN login_jobs_hotel;
GO

-- 5. Asignación de roles
ALTER ROLE db_owner ADD MEMBER carlos;
ALTER ROLE rol_recepcionista ADD MEMBER ana;
ALTER ROLE rol_gerente ADD MEMBER maria;
ALTER ROLE rol_contador ADD MEMBER luis;
ALTER ROLE rol_analista_bi ADD MEMBER sofia;
ALTER ROLE rol_profesor ADD MEMBER james;
ALTER ROLE db_backupoperator ADD MEMBER login_jobs_hotel;
GO

-- 6. Permisos de recepcionista
GRANT SELECT ON OBJECT::catalogo.hotel TO rol_recepcionista;
GRANT SELECT ON OBJECT::catalogo.tipo_habitacion TO rol_recepcionista;
GRANT SELECT ON OBJECT::catalogo.habitacion TO rol_recepcionista;

GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.huesped TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.reservacion TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.estancia TO rol_recepcionista;

GRANT EXECUTE ON OBJECT::operaciones.sp_listar_habitaciones_disponibles TO rol_recepcionista;
GO

-- 7. Permisos de gerente
GRANT SELECT ON SCHEMA::catalogo TO rol_gerente;
GRANT SELECT ON SCHEMA::finanzas TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.huesped TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.reservacion TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.estancia TO rol_gerente;
GO

-- 8. Permisos de contador
GRANT SELECT, INSERT, UPDATE ON SCHEMA::finanzas TO rol_contador;
GRANT SELECT ON OBJECT::catalogo.tipo_habitacion TO rol_contador;
GRANT SELECT ON OBJECT::operaciones.reservacion TO rol_contador;
GRANT SELECT ON OBJECT::operaciones.estancia TO rol_contador;
GO

-- 9. Permisos de analista BI
GRANT SELECT ON SCHEMA::reportes TO rol_analista_bi;
GO

-- 10. Permisos de profesor
GRANT SELECT ON SCHEMA::catalogo TO rol_profesor;
GRANT SELECT ON SCHEMA::operaciones TO rol_profesor;
GRANT SELECT ON SCHEMA::finanzas TO rol_profesor;
GO

-- 11. SQL Server Agent
USE msdb;
GO

CREATE USER login_jobs_hotel FOR LOGIN login_jobs_hotel;
GO

ALTER ROLE SQLAgentUserRole ADD MEMBER login_jobs_hotel;
GO
