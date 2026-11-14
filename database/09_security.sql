/*
   SEGURIDAD - ROLES Y PERMISOS (bd_hotel_grupoAC)
   Principio de mínimo privilegio: cada rol recibe únicamente
   los permisos necesarios para su función.

   Roles:
     rol_recepcionista -> atención de huéspedes y reservaciones
     rol_gerente       -> consulta general del hotel (solo lectura)
     rol_contador      -> gestión de facturación
     rol_analista_bi   -> consulta de vistas de reportes
     rol_profesor      -> lee tablas (solo lectura)
*/
USE bd_hotel_grupoAC;
GO

-- Creación de roles
CREATE ROLE rol_recepcionista AUTHORIZATION dbo;
CREATE ROLE rol_gerente       AUTHORIZATION dbo;
CREATE ROLE rol_contador      AUTHORIZATION dbo;
CREATE ROLE rol_analista_bi   AUTHORIZATION dbo;
CREATE ROLE rol_profesor      AUTHORIZATION dbo;
GO

/*
   RECEPCIONISTA
   Consulta el catálogo de habitaciones y gestiona huéspedes,
   reservaciones y estancias. Sin acceso a finanzas.
*/
GRANT SELECT ON OBJECT::catalogo.hotel           TO rol_recepcionista;
GRANT SELECT ON OBJECT::catalogo.tipo_habitacion TO rol_recepcionista;
GRANT SELECT ON OBJECT::catalogo.habitacion      TO rol_recepcionista;

GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.huesped     TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.reservacion TO rol_recepcionista;
GRANT SELECT, INSERT, UPDATE ON OBJECT::operaciones.estancia    TO rol_recepcionista;
GO

/*
   GERENTE
   Seguimiento operativo y financiero. Solo lectura.
*/
GRANT SELECT ON SCHEMA::catalogo TO rol_gerente;
GRANT SELECT ON SCHEMA::finanzas TO rol_gerente;

GRANT SELECT ON OBJECT::operaciones.huesped     TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.reservacion TO rol_gerente;
GRANT SELECT ON OBJECT::operaciones.estancia    TO rol_gerente;
GO

/*
   CONTADOR
   Registra y corrige facturas (sin eliminarlas). Consulta las
   tablas necesarias para facturar.
*/
GRANT SELECT, INSERT, UPDATE ON SCHEMA::finanzas TO rol_contador;

GRANT SELECT ON OBJECT::catalogo.tipo_habitacion TO rol_contador;
GRANT SELECT ON OBJECT::operaciones.reservacion  TO rol_contador;
GRANT SELECT ON OBJECT::operaciones.estancia     TO rol_contador;
GO

/*
   ANALISTA BI
   Sin acceso a tablas base. Solo consulta las vistas del
   esquema reportes.
*/
GRANT SELECT ON SCHEMA::reportes TO rol_analista_bi;
GO

/*
   PROFESOR
   Solo lectura en todos los esquemas. Sin INSERT, UPDATE,
   DELETE ni EXECUTE.
*/
GRANT SELECT ON SCHEMA::catalogo    TO rol_profesor;
GRANT SELECT ON SCHEMA::operaciones TO rol_profesor;
GRANT SELECT ON SCHEMA::finanzas    TO rol_profesor;
GRANT SELECT ON SCHEMA::reportes    TO rol_profesor;
GO

-- Verificación de permisos
SELECT
    rol.name              AS rol,
    perm.state_desc       AS estado,
    perm.permission_name  AS permiso,
    CASE perm.class_desc
        WHEN 'OBJECT_OR_COLUMN' THEN OBJECT_SCHEMA_NAME(perm.major_id) + '.' + OBJECT_NAME(perm.major_id)
        WHEN 'SCHEMA'           THEN 'SCHEMA::' + SCHEMA_NAME(perm.major_id)
        ELSE perm.class_desc
    END                   AS objeto
FROM sys.database_permissions AS perm
JOIN sys.database_principals  AS rol
    ON rol.principal_id = perm.grantee_principal_id
WHERE rol.name IN (
    'rol_recepcionista',
    'rol_gerente',
    'rol_contador',
    'rol_analista_bi',
    'rol_profesor'
)
ORDER BY rol.name, objeto, permiso;
GO
