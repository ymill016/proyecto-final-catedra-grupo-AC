/* ============================================================
   SEGURIDAD - bd_hotel_grupoAC
   ============================================================ */
USE bd_hotel_grupoAC;
GO
-- Crear roles
CREATE ROLE rol_recepcionista;
CREATE ROLE rol_programador;
CREATE ROLE rol_gerente;
CREATE ROLE rol_contador;
GO

-- 1) RECEPCIONISTA: consulta catálogo y trabaja con operaciones.
GRANT SELECT ON SCHEMA::catalogo TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE, EXECUTE ON SCHEMA::operaciones TO rol_recepcionista;
DENY  ALL ON SCHEMA::finanzas TO rol_recepcionista;
GO

-- 2) PROGRAMADOR: crear objetos, gestionarlos y hacer BACKUP.
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO rol_programador;
GRANT BACKUP DATABASE, BACKUP LOG TO rol_programador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::catalogo    TO rol_programador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::operaciones TO rol_programador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::finanzas    TO rol_programador;
GO

-- 3) GERENTE: administra datos de catálogo y operaciones, consulta finanzas.
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::catalogo    TO rol_gerente;
GRANT SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::operaciones TO rol_gerente;
GRANT SELECT ON SCHEMA::finanzas TO rol_gerente;
GO

-- 4) CONTADOR: trabaja con finanzas; solo consulta catálogo y operaciones.
GRANT SELECT, INSERT, UPDATE, EXECUTE ON SCHEMA::finanzas TO rol_contador;
GRANT SELECT ON SCHEMA::catalogo    TO rol_contador;
GRANT SELECT ON SCHEMA::operaciones TO rol_contador;
GO
