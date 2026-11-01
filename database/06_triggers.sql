/* ============================================================
   UN SOLO TRIGGER: ACTUALIZAR EL ESTADO DE LA HABITACION
   Cuando una estancia termina -> LIMPIEZA.
   Cuando una estancia se cancela -> DISPONIBLE.
   ============================================================ */
USE bd_hotel_grupoAC;
GO
CREATE OR ALTER TRIGGER operaciones.trg_estado_habitacion_al_cerrar_estancia
ON operaciones.estancia
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE h
    SET h.estado_habitacion = CASE
        WHEN i.estado_estancia = 'FINALIZADA' THEN 'LIMPIEZA'
        WHEN i.estado_estancia = 'CANCELADA' THEN 'DISPONIBLE'
    END
    FROM catalogo.habitacion AS h
    INNER JOIN inserted AS i ON i.id_habitacion = h.id_habitacion
    INNER JOIN deleted AS d ON d.id_estancia = i.id_estancia
    WHERE i.estado_estancia IN ('FINALIZADA', 'CANCELADA')
      AND d.estado_estancia <> i.estado_estancia;
END;
GO
