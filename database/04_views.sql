--=================================
--           CONSULTAS
--=================================
USE bd_hotel_grupoAA;
GO

/* ------------------------------------------------------------
   CONSULTA 1: analisis pareto (ABC) de servicios
 Que servicios concentran el 80% del ingreso por consumos.
--------------------------------------------------------------- */
WITH ingreso_servicio AS (
SELECT s.id_servicio,s.nombre,s.categoria,
SUM(cs.subtotal) AS ingreso
FROM operacion.consumo_servicio cs
JOIN catalogo.servicio s ON s.id_servicio = cs.id_servicio
GROUP BY s.id_servicio, s.nombre, s.categoria),

pct_servicio AS (
SELECT*,ROUND(100.0 * ingreso / SUM(ingreso) OVER (), 2) AS pct_ingreso
FROM ingreso_servicio
)
SELECT nombre,categoria,ingreso,pct_ingreso,
ROUND(SUM(pct_ingreso) OVER (ORDER BY ingreso DESC ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW), 
2) AS pct_acumulado,
CASE
WHEN SUM(pct_ingreso) OVER (ORDER BY ingreso DESC
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) <= 80 THEN 'A'
WHEN SUM(pct_ingreso) OVER (ORDER BY ingreso DESC
ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) <= 95 THEN 'B'
ELSE 'C'
END AS clase_abc
FROM pct_servicio ORDER BY ingreso DESC;
GO

/* ------------------------------------------------------------
   CONSULTA 2: RESERVAS POR CANAL Y ESTADO
   Matriz canal vs. estado para el dashboard.
--------------------------------------------------------------- */

SELECT canal_reserva, [PENDIENTE], [CONFIRMADA], [CANCELADA] FROM (
SELECT canal_reserva, estado_reserva
FROM reservas.reservacion) src PIVOT (COUNT(estado_reserva)
FOR estado_reserva IN ([PENDIENTE], [CONFIRMADA], [CANCELADA]) ) pvt
ORDER BY canal_reserva;
GO

/* ------------------------------------------------------------
   CONSULTAS 3: RANKING DE HUESPEDES POR GASTO TOTAL
   Posicion competitiva y cuartiles de valor para segmentacion VIP.
------------------------------------------------------------ */
SELECT hu.nombre + ' ' + hu.apellido AS huesped,hu.nacionalidad,
COUNT(DISTINCT f.id_factura) AS visitas, SUM(f.total) AS gasto_total,
RANK()OVER (ORDER BY SUM(f.total) DESC) AS posicion_rank,
DENSE_RANK() OVER (ORDER BY SUM(f.total) DESC) AS posicion_dense,
NTILE(4)OVER (ORDER BY SUM(f.total) DESC) AS cuartil_valor
FROM reservas.huesped hu
JOIN reservas.reservacion r ON r.id_huesped = hu.id_huesped
JOIN operacion.estancia e   ON e.id_reservacion = r.id_reservacion
JOIN facturacion.factura f  ON f.id_estancia = e.id_estancia
WHERE f.estado_factura <> 'CANCELADO'
GROUP BY hu.id_huesped, hu.nombre, hu.apellido, hu.nacionalidad
ORDER BY gasto_total DESC;
GO
