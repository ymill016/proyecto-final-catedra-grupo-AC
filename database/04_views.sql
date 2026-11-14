USE bd_hotel_grupoAC;
GO

/* ============================================================
   CONSULTA 1: EVOLUCIÓN MENSUAL DE INGRESOS

   Objetivo:
   Analizar los ingresos efectivamente cobrados por el hotel,
   agrupándolos por mes para identificar tendencias de
   facturación.
   ============================================================ */

CREATE OR ALTER VIEW reportes.vw_evolucion_mensual_ingresos
AS
WITH mensual AS (
    SELECT
        DATEFROMPARTS(YEAR(f.fecha_pago), MONTH(f.fecha_pago), 1) AS mes,
        COUNT(*)     AS facturas_pagadas,
        SUM(f.total) AS ingresos
    FROM finanzas.factura AS f
    INNER JOIN operaciones.estancia AS e
        ON f.id_estancia = e.id_estancia
    WHERE f.estado_factura = 'PAGADO'
      AND f.fecha_pago IS NOT NULL
    GROUP BY DATEFROMPARTS(YEAR(f.fecha_pago), MONTH(f.fecha_pago), 1)
)
SELECT
    mes,
    facturas_pagadas,
    ingresos,
    LAG(ingresos) OVER (ORDER BY mes)             AS ingresos_mes_anterior,
    SUM(ingresos) OVER (ORDER BY mes
                        ROWS UNBOUNDED PRECEDING) AS ingresos_acumulados
FROM mensual;
GO


/* ============================================================
   CONSULTA 2: ANÁLISIS DE DEMANDA Y RESERVACIONES

   Objetivo:
   Evaluar los canales de reserva, estados y tipos de
   habitación más solicitados, e identificar clientes
   que realizan reservaciones recurrentes.
   ============================================================ */

CREATE OR ALTER VIEW reportes.vw_analisis_demanda_reservaciones
AS
SELECT
    r.id_reservacion,
    r.id_huesped,
    r.fecha_reserva,
    r.estado_reserva,
    r.canal_reserva,
    th.nombre_tipo,

    ROW_NUMBER() OVER (
        PARTITION BY r.id_huesped
        ORDER BY r.fecha_reserva, r.id_reservacion
    ) AS numero_reserva_cliente

FROM operaciones.reservacion AS r

INNER JOIN catalogo.tipo_habitacion AS th
    ON r.id_tipo_habitacion = th.id_tipo_habitacion;
GO


/* ============================================================
   CONSULTA 3: RANKING DE CLIENTES SEGÚN GASTO

   Objetivo:
   Identificar los huéspedes que generan mayores ingresos,
   considerando el gasto acumulado y la cantidad de
   estancias facturadas y pagadas.
   ============================================================ */

CREATE OR ALTER VIEW reportes.vw_ranking_clientes_gasto
AS
WITH facturas_por_estancia AS (
    SELECT
        id_estancia,
        SUM(total) AS gasto_estancia

    FROM finanzas.factura

    WHERE estado_factura = 'PAGADO'

    GROUP BY id_estancia
),
clientes AS (
    SELECT
        r.id_huesped,
        COUNT(*) AS estancias_pagadas,
        SUM(fe.gasto_estancia) AS gasto_total

    FROM facturas_por_estancia AS fe

    INNER JOIN operaciones.estancia AS e
        ON fe.id_estancia = e.id_estancia

    INNER JOIN operaciones.reservacion AS r
        ON e.id_reservacion = r.id_reservacion

    GROUP BY r.id_huesped
)
SELECT
    h.id_huesped,

    CONCAT(
        h.nombre, ' ', h.apellido
    ) AS nombre_cliente,

    h.nacionalidad,

    ISNULL(
        c.estancias_pagadas, 0
    ) AS estancias_pagadas,

    ISNULL(
        c.gasto_total, 0
    ) AS gasto_total,

    RANK() OVER (
        ORDER BY ISNULL(c.gasto_total, 0) DESC
    ) AS posicion

FROM operaciones.huesped AS h

LEFT JOIN clientes AS c
    ON h.id_huesped = c.id_huesped;
GO
