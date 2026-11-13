/*
   USUARIOS (BASE DE DATOS AUTOCONTENIDA) - bd_hotel_grupoAC

   carlos -> db_owner (propietario de la base de datos)
   ana    -> rol_recepcionista
   maria  -> rol_gerente
   luis   -> rol_contador
   sofia  -> rol_analista_bi
   james  -> rol_profesor
*/

-- Habilitar la autenticación autocontenida en el servidor
USE master;
GO

EXEC sp_configure 'contained database authentication', 1;
RECONFIGURE;
GO

-- Convertir la base del hotel en autocontenida
ALTER DATABASE bd_hotel_grupoAC SET CONTAINMENT = PARTIAL;
GO

-- Crear usuarios con contraseña dentro de la base de datos
USE bd_hotel_grupoAC;
GO

CREATE USER carlos WITH PASSWORD = 'Carlos#2026!';
CREATE USER ana    WITH PASSWORD = 'Ana#2026!';
CREATE USER maria  WITH PASSWORD = 'Maria#2026!';
CREATE USER luis   WITH PASSWORD = 'Luis#2026!';
CREATE USER sofia  WITH PASSWORD = 'Sofia#2026!';
CREATE USER james  WITH PASSWORD = 'James#2026!';
GO

-- Asignar cada usuario a su rol
ALTER ROLE db_owner          ADD MEMBER carlos;
ALTER ROLE rol_recepcionista ADD MEMBER ana;
ALTER ROLE rol_gerente       ADD MEMBER maria;
ALTER ROLE rol_contador      ADD MEMBER luis;
ALTER ROLE rol_analista_bi   ADD MEMBER sofia;
ALTER ROLE rol_profesor      ADD MEMBER james;
GO

-- Verificar que la base quedó autocontenida
SELECT name, containment_desc
FROM sys.databases
WHERE name = 'bd_hotel_grupoAC';
GO

-- Verificar la membresía de cada usuario
SELECT
    r.name AS rol,
    m.name AS usuario
FROM sys.database_role_members AS rm
JOIN sys.database_principals   AS r ON r.principal_id = rm.role_principal_id
JOIN sys.database_principals   AS m ON m.principal_id = rm.member_principal_id
WHERE m.name IN ('carlos', 'ana', 'maria', 'luis', 'sofia', 'james')
ORDER BY r.name, m.name;
GO


-- Probar los permisos

USE bd_hotel_grupoAC;
GO

-- 1. PROFESOR (james)
EXECUTE AS USER = 'james';

SELECT * FROM operaciones.huesped;          -- Permitido

DELETE FROM operaciones.huesped
WHERE id_huesped = -1;                      -- Denegado

REVERT;
GO


-- 2. RECEPCIONISTA (ana)
EXECUTE AS USER = 'ana';

SELECT * FROM operaciones.reservacion;      -- Permitido

UPDATE operaciones.reservacion
SET estado_reserva = 'CONFIRMADA'
WHERE id_reservacion = -1;                  -- Permitido

SELECT * FROM finanzas.factura;             -- Denegado

REVERT;
GO


-- 3. GERENTE (maria)
EXECUTE AS USER = 'maria';

SELECT * FROM finanzas.factura;             -- Permitido

UPDATE finanzas.factura
SET estado_factura = 'PAGADO'
WHERE id_factura = -1;                      -- Denegado

REVERT;
GO


-- 4. CONTADOR (luis)
EXECUTE AS USER = 'luis';

SELECT * FROM finanzas.factura;             -- Permitido

UPDATE finanzas.factura
SET estado_factura = 'PAGADO'
WHERE id_factura = -1;                      -- Permitido

DELETE FROM finanzas.factura
WHERE id_factura = -1;                      -- Denegado

REVERT;
GO


-- 5. ANALISTA BI (sofia)
EXECUTE AS USER = 'sofia';

SELECT * FROM reportes.vw_evolucion_mensual_ingresos;   -- Permitido

SELECT * FROM finanzas.factura;                         -- Denegado

REVERT;
GO


-- 6. PROPIETARIO (carlos)
EXECUTE AS USER = 'carlos';

SELECT * FROM operaciones.huesped;          -- Permitido

UPDATE operaciones.reservacion
SET estado_reserva = 'CONFIRMADA'
WHERE id_reservacion = -1;                  -- Permitido

DELETE FROM finanzas.factura
WHERE id_factura = -1;                      -- Permitido

REVERT;
GO
