/* ============================================================
   UN SOLO PROCEDIMIENTO: LISTAR HABITACIONES DISPONIBLES
   Para demostrar el permiso EXECUTE de la recepcionista.
   ============================================================ */
USE bd_hotel_grupoAC;
GO

CREATE OR ALTER PROCEDURE operaciones.sp_listar_habitaciones_disponibles
AS
BEGIN
    SET NOCOUNT ON;

    SELECT numero_habitacion, estado_habitacion
    FROM catalogo.habitacion
    WHERE estado_habitacion = 'DISPONIBLE';
END;
GO

-- Prueba para verificar permisos del rol recepcionista
EXEC operaciones.sp_listar_habitaciones_disponibles;
GO

