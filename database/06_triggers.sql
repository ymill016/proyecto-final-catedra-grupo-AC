USE bd_hotel_grupoAC;
GO
/* ============================================================
   TRIGGERS
   ============================================================ */

/* Trigger 1: Validar estado y fechas de reservaciones */
CREATE OR ALTER TRIGGER operaciones.trg_verificar_disponibilidad_reservacion
ON operaciones.reservacion
AFTER INSERT
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted
        WHERE estado_reserva NOT IN ('PENDIENTE', 'CONFIRMADA')
           OR fecha_salida <= fecha_entrada
    )
    BEGIN
        RAISERROR('Error: Estado de reserva inválido o rango de fechas incorrecto.', 16, 1);
        ROLLBACK TRANSACTION;
        RETURN;
    END
END;
GO

/* Trigger 2: Actualiza el estado de la habitación tras finalizar/cancelar estancia */
CREATE OR ALTER TRIGGER operaciones.trg_actualizar_estado_habitacion_checkout
ON operaciones.estancia
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF UPDATE(estado_estancia)
    BEGIN
        -- Estancia FINALIZADA -> habitación a LIMPIEZA
        UPDATE h
        SET h.estado_habitacion = 'LIMPIEZA'
        FROM catalogo.habitacion h
        JOIN inserted i ON h.id_habitacion = i.id_habitacion
        JOIN deleted d ON i.id_estancia = d.id_estancia
        WHERE i.estado_estancia = 'FINALIZADA' AND d.estado_estancia != 'FINALIZADA';

        -- Estancia CANCELADA -> habitación a DISPONIBLE
        UPDATE h
        SET h.estado_habitacion = 'DISPONIBLE'
        FROM catalogo.habitacion h
        JOIN inserted i ON h.id_habitacion = i.id_habitacion
        JOIN deleted d ON i.id_estancia = d.id_estancia
        WHERE i.estado_estancia = 'CANCELADA' AND d.estado_estancia != 'CANCELADA';
    END
END;
GO

/* Trigger 3: Valida y corrige el subtotal en consumo_servicio */
CREATE OR ALTER TRIGGER operaciones.trg_validar_subtotal_consumo
ON operaciones.consumo_servicio
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    UPDATE cs
    SET cs.subtotal = cs.cantidad * s.precio_unitario
    FROM operaciones.consumo_servicio cs
    JOIN inserted i ON cs.id_consumo = i.id_consumo
    JOIN catalogo.servicio s ON cs.id_servicio = s.id_servicio
    WHERE cs.subtotal <> (cs.cantidad * s.precio_unitario);
END;
GO
