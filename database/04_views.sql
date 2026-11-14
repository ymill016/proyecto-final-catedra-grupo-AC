USE bd_hotel_grupoAC;
GO

/* ============================================================
   CONSULTA 1: EVOLUCIÓN MENSUAL DE INGRESOS

   Objetivo de negocio:
   Analizar la tendencia de facturación mensual del hotel,
   comparando los ingresos de cada mes con el mes anterior
   y con el acumulado, para detectar crecimiento o caídas
   en la facturación.

   Funciones ventana: LAG(), SUM() OVER (ROWS UNBOUNDED PRECEDING)
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
   CONSULTA 2: DEMANDA POR TIPO DE HABITACIÓN Y TEMPORADA

   Objetivo de negocio:
   Identificar en qué meses aumenta la demanda de cada tipo
   de habitación, para ajustar las tarifas en temporadas
   altas y lanzar promociones en temporadas bajas,
   maximizando los ingresos del hotel.

   Funciones ventana: RANK() OVER (PARTITION BY mes),
                      SUM() OVER (PARTITION BY mes)
   ============================================================ */

CREATE OR ALTER VIEW reportes.vw_demanda_tipos_habitacion
AS
WITH demanda AS (
    SELECT
        DATEFROMPARTS(YEAR(r.fecha_reserva), MONTH(r.fecha_reserva), 1) AS mes,
        th.nombre_tipo,
        COUNT(*) AS total_reservas
    FROM operaciones.reservacion AS r
    INNER JOIN catalogo.tipo_habitacion AS th
        ON r.id_tipo_habitacion = th.id_tipo_habitacion
    GROUP BY
        DATEFROMPARTS(YEAR(r.fecha_reserva), MONTH(r.fecha_reserva), 1),
        th.nombre_tipo
)
SELECT
    mes,
    nombre_tipo,
    total_reservas,
    RANK() OVER (
        PARTITION BY mes
        ORDER BY total_reservas DESC
    ) AS posicion_en_el_mes,
    CAST(
        100.0 * total_reservas / SUM(total_reservas) OVER (PARTITION BY mes)
        AS DECIMAL(5,2)
    ) AS porcentaje_del_mes
FROM demanda;
GO

/* ============================================================
   CONSULTA 3: RANKING DE CLIENTES SEGÚN GASTO

   Objetivo de negocio:
   Identificar a los huéspedes que generan mayores ingresos
   para el hotel, considerando su gasto acumulado y la
   cantidad de estancias facturadas y pagadas, para
   enfocar estrategias de fidelización.

   Función ventana: RANK()
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
    CONCAT(h.nombre, ' ', h.apellido) AS nombre_cliente,
    h.nacionalidad,
    ISNULL(c.estancias_pagadas, 0) AS estancias_pagadas,
    ISNULL(c.gasto_total, 0)       AS gasto_total,
    RANK() OVER (
        ORDER BY ISNULL(c.gasto_total, 0) DESC
    ) AS posicion
FROM operaciones.huesped AS h
LEFT JOIN clientes AS c
    ON h.id_huesped = c.id_huesped;
GO

/* ============================================================
   EJECUCIÓN DE LAS CONSULTAS
   ============================================================ */

-- CONSULTA 1: Evolución mensual de ingresos
SELECT
    mes,
    facturas_pagadas,
    ingresos,
    ingresos_mes_anterior,
    ingresos_acumulados
FROM reportes.vw_evolucion_mensual_ingresos
WHERE mes >= '2026-01-01'
  AND mes < '2027-01-01'
ORDER BY mes;
GO

-- CONSULTA 2: Demanda por tipo de habitación
SELECT
    mes,
    nombre_tipo,
    total_reservas,
    posicion_en_el_mes,
    porcentaje_del_mes
FROM reportes.vw_demanda_tipos_habitacion
WHERE mes >= '2026-01-01'
  AND mes < '2027-01-01'
ORDER BY mes, posicion_en_el_mes, nombre_tipo;
GO

-- CONSULTA 3: Ranking de clientes según gasto
SELECT
    id_huesped,
    nombre_cliente,
    nacionalidad,
    estancias_pagadas,
    gasto_total,
    posicion
FROM reportes.vw_ranking_clientes_gasto
WHERE posicion <= 10
  AND gasto_total > 0
ORDER BY posicion, id_huesped;
GO
