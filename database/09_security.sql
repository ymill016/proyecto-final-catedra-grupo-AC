/* ============================================================
   SEGURIDAD - bd_hotel_grupoAC
   ============================================================ */
USE bd_hotel_grupoAC;
GO

--crear roles
CREATE ROLE rol_programador;
CREATE ROLE rol_gerente;
CREATE ROLE rol_contador;
CREATE ROLE rol_recepcionista;
CREATE ROLE rol_profesor; -- solo lectura
GO

--asigar permisos a Programador
GRANT CREATE TABLE, CREATE VIEW, CREATE PROCEDURE, CREATE FUNCTION TO rol_programador;

GRANT EXECUTE ON DATABASE::bd_hotel_grupoAC TO rol_programador;

GRANT BACKUP DATABASE, BACKUP LOG TO rol_programador;

GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::catalogo TO rol_programador;

GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::operaciones TO rol_programador;

GRANT ALTER, SELECT, INSERT, UPDATE, DELETE, EXECUTE ON SCHEMA::finanzas TO rol_programador;

GO

-- asignando solo lectura a Gerente

GRANT SELECT ON SCHEMA::catalogo TO rol_gerente;

GRANT SELECT ON SCHEMA::operaciones TO rol_gerente;

GRANT SELECT ON SCHEMA::finanzas TO rol_gerente;

GO

-- permisos al Contador

GRANT SELECT ON SCHEMA::catalogo TO rol_contador;

GRANT SELECT ON SCHEMA::operaciones TO rol_contador;

GRANT SELECT ON SCHEMA::finanzas TO rol_contador;

GRANT INSERT, UPDATE ON SCHEMA::finanzas TO rol_contador;
GO

--permisos de la recepcionista

GRANT SELECT ON SCHEMA::catalogo TO rol_recepcionista;

GRANT SELECT, INSERT, UPDATE ON SCHEMA::operaciones TO rol_recepcionista;

GRANT UPDATE ON OBJECT::catalogo.habitacion TO rol_recepcionista;

GRANT EXECUTE ON OBJECT::operaciones.sp_realizar_checkin TO rol_recepcionista;

GRANT EXECUTE ON OBJECT::operaciones.sp_registrar_consumo_servicio TO rol_recepcionista;

GRANT EXECUTE ON OBJECT::finanzas.sp_realizar_checkout TO rol_recepcionista;
GO

-- permisos del profesor (solo lectura)

GRANT SELECT ON SCHEMA::catalogo TO rol_profesor;

GRANT SELECT ON SCHEMA::operaciones TO rol_profesor;

GRANT SELECT ON SCHEMA::finanzas TO rol_profesor;

GO
