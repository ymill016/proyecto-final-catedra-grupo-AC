USE bd_hotel_grupoAC;
GO

/* ============================================================
   FUNCIONES
   ============================================================ */

/* Función 1: Calcular noches de estancia */
CREATE OR ALTER FUNCTION finanzas.fn_calcular_noches(@p_id_estancia INT)
RETURNS INT
AS
BEGIN
    DECLARE @v_checkin DATETIME2;
    DECLARE @v_checkout DATETIME2;
    DECLARE @v_noches INT;

    SELECT
        @v_checkin = fecha_checkin,
        @v_checkout = fecha_checkout
    FROM operaciones.estancia
    WHERE id_estancia = @p_id_estancia;

    IF @@ROWCOUNT = 0
        RETURN NULL;

    IF @v_checkout IS NULL
        RETURN NULL;

    SET @v_noches = DATEDIFF(DAY, @v_checkin, @v_checkout);

    IF @v_noches < 1
        SET @v_noches = 1;

    RETURN @v_noches;
END;
GO

/* Función 2: Total consumos */
CREATE OR ALTER FUNCTION finanzas.fn_calcular_total_servicios(@p_id_estancia INT)
RETURNS NUMERIC(10,2)
AS
BEGIN
    DECLARE @v_total NUMERIC(10,2);

    SELECT @v_total = COALESCE(SUM(subtotal),0)
    FROM operaciones.consumo_servicio
    WHERE id_estancia = @p_id_estancia;

    RETURN @v_total;
END;
GO

/* Función 3: Disponibilidad de habitación */
CREATE OR ALTER FUNCTION operaciones.fn_habitacion_disponible(
    @p_id_habitacion INT,
    @p_fecha_entrada DATETIME2,
    @p_fecha_salida DATETIME2
)
RETURNS BIT
AS
BEGIN
    DECLARE @v_conflictos INT;
    DECLARE @v_estado_habitacion VARCHAR(20);

    IF @p_fecha_salida <= @p_fecha_entrada
        RETURN 0;

    SELECT @v_estado_habitacion = estado_habitacion
    FROM catalogo.habitacion
    WHERE id_habitacion = @p_id_habitacion;

    IF @@ROWCOUNT = 0
        RETURN 0;

    IF @v_estado_habitacion = 'MANTENIMIENTO'
        RETURN 0;

    SELECT @v_conflictos = COUNT(*)
    FROM operaciones.estancia e
    WHERE e.id_habitacion = @p_id_habitacion
      AND e.estado_estancia = 'ACTIVA'
      AND e.fecha_checkin < @p_fecha_salida
      AND COALESCE(e.fecha_checkout, @p_fecha_salida) > @p_fecha_entrada;

    IF @v_conflictos = 0
        RETURN 1;

    RETURN 0;
END;
GO

/* Función 4: Costo total hospedaje */
CREATE OR ALTER FUNCTION finanzas.fn_calcular_costo_habitacion(@p_id_estancia INT)
RETURNS NUMERIC(10,2)
AS
BEGIN
    DECLARE @v_noches INT;
    DECLARE @v_precio_noche NUMERIC(10,2);
    DECLARE @v_costo_total NUMERIC(10,2);

    SET @v_noches = finanzas.fn_calcular_noches(@p_id_estancia);

    IF @v_noches IS NULL
        RETURN NULL;

    SELECT @v_precio_noche = th.precio_noche
    FROM operaciones.estancia e
    JOIN catalogo.habitacion h
        ON h.id_habitacion = e.id_habitacion
    JOIN catalogo.tipo_habitacion th
        ON th.id_tipo_habitacion = h.id_tipo_habitacion
    WHERE e.id_estancia = @p_id_estancia;

    IF @@ROWCOUNT = 0
        RETURN NULL;

    SET @v_costo_total = @v_noches * @v_precio_noche;

    RETURN @v_costo_total;
END;
GO

/* ============================================================
   PROCEDIMIENTOS ALMACENADOS
   ============================================================ */

