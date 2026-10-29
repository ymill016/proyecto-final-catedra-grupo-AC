/* ============================================================
   AUDITORÍA PARA bd_hotel_grupoAA
   SQL SERVER AUDIT + DATABASE AUDIT SPECIFICATION
============================================================ */

USE master;
GO

/* ============================================================
   CREAR SERVER AUDIT
============================================================ */

CREATE SERVER AUDIT hotelAudits
TO FILE
(
    FILEPATH = 'C:\Audit\',
    MAXSIZE = 10 MB,
    MAX_FILES = 5
)
WITH
(
    ON_FAILURE = CONTINUE
);
GO

/* ============================================================
   ACTIVAR SERVER AUDIT
============================================================ */

ALTER SERVER AUDIT hotelAudits
WITH (STATE = ON);
GO


/* ============================================================
   CREAR AUDITORÍA DE LA BASE DE DATOS
============================================================ */

USE bd_hotel_grupoAA;
GO

CREATE DATABASE AUDIT SPECIFICATION audit_hotel
FOR SERVER AUDIT hotelAudits

ADD (
    SELECT,
    INSERT,
    UPDATE,
    DELETE
    ON dbo.huesped
    BY PUBLIC
),

ADD (
    SELECT,
    INSERT,
    UPDATE,
    DELETE
    ON dbo.reservacion
    BY PUBLIC
),

ADD (
    SELECT,
    INSERT,
    UPDATE,
    DELETE
    ON dbo.estancia
    BY PUBLIC
),

ADD (
    SELECT,
    INSERT,
    UPDATE,
    DELETE
    ON dbo.factura
    BY PUBLIC
),

ADD (
    SELECT,
    INSERT,
    UPDATE,
    DELETE
    ON dbo.consumo_servicio
    BY PUBLIC
);

GO

/* ============================================================
   ACTIVAR AUDITORÍA DE LA BASE
============================================================ */

ALTER DATABASE AUDIT SPECIFICATION audit_hotel
WITH (STATE = ON);
GO


/* ============================================================
   BASE DE DATOS PARA CONSULTAR AUDITORÍAS
============================================================ */

USE master;
GO

CREATE DATABASE auditorias;
GO


/* ============================================================
   VISTA PARA CONSULTAR AUDITORÍAS
============================================================ */

USE auditorias;
GO

CREATE VIEW vw_auditoria_hotel
AS
SELECT
    event_time,
    action_id,
    succeeded,
    session_server_principal_name,
    database_name,
    schema_name,
    object_name,
    statement
FROM sys.fn_get_audit_file(
    'C:\Audit\hotelAudits*',
    DEFAULT,
    DEFAULT
);
GO


/* ============================================================
   CONSULTA GENERAL DE AUDITORÍAS
============================================================ */

SELECT *
FROM vw_auditoria_hotel
ORDER BY event_time DESC;
GO


/* ============================================================
   CONSULTAS ÚTILES
============================================================ */

-- Ver últimas 50 acciones
SELECT TOP 50 *
FROM vw_auditoria_hotel
ORDER BY event_time DESC;
GO

-- Ver acciones realizadas sobre la tabla HUESPED
SELECT *
FROM vw_auditoria_hotel
WHERE object_name = 'huesped'
ORDER BY event_time DESC;
GO

-- Ver acciones realizadas sobre FACTURA
SELECT *
FROM vw_auditoria_hotel
WHERE object_name = 'factura'
ORDER BY event_time DESC;
GO

-- Ver solo INSERTS
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'IN'
ORDER BY event_time DESC;
GO

-- Ver solo UPDATES
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'UP'
ORDER BY event_time DESC;
GO

-- Ver solo DELETES
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'DL'
ORDER BY event_time DESC;
GO

-- Ver qué usuario realizó acciones
SELECT
    session_server_principal_name,
    action_id,
    object_name,
    event_time
FROM vw_auditoria_hotel
ORDER BY event_time DESC;
GO
