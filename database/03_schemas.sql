/* ============================================================
ESQUEMAS - bd_hotel_grupoAC
catalogo-> hotel, tipo_habitacion, habitacion, servicio
operaciones-> huesped, empleado, reservacion, estancia, acompanante, consumo_servicio
finanzas-> factura, detalle_factura
============================================================ */
USE bd_hotel_grupoAC;
GO

--crear esquemas

CREATE SCHEMA catalogo AUTHORIZATION dbo;
GO

CREATE SCHEMA operaciones AUTHORIZATION dbo;
GO

CREATE SCHEMA finanzas AUTHORIZATION dbo;
GO

-- mover tablas a los esquemas

-- esquema catalogo
ALTER SCHEMA catalogo TRANSFER dbo.hotel;
ALTER SCHEMA catalogo TRANSFER dbo.tipo_habitacion;
ALTER SCHEMA catalogo TRANSFER dbo.habitacion;
ALTER SCHEMA catalogo TRANSFER dbo.servicio;
GO

-- esquema de operaciones
ALTER SCHEMA operaciones TRANSFER dbo.huesped;
ALTER SCHEMA operaciones TRANSFER dbo.empleado;
ALTER SCHEMA operaciones TRANSFER dbo.reservacion;
ALTER SCHEMA operaciones TRANSFER dbo.estancia;
ALTER SCHEMA operaciones TRANSFER dbo.acompanante;
ALTER SCHEMA operaciones TRANSFER dbo.consumo_servicio;
GO

--esquema de finanzas
ALTER SCHEMA finanzas TRANSFER dbo.factura;
ALTER SCHEMA finanzas TRANSFER dbo.detalle_factura;
GO

--consultar esquemas existentes
SELECT
    s.name AS esquema,
    t.name AS tabla
FROM sys.tables AS t
INNER JOIN sys.schemas AS s
    ON t.schema_id = s.schema_id
ORDER BY s.name, t.name;
GO
