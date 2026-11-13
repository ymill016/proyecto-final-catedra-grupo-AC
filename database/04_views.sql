USE bd_hotel_grupoAC;
GO

/*
1. Evolución mensual de ingresos
Objetivo: identificar cómo evolucionan los ingresos efectivamente cobrados
por el hotel y compararlos con el período anterior.
*/
CREATE VIEW reportes.vw_evolucion_mensual_ingresos
AS
WITH mensual AS (
    SELECT
        DATEFROMPARTS(YEAR(fecha_pago), MONTH(fecha_pago), 1) AS mes,
        COUNT(*)   AS facturas_pagadas,
        SUM(total) AS ingresos
    FROM finanzas.factura
    WHERE estado_factura = 'PAGADO'
      AND fecha_pago IS NOT NULL
    GROUP BY
        YEAR(fecha_pago),
        MONTH(fecha_pago)
)
SELECT
    mes,
    facturas_pagadas,
    ingresos,
    LAG(ingresos) OVER (ORDER BY mes) AS ingresos_mes_anterior
FROM mensual;
GO

/*
2. Análisis de demanda y reservaciones
Objetivo: evaluar los canales y tipos de habitación más solicitados,
identificar cancelaciones y conocer la frecuencia con que los huéspedes
realizan reservas.
*/
CREATE VIEW reportes.vw_analisis_demanda_reservaciones
AS
SELECT
    r.id_reservacion,
    r.id_huesped,
    r.fecha_reserva,
    r.estado_reserva,
    r.canal_reserva,
    th.nombre_tipo,
    h.nacionalidad,
    ROW_NUMBER() OVER (
        PARTITION BY r.id_huesped
        ORDER BY r.fecha_reserva, r.id_reservacion
    ) AS numero_reserva_cliente
FROM operaciones.reservacion r
JOIN catalogo.tipo_habitacion th
    ON r.id_tipo_habitacion = th.id_tipo_habitacion
JOIN operaciones.huesped h
    ON r.id_huesped = h.id_huesped;
GO

/*
3. Ranking de clientes según gasto
Objetivo: identificar los huéspedes que generan mayores ingresos cobrados,
considerando tanto su gasto total como su frecuencia de estancias facturadas.
*/
CREATE VIEW reportes.vw_ranking_clientes_gasto
AS
WITH clientes AS (
    SELECT
        r.id_huesped,
        COUNT(*)     AS estancias_pagadas,
        SUM(f.total) AS gasto_total
    FROM finanzas.factura f
    JOIN operaciones.estancia e
        ON f.id_estancia = e.id_estancia
    JOIN operaciones.reservacion r
        ON e.id_reservacion = r.id_reservacion
    WHERE f.estado_factura = 'PAGADO'
    GROUP BY r.id_huesped
)
SELECT
    id_huesped,
    estancias_pagadas,
    gasto_total,
    RANK() OVER (ORDER BY gasto_total DESC) AS posicion
FROM clientes;
GO
