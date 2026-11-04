use bd_hotel_grupoAC;
go

-----------------------------------------------------------
                --- 7. INDICES ---
-----------------------------------------------------------

-- Para vw_tipos_habitacion_mas_reservados: Acelera el conteo de reservas por cada tipo de habitación
-- Evita el Sort antes del agregado 
CREATE NONCLUSTERED INDEX ix_reservacion_tipo_habitacion 
ON operaciones.reservacion (id_tipo_habitacion);

-- Para vw_reservas_por_canal_estado: Agrupa por canal de reserva y cuenta por estado de reserva.
-- excluye registros donde canal_reserva es nulo.
CREATE NONCLUSTERED INDEX ix_reservacion_canal_estado
ON operaciones.reservacion (canal_reserva)
INCLUDE (estado_reserva)
WHERE canal_reserva IS NOT NULL;

-- Para vw_huespedes_por_nacionalidad: agrupa huéspedes por nacionalidad.
-- excluye registros donde nacionalidad es nula.
CREATE NONCLUSTERED INDEX ix_huesped_nacionalidad
ON operaciones.huesped (nacionalidad)
WHERE nacionalidad IS NOT NULL;

--Consultar indices por tablas
EXEC sp_helpindex 'operaciones.reservacion';
EXEC sp_helpindex 'operaciones.huesped';

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