/* Procedimiento 1: Check-in */
CREATE OR ALTER PROCEDURE operaciones.sp_realizar_checkin
    @p_id_reservacion INT,
    @p_id_habitacion INT,
    @p_id_empleado INT,
    @p_id_estancia_out INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_estado_reserva VARCHAR(20);
    DECLARE @v_estado_habitacion VARCHAR(20);
    DECLARE @v_id_huesped INT;

    SELECT
        @v_estado_reserva = estado_reserva,
        @v_id_huesped = id_huesped
    FROM operaciones.reservacion
    WHERE id_reservacion = @p_id_reservacion;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50001, 'No existe la reservacion especificada.',1;
    END;

    IF @v_estado_reserva <> 'CONFIRMADA'
    BEGIN
        RAISERROR('La reservacion no esta confirmada.',16,1);
        RETURN;
    END;

    SELECT @v_estado_habitacion = estado_habitacion
    FROM catalogo.habitacion
    WHERE id_habitacion = @p_id_habitacion;

    IF @@ROWCOUNT = 0
    BEGIN
        THROW 50002, 'No existe la habitacion especificada.',1;
    END;

    IF @v_estado_habitacion <> 'DISPONIBLE'
    BEGIN
        RAISERROR('La habitacion no esta disponible.',16,1);
        RETURN;
    END;

    INSERT INTO operaciones.estancia(
        fecha_checkin,
        fecha_checkout,
        estado_estancia,
        id_reservacion,
        id_habitacion,
        id_empleado_checkin
    )
    VALUES(
        GETDATE(),
        NULL,
        'ACTIVA',
        @p_id_reservacion,
        @p_id_habitacion,
        @p_id_empleado
    );

    SET @p_id_estancia_out = SCOPE_IDENTITY();

    INSERT INTO operaciones.acompanante(
        es_titular,
        id_estancia,
        id_huesped
    )
    VALUES(
        1,
        @p_id_estancia_out,
        @v_id_huesped
    );

    UPDATE catalogo.habitacion
    SET estado_habitacion = 'OCUPADA'
    WHERE id_habitacion = @p_id_habitacion;
END;
GO

/* Procedimiento 2: Check-out*/
CREATE OR ALTER PROCEDURE finanzas.sp_realizar_checkout
    @p_id_estancia INT,
    @p_id_empleado INT,
    @p_tipo_pago VARCHAR(30),
    @p_metodo_pago VARCHAR(30),
    @p_descuento NUMERIC(10,2),
    @p_id_factura_out INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_estado_estancia VARCHAR(20);
    DECLARE @v_id_habitacion INT;
    DECLARE @v_costo_habitacion NUMERIC(10,2);
    DECLARE @v_total_servicios NUMERIC(10,2);
    DECLARE @v_subtotal NUMERIC(10,2);
    DECLARE @v_impuestos NUMERIC(10,2);
    DECLARE @v_total NUMERIC(10,2);
    DECLARE @v_tasa_impuesto NUMERIC(5,4)=0.13;
    DECLARE @v_desc NUMERIC(10,2);
    DECLARE @v_noches INT;
    DECLARE @v_precio_noche NUMERIC(10,2);
    DECLARE @v_nombre_habitacion VARCHAR(50);

    SELECT
        @v_estado_estancia = estado_estancia,
        @v_id_habitacion = id_habitacion
    FROM operaciones.estancia
    WHERE id_estancia = @p_id_estancia;

    IF @@ROWCOUNT = 0
        THROW 50003,'No existe la estancia especificada.',1;

    IF @v_estado_estancia <> 'ACTIVA'
    BEGIN
        RAISERROR('La estancia no esta activa.',16,1);
        RETURN;
    END;

    IF EXISTS (
        SELECT 1
        FROM finanzas.factura
        WHERE id_estancia = @p_id_estancia
    )
    BEGIN
        RAISERROR('Ya existe una factura para esta estancia.',16,1);
        RETURN;
    END;

    UPDATE operaciones.estancia
    SET fecha_checkout = GETDATE(),
        estado_estancia = 'FINALIZADA'
    WHERE id_estancia = @p_id_estancia;

    SET @v_costo_habitacion =
        finanzas.fn_calcular_costo_habitacion(@p_id_estancia);

    SET @v_noches =
        finanzas.fn_calcular_noches(@p_id_estancia);

    SET @v_total_servicios =
        finanzas.fn_calcular_total_servicios(@p_id_estancia);

    SELECT
        @v_precio_noche = th.precio_noche,
        @v_nombre_habitacion = th.nombre_tipo
    FROM operaciones.estancia e
    JOIN catalogo.habitacion h
        ON h.id_habitacion = e.id_habitacion
    JOIN catalogo.tipo_habitacion th
        ON th.id_tipo_habitacion = h.id_tipo_habitacion
    WHERE e.id_estancia = @p_id_estancia;

    SET @v_desc = COALESCE(@p_descuento,0);
    SET @v_subtotal = @v_costo_habitacion + @v_total_servicios - @v_desc;
    SET @v_impuestos = ROUND(@v_subtotal * @v_tasa_impuesto,2);
    SET @v_total = @v_subtotal + @v_impuestos;

    INSERT INTO finanzas.factura(
        fecha_emision,
        subtotal,
        impuestos,
        descuento,
        total,
        estado_factura,
        fecha_pago,
        tipo_pago,
        metodo_pago,
        id_empleado,
        id_estancia
    )
    VALUES(
        GETDATE(),
        @v_subtotal,
        @v_impuestos,
        @v_desc,
        @v_total,
        CASE WHEN @p_metodo_pago='CONTADO'
             THEN 'PAGADO'
             ELSE 'PENDIENTE' END,
        CASE WHEN @p_metodo_pago='CONTADO'
             THEN GETDATE()
             ELSE NULL END,
        @p_tipo_pago,
        @p_metodo_pago,
        @p_id_empleado,
        @p_id_estancia
    );

    SET @p_id_factura_out = SCOPE_IDENTITY();

    INSERT INTO finanzas.detalle_factura(
        tipo_detalle,
        concepto,
        cantidad,
        precio_unitario,
        subtotal,
        id_factura,
        id_consumo
    )
    VALUES(
        'HABITACION',
        'Alojamiento - ' + @v_nombre_habitacion +
        ' (' + CAST(@v_noches AS VARCHAR) + ' noche(s))',
        @v_noches,
        @v_precio_noche,
        @v_costo_habitacion,
        @p_id_factura_out,
        NULL
    );

    INSERT INTO finanzas.detalle_factura(
        tipo_detalle,
        concepto,
        cantidad,
        precio_unitario,
        subtotal,
        id_factura,
        id_consumo
    )
    SELECT
        'SERVICIO',
        s.nombre,
        cs.cantidad,
        s.precio_unitario,
        cs.subtotal,
        @p_id_factura_out,
        cs.id_consumo
    FROM operaciones.consumo_servicio cs
    JOIN catalogo.servicio s
        ON s.id_servicio = cs.id_servicio
    WHERE cs.id_estancia = @p_id_estancia;
