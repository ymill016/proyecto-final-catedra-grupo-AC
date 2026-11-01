/* ============================================================
   SEGURIDAD - bd_hotel_grupoAC
   ============================================================ */
USE bd_hotel_grupoAC;
GO

--crear roles
CREATE ROLE rol_programador;
CREATE ROLE rol_recepcionista;
CREATE ROLE rol_profesor; -- solo lectura
GO

-- 1) PROGRAMADOR: crear objetos, gestionarlos y hacer BACKUP.
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO rol_programador;
GRANT BACKUP DATABASE, BACKUP LOG TO rol_programador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::catalogo TO rol_programador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::operaciones TO rol_programador;
GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::finanzas TO rol_programador;
GO

-- 2) RECEPCIONISTA: consulta catalogo y trabaja con operaciones.
GRANT SELECT ON SCHEMA::catalogo TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE, EXECUTE ON SCHEMA::operaciones TO rol_recepcionista;
GO

-- 3) PROFESOR: lectura de todos los esquemas
GRANT SELECT ON SCHEMA::catalogo TO rol_profesor;
GRANT SELECT ON SCHEMA::operaciones TO rol_profesor;
GRANT SELECT ON SCHEMA::finanzas TO rol_profesor;
GO
