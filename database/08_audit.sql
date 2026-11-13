/* ============================================================
   AUDITORÍA PARA bd_hotel_grupoAC
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
   (incluye todas las tablas de operaciones y finanzas)
============================================================ */

USE bd_hotel_grupoAA;
GO

CREATE DATABASE AUDIT SPECIFICATION audit_hotel
FOR SERVER AUDIT hotelAudits

-- Esquema operaciones
ADD (SELECT, INSERT, UPDATE, DELETE ON operaciones.huesped          BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON operaciones.empleado         BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON operaciones.reservacion      BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON operaciones.estancia         BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON operaciones.acompanante      BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON operaciones.consumo_servicio BY PUBLIC),

-- Esquema finanzas
ADD (SELECT, INSERT, UPDATE, DELETE ON finanzas.factura             BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON finanzas.detalle_factura     BY PUBLIC),

-- Esquema catalogo
ADD (SELECT, INSERT, UPDATE, DELETE ON catalogo.hotel               BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON catalogo.tipo_habitacion     BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON catalogo.habitacion          BY PUBLIC),
ADD (SELECT, INSERT, UPDATE, DELETE ON catalogo.servicio            BY PUBLIC);
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
   GENERAR ACTIVIDAD DE PRUEBA (evidencia)
   Ejecutar este bloque y luego las consultas de más abajo.
============================================================ */

USE bd_hotel_grupoAA;
GO

-- SELECT (action_id = 'SL')
SELECT TOP 5 * FROM operaciones.huesped;
SELECT TOP 5 * FROM operaciones.reservacion;
SELECT TOP 5 * FROM finanzas.factura;
GO

-- UPDATE (action_id = 'UP'): no modifica el valor real del dato
UPDATE operaciones.huesped
SET nacionalidad = nacionalidad
WHERE id_huesped = (SELECT MIN(id_huesped) FROM operaciones.huesped);
GO

-- DELETE (action_id = 'DL'): no borra filas, pero la sentencia queda auditada
DELETE FROM operaciones.consumo_servicio
WHERE 1 = 0;
GO

-- INSERT (action_id = 'IN'): ajusta columnas y valores a tu tabla.
-- Ejemplo (descomenta y adapta):
-- INSERT INTO catalogo.servicio (nombre_servicio, precio)
-- VALUES ('Servicio de prueba auditoría', 10.00);
-- GO

-- Esperar a que SQL Server escriba los eventos en el archivo
WAITFOR DELAY '00:00:05';
GO


/* ============================================================
   CONSULTAS DE LOS LOGS (tomar captura de estos resultados)
============================================================ */

USE auditorias;
GO

-- Consulta general
SELECT *
FROM vw_auditoria_hotel
ORDER BY event_time DESC;
GO

-- Últimas 50 acciones
SELECT TOP 50 *
FROM vw_auditoria_hotel
ORDER BY event_time DESC;
GO

-- Acciones sobre HUESPED
SELECT *
FROM vw_auditoria_hotel
WHERE schema_name = 'operaciones'
  AND object_name = 'huesped'
ORDER BY event_time DESC;
GO

-- Acciones sobre FACTURA
SELECT *
FROM vw_auditoria_hotel
WHERE schema_name = 'finanzas'
  AND object_name = 'factura'
ORDER BY event_time DESC;
GO

-- Acciones por esquema
SELECT *
FROM vw_auditoria_hotel
WHERE schema_name = 'operaciones'
ORDER BY event_time DESC;
GO

-- Solo SELECT
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'SL'
ORDER BY event_time DESC;
GO

-- Solo INSERTS
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'IN'
ORDER BY event_time DESC;
GO

-- Solo UPDATES
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'UP'
ORDER BY event_time DESC;
GO

-- Solo DELETES
SELECT *
FROM vw_auditoria_hotel
WHERE action_id = 'DL'
ORDER BY event_time DESC;
GO

-- Resumen: cantidad de acciones por tipo y tabla
SELECT
    action_id,
    schema_name,
    object_name,
    COUNT(*) AS total_eventos
FROM vw_auditoria_hotel
WHERE schema_name IN ('operaciones', 'finanzas', 'catalogo')
GROUP BY action_id, schema_name, object_name
ORDER BY total_eventos DESC;
GO

-- Qué usuario realizó cada acción
SELECT
    session_server_principal_name,
    action_id,
    schema_name,
    object_name,
    event_time
FROM vw_auditoria_hotel
ORDER BY event_time DESC;
GO
