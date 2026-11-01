/* ============================================================
   TRES CONSULTAS (CTE, PIVOT Y FUNCIONES VENTANA)
   SQL Server - Hotel Grupo AC
   ============================================================ */
USE bd_hotel_grupoAC;
GO

-- Consulta 1: TIPOS DE HABITACION MAS SOLICITADOS
CREATE OR ALTER VIEW operaciones.vw_tipos_habitacion_mas_reservados
AS
WITH ConteoHabitaciones AS (
    SELECT
        th.nombre_tipo,
        COUNT(*) AS total_reservas
    FROM operaciones.reservacion AS r
    INNER JOIN catalogo.tipo_habitacion AS th
        ON r.id_tipo_habitacion = th.id_tipo_habitacion
    GROUP BY th.nombre_tipo
)
SELECT
    nombre_tipo,
    total_reservas,
    RANK() OVER (ORDER BY total_reservas DESC) AS posicion
FROM ConteoHabitaciones;
GO

-- Consulta 2: RESERVACIONES POR CANAL Y ESTADO
CREATE OR ALTER VIEW operaciones.vw_reservas_por_canal_estado
AS
SELECT
    p.canal_reserva,
    ISNULL(p.[PENDIENTE], 0) AS pendientes,
    ISNULL(p.[CONFIRMADA], 0) AS confirmadas,
    ISNULL(p.[CANCELADA], 0) AS canceladas,
    ROW_NUMBER() OVER (
        ORDER BY ISNULL(p.[CONFIRMADA], 0) DESC, p.canal_reserva
    ) AS posicion
FROM (
    SELECT id_reservacion, canal_reserva, estado_reserva
    FROM operaciones.reservacion
    WHERE canal_reserva IS NOT NULL
) AS origen
PIVOT (
    COUNT(id_reservacion)
    FOR estado_reserva IN ([PENDIENTE], [CONFIRMADA], [CANCELADA])
) AS p;
GO

-- Consulta 3: NACIONALIDADES CON MAS HUESPEDES
CREATE OR ALTER VIEW operaciones.vw_huespedes_por_nacionalidad
AS
SELECT
    nacionalidad,
    COUNT(*) AS total_huespedes,
    DENSE_RANK() OVER (ORDER BY COUNT(*) DESC) AS posicion
FROM operaciones.huesped
WHERE nacionalidad IS NOT NULL
GROUP BY nacionalidad;
GO