END;
GO

/* Procedimiento 3: Registrar consumo */
CREATE OR ALTER PROCEDURE operaciones.sp_registrar_consumo_servicio
    @p_id_estancia INT,
    @p_id_servicio INT,
    @p_id_empleado INT,
    @p_cantidad INT
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @v_precio_unitario NUMERIC(10,2);
    DECLARE @v_subtotal NUMERIC(10,2);
    DECLARE @v_estado_estancia VARCHAR(20);
    DECLARE @v_estado_servicio VARCHAR(20);

    IF @p_cantidad <= 0
    BEGIN
        RAISERROR('La cantidad debe ser mayor a cero.',16,1);
        RETURN;
    END;

    SELECT @v_estado_estancia = estado_estancia
    FROM operaciones.estancia
    WHERE id_estancia = @p_id_estancia;

    IF @@ROWCOUNT = 0
        THROW 50004,'No existe la estancia especificada.',1;

    IF @v_estado_estancia <> 'ACTIVA'
    BEGIN
        RAISERROR('La estancia no esta activa.',16,1);
        RETURN;
    END;

    SELECT
        @v_precio_unitario = precio_unitario,
        @v_estado_servicio = estado_servicio
    FROM catalogo.servicio
    WHERE id_servicio = @p_id_servicio;

    IF @@ROWCOUNT = 0
        THROW 50005,'No existe el servicio especificado.',1;

    IF @v_estado_servicio <> 'ACTIVO'
    BEGIN
        RAISERROR('El servicio no esta disponible actualmente.',16,1);
        RETURN;
    END;

    SET @v_subtotal = @p_cantidad * @v_precio_unitario;

    INSERT INTO operaciones.consumo_servicio(
        fecha_consumo,
        cantidad,
        subtotal,
        id_estancia,
        id_servicio,
        id_empleado
    )
    VALUES(
        GETDATE(),
        @p_cantidad,
        @v_subtotal,
        @p_id_estancia,
        @p_id_servicio,
        @p_id_empleado
    );
END;
GO
