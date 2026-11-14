/* ============================================================
   SEGURIDAD - HOTEL GRUPO AC
   ============================================================ */

-- Configuración de usuarios contenidos y rol de servidor
USE master;
GO

EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

ALTER DATABASE bd_hotel_grupoAC SET CONTAINMENT = PARTIAL;
GO

CREATE LOGIN sandra WITH PASSWORD = 'Hotel#Restore2026!';
GO

ALTER SERVER ROLE dbcreator ADD MEMBER sandra;
GO

-- Roles de la base de datos
USE bd_hotel_grupoAC;
GO

CREATE ROLE rol_recepcionista AUTHORIZATION dbo;
CREATE ROLE rol_gerente AUTHORIZATION dbo;
CREATE ROLE rol_contador AUTHORIZATION dbo;
CREATE ROLE rol_analista_bi AUTHORIZATION dbo;
CREATE ROLE rol_profesor AUTHORIZATION dbo;
GO

-- Usuarios
CREATE USER carlos WITH PASSWORD = 'Hotel#Owner2026!';
CREATE USER ana WITH PASSWORD = 'Hotel#Recep2026!';
CREATE USER maria WITH PASSWORD = 'Hotel#Gerente2026!';
CREATE USER luis WITH PASSWORD = 'Hotel#Conta2026!';
CREATE USER sofia WITH PASSWORD = 'Hotel#Analisis2026!';
CREATE USER james WITH PASSWORD = 'Hotel#Profe2026!';
CREATE USER pedro WITH PASSWORD = 'Hotel#Backup2026!';
GO

-- Asignación de roles
ALTER ROLE db_owner ADD MEMBER carlos;
ALTER ROLE rol_recepcionista ADD MEMBER ana;
ALTER ROLE rol_gerente ADD MEMBER maria;
ALTER ROLE rol_contador ADD MEMBER luis;
ALTER ROLE rol_analista_bi ADD MEMBER sofia;
ALTER ROLE rol_profesor ADD MEMBER james;
ALTER ROLE db_backupoperator ADD MEMBER pedro;
GO

-- RECEPCIONISTA: consulta de habitaciones y gestión de hospedaje
GRANT SELECT ON OBJECT::catalogo.hotel TO rol_recepcionista;
GRANT SELECT ON OBJECT::catalogo.tipo_habitacion TO rol_recepcionista;
GRANT SELECT ON OBJECT::catalogo.habitacion TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.huesped TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.reservacion TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.estancia TO rol_recepcionista;
GRANT EXECUTE ON OBJECT::operaciones.sp_listar_habitaciones_disponibles TO rol_recepcionista;
GO

-- GERENTE: consultas operativas y financieras
GRANT SELECT ON SCHEMA::catalogo TO rol_gerente;
GRANT SELECT ON SCHEMA::finanzas TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.huesped TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.reservacion TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.estancia TO rol_gerente;
GO

-- CONTADOR: consulta de datos y gestión de facturación
GRANT SELECT, INSERT, UPDATE ON SCHEMA::finanzas TO rol_contador;
GRANT SELECT ON OBJECT::catalogo.tipo_habitacion TO rol_contador;
GRANT SELECT ON OBJECT::operaciones.reservacion TO rol_contador;
GRANT SELECT ON OBJECT::operaciones.estancia TO rol_contador;
GO

-- ANALISTA BI: lectura de vistas de reportes
GRANT SELECT ON SCHEMA::reportes TO rol_analista_bi;
GO

-- PROFESOR: lectura de los cuatro esquemas
GRANT SELECT ON SCHEMA::catalogo TO rol_profesor;
GRANT SELECT ON SCHEMA::operaciones TO rol_profesor;
GRANT SELECT ON SCHEMA::finanzas TO rol_profesor;
GRANT SELECT ON SCHEMA::reportes TO rol_profesor;
GO

-- sa: login integrado de SQL Server, no se crea ni se modifica.
