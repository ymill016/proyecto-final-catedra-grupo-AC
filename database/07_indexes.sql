use bd_hotel_grupoAC;
go

-----------------------------------------------------------
                --- 7. INDICES ---
-----------------------------------------------------------

-- Estadística para estimar filas en el JOIN entre estancia y reservación
CREATE STATISTICS st_estancia_id_reservacion
ON operaciones.estancia (id_reservacion);

-- Estadística para filtros por estado y fecha de pago
CREATE STATISTICS st_factura_estado_fecha
ON finanzas.factura (estado_factura, fecha_pago);

--recalcular la estadisticas 
UPDATE STATISTICS operaciones.estancia WITH FULLSCAN;
UPDATE STATISTICS finanzas.factura WITH FULLSCAN;

-- Índice filtrado solo por facturas pagadas; cubre fecha_pago y total sin Key Lookup
CREATE NONCLUSTERED INDEX IX_factura_fecha_estancia
ON finanzas.factura (id_estancia)
INCLUDE (fecha_pago, total)
WHERE estado_factura = 'PAGADO' AND fecha_pago IS NOT NULL;
GO

-- Búsqueda por huésped y fecha; INCLUDE evita lecturas a la tabla base
CREATE NONCLUSTERED INDEX IX_reservacion_huesped_fecha
ON operaciones.reservacion (id_huesped, fecha_reserva, id_reservacion)
INCLUDE (estado_reserva, canal_reserva, id_tipo_habitacion);

-- Índice filtrado: solo las facturas pagadas, ya agrupables por estancia
CREATE NONCLUSTERED INDEX IX_factura_pagado_estancia
ON finanzas.factura (id_estancia)
INCLUDE (total)
WHERE estado_factura = 'PAGADO';

-- Cubre los datos del huésped que muestra el reporte
CREATE NONCLUSTERED INDEX IX_huesped_reporte
ON operaciones.huesped (id_huesped)
INCLUDE (nombre, apellido, nacionalidad);

--Consultar indices por tablas
EXEC sp_helpindex 'operaciones.reservacion';
EXEC sp_helpindex 'operaciones.huesped';
EXEC sp_helpindex 'finanzas.factura';

--Consultar todos los indices existentes en la base de datos
SELECT
    s.name AS esquema,
    t.name AS tabla,
    i.name AS nombre_indice,
    i.type_desc AS tipo_indice,
    i.is_primary_key AS es_clave_primaria,
    i.is_unique AS es_unico,
    i.is_disabled AS esta_deshabilitado
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
INNER JOIN sys.schemas s ON t.schema_id = s.schema_id
WHERE i.index_id > 0
ORDER BY s.name, t.name, i.name;
