USE bd_hotel_grupoAC;
GO

-----------------------------------------------------------
----- 1. TABLAS INDEPENDIENTES (Sin llaves foráneas) -------
-----------------------------------------------------------

CREATE TABLE hotel (
    id_hotel      INT IDENTITY(1,1),
    nombre        VARCHAR(100) NOT NULL,
    direccion     VARCHAR(200) NOT NULL,
    telefono      VARCHAR(20),
    correo        VARCHAR(150),
    num_estrellas INT,
    CONSTRAINT pk_hotel PRIMARY KEY (id_hotel),
    CONSTRAINT uq_hotel_correo UNIQUE (correo),
    CONSTRAINT ck_hotel_correo CHECK (correo LIKE '%@%.%'),
    CONSTRAINT ck_hotel_num_estrellas CHECK (num_estrellas BETWEEN 1 AND 5)
);
GO

CREATE TABLE huesped (
    id_huesped          INT IDENTITY(1,1),
    nombre              VARCHAR(100) NOT NULL,
    apellido            VARCHAR(100) NOT NULL,
    documento_identidad VARCHAR(30)  NOT NULL,
    telefono            VARCHAR(20),
    correo              VARCHAR(100),
    direccion           VARCHAR(255),
    tipo_documento      VARCHAR(30)  NOT NULL,
    nacionalidad        VARCHAR(50),
    fecha_registro      DATE         NOT NULL,
    CONSTRAINT pk_huesped PRIMARY KEY (id_huesped),
    CONSTRAINT uq_huesped_correo UNIQUE (correo),
    CONSTRAINT ck_huesped_correo CHECK (correo LIKE '%@%.%'),
    CONSTRAINT ck_huesped_tipo_documento CHECK (tipo_documento IN ('DUI','PASAPORTE','CARNET_RESIDENCIA')),
    CONSTRAINT uq_huesped_documento_identidad UNIQUE (documento_identidad)
);
GO

CREATE TABLE tipo_habitacion (
    id_tipo_habitacion INT IDENTITY(1,1),
    nombre_tipo        VARCHAR(50)     NOT NULL,
    descripcion        VARCHAR(MAX),
    capacidad          INT             NOT NULL,
    precio_noche       NUMERIC(10,2)   NOT NULL,
    CONSTRAINT pk_tipo_habitacion PRIMARY KEY (id_tipo_habitacion),
    CONSTRAINT ck_tipo_habitacion_capacidad CHECK (capacidad > 0),
    CONSTRAINT ck_tipo_habitacion_precio CHECK (precio_noche >= 0)
);
GO

CREATE TABLE servicio (
    id_servicio     INT IDENTITY(1,1),
    nombre          VARCHAR(100)  NOT NULL,
    descripcion     VARCHAR(MAX),
    precio_unitario NUMERIC(10,2) NOT NULL,
    estado_servicio VARCHAR(20)   NOT NULL,
    categoria       VARCHAR(50),
    CONSTRAINT pk_servicio PRIMARY KEY (id_servicio),
    CONSTRAINT ck_servicio_estado CHECK (estado_servicio IN ('ACTIVO','INACTIVO')),
    CONSTRAINT ck_servicio_precio CHECK (precio_unitario >= 0)
);
GO


-----------------------------------------------------------
----- 2. TABLAS DE PRIMER NIVEL DE DEPENDENCIA ------------
-----------------------------------------------------------

CREATE TABLE empleado (
     id_empleado        INT IDENTITY(1,1),
     nombre             VARCHAR(100) NOT NULL,
     apellido           VARCHAR(100) NOT NULL,
     cargo              VARCHAR(100),
     telefono           VARCHAR(20),
     correo             VARCHAR(100),
     estado_empleado    VARCHAR(20)  NOT NULL,
     fecha_contratacion DATE         NOT NULL,
     turno              VARCHAR(20),
     id_hotel           INT          NOT NULL,
     CONSTRAINT pk_empleado PRIMARY KEY (id_empleado),
     CONSTRAINT ck_empleado_correo CHECK (correo LIKE '%@%.%'),
     CONSTRAINT ck_empleado_estado CHECK (estado_empleado IN ('ACTIVO','INACTIVO','VACACIONES','SUSPENDIDO')),
     CONSTRAINT ck_empleado_turno CHECK (turno IN ('MANANA','TARDE','NOCHE')),
     CONSTRAINT fk_empleado_hotel 
         FOREIGN KEY (id_hotel) 
         REFERENCES hotel(id_hotel)
     ON UPDATE NO ACTION
     ON DELETE NO ACTION
);
GO

CREATE TABLE habitacion (
    id_habitacion      INT IDENTITY(1,1),
    numero_habitacion  VARCHAR(10) NOT NULL,
    nivel              INT,
    estado_habitacion  VARCHAR(20) NOT NULL,
    id_hotel           INT         NOT NULL,
    id_tipo_habitacion INT         NOT NULL,
    CONSTRAINT pk_habitacion PRIMARY KEY (id_habitacion),
    CONSTRAINT uq_habitacion_numero UNIQUE(numero_habitacion, id_hotel),
    CONSTRAINT ck_habitacion_estado CHECK (estado_habitacion IN ('DISPONIBLE','OCUPADA','MANTENIMIENTO','LIMPIEZA')),
    CONSTRAINT ck_habitacion_nivel CHECK (nivel >= 0),
    CONSTRAINT fk_habitacion_hotel 
        FOREIGN KEY (id_hotel) 
        REFERENCES hotel(id_hotel)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_habitacion_tipo 
        FOREIGN KEY (id_tipo_habitacion) 
        REFERENCES tipo_habitacion(id_tipo_habitacion)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
);
GO


-----------------------------------------------------------
----- 3. TABLAS DE SEGUNDO NIVEL DE DEPENDENCIA -----------
-----------------------------------------------------------

CREATE TABLE reservacion (
    id_reservacion     INT IDENTITY(1,1),
    fecha_reserva      DATE        NOT NULL,
    fecha_entrada      DATE        NOT NULL,
    fecha_salida       DATE        NOT NULL,
    estado_reserva     VARCHAR(20) NOT NULL,
    canal_reserva      VARCHAR(50),
    id_huesped         INT         NOT NULL,
    id_empleado        INT         NOT NULL,
    id_tipo_habitacion INT         NOT NULL,
    CONSTRAINT pk_reservacion PRIMARY KEY (id_reservacion),
    CONSTRAINT ck_reserva_fechas CHECK (fecha_salida > fecha_entrada),
    CONSTRAINT ck_reserva_estado CHECK (estado_reserva IN ('PENDIENTE','CONFIRMADA','CANCELADA')),
    CONSTRAINT ck_reserva_canal CHECK (canal_reserva IN ('WEB','TELEFONO','RECEPCION','AGENCIA')),
    CONSTRAINT fk_reserva_huesped 
        FOREIGN KEY (id_huesped) 
        REFERENCES huesped(id_huesped)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_reserva_empleado 
        FOREIGN KEY (id_empleado) 
        REFERENCES empleado(id_empleado)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_reserva_tipo 
        FOREIGN KEY (id_tipo_habitacion) 
        REFERENCES tipo_habitacion(id_tipo_habitacion)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
);
GO


-----------------------------------------------------------
----- 4. TABLAS DE TERCER NIVEL DE DEPENDENCIA ------------
-----------------------------------------------------------

CREATE TABLE estancia (
    id_estancia         INT IDENTITY(1,1),
    fecha_checkin       DATETIME2   NOT NULL,
    fecha_checkout      DATETIME2,
    estado_estancia     VARCHAR(20) NOT NULL,
    id_reservacion      INT         NOT NULL,
    id_habitacion       INT         NOT NULL,
    id_empleado_checkin INT         NOT NULL,
    CONSTRAINT pk_estancia PRIMARY KEY (id_estancia),
    CONSTRAINT ck_estancia_estado CHECK (estado_estancia IN ('ACTIVA','FINALIZADA','CANCELADA')),
    CONSTRAINT ck_estancia_fechas CHECK (fecha_checkout IS NULL OR fecha_checkout > fecha_checkin),
    CONSTRAINT fk_estancia_reserva 
        FOREIGN KEY (id_reservacion) 
        REFERENCES reservacion(id_reservacion)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_estancia_habitacion 
        FOREIGN KEY (id_habitacion) 
        REFERENCES habitacion(id_habitacion)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_estancia_empleado 
        FOREIGN KEY (id_empleado_checkin) 
        REFERENCES empleado(id_empleado)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
);
GO


-----------------------------------------------------------
----- 5. TABLAS DERIVADAS DE ESTANCIA ---------------------
-----------------------------------------------------------

CREATE TABLE acompanante (
    id_acompanante INT IDENTITY(1,1),
    es_titular     BIT NOT NULL DEFAULT 0,
    id_estancia    INT NOT NULL,
    id_huesped     INT NOT NULL,
    CONSTRAINT pk_acompanante PRIMARY KEY (id_acompanante),
    CONSTRAINT fk_acompanante_estancia
        FOREIGN KEY (id_estancia)
        REFERENCES estancia(id_estancia)
    ON UPDATE NO ACTION
    ON DELETE CASCADE,
    CONSTRAINT fk_acompanante_huesped
        FOREIGN KEY (id_huesped)
        REFERENCES huesped(id_huesped)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
);
GO

CREATE TABLE consumo_servicio (
    id_consumo    INT IDENTITY(1,1), 
    fecha_consumo DATETIME2     NOT NULL,
    cantidad      INT           NOT NULL,
    subtotal      NUMERIC(10,2) NOT NULL,
    id_estancia   INT           NOT NULL,
    id_servicio   INT           NOT NULL,
    id_empleado   INT           NOT NULL,
    CONSTRAINT pk_consumo_servicio PRIMARY KEY (id_consumo),
    CONSTRAINT ck_consumo_subtotal CHECK (subtotal >= 0),
    CONSTRAINT ck_consumo_cantidad CHECK (cantidad > 0),
    CONSTRAINT fk_consumo_estancia 
        FOREIGN KEY (id_estancia) 
        REFERENCES estancia(id_estancia)
    ON UPDATE NO ACTION
    ON DELETE CASCADE,
    CONSTRAINT fk_consumo_servicio 
        FOREIGN KEY (id_servicio) 
        REFERENCES servicio(id_servicio)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_consumo_empleado 
        FOREIGN KEY (id_empleado) 
        REFERENCES empleado(id_empleado)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
);
GO

CREATE TABLE factura (
    id_factura     INT IDENTITY(1,1),
    fecha_emision  DATETIME2     NOT NULL,
    subtotal       NUMERIC(10,2) NOT NULL,
    impuestos      NUMERIC(10,2) NOT NULL,
    descuento      NUMERIC(10,2),
    total          NUMERIC(10,2) NOT NULL,
    estado_factura VARCHAR(20)   NOT NULL,
    fecha_pago     DATETIME2,
    tipo_pago      VARCHAR(30),
    metodo_pago    VARCHAR(30)   NOT NULL,
    id_empleado    INT           NOT NULL,
    id_estancia    INT           NOT NULL,
    CONSTRAINT pk_factura PRIMARY KEY (id_factura),
    CONSTRAINT uq_factura_estancia UNIQUE (id_estancia),
    CONSTRAINT ck_factura_subtotal CHECK (subtotal >= 0),
    CONSTRAINT ck_factura_total CHECK (total >= 0),
    CONSTRAINT ck_factura_descuento CHECK (descuento >= 0),
    CONSTRAINT ck_factura_impuestos CHECK (impuestos >= 0),
    CONSTRAINT ck_factura_estado CHECK (estado_factura IN ('PENDIENTE', 'PAGADO', 'CANCELADO')),
    CONSTRAINT ck_factura_tipo_pago CHECK (tipo_pago IN ('EFECTIVO', 'TARJETA', 'TRANSFERENCIA')),
    CONSTRAINT ck_factura_metodo CHECK (metodo_pago IN ('CONTADO','CREDITO')),
    CONSTRAINT fk_factura_empleado 
        FOREIGN KEY (id_empleado) 
        REFERENCES empleado(id_empleado)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION,
    CONSTRAINT fk_factura_estancia 
        FOREIGN KEY (id_estancia) 
        REFERENCES estancia(id_estancia)
    ON UPDATE NO ACTION
    ON DELETE NO ACTION
);
GO


-----------------------------------------------------------
----- 6. TABLA FINAL DE DETALLE ---------------------------
-----------------------------------------------------------

CREATE TABLE detalle_factura (
    id_detalle_factura INT IDENTITY(1,1),
    tipo_detalle       VARCHAR(30)   NOT NULL,
    concepto           VARCHAR(225)  NOT NULL,
    cantidad           INT           NOT NULL,
    precio_unitario    NUMERIC(10,2) NOT NULL,
    subtotal           NUMERIC(10,2) NOT NULL,
    id_factura         INT           NOT NULL,
    id_consumo         INT,
    CONSTRAINT pk_detalle_factura PRIMARY KEY (id_detalle_factura),
    CONSTRAINT ck_detalle_cantidad CHECK (cantidad > 0),
    CONSTRAINT ck_detalle_tipo CHECK (tipo_detalle IN ('HABITACION','SERVICIO')),
    CONSTRAINT ck_detalle_precio CHECK (precio_unitario >= 0),
    CONSTRAINT ck_detale_subtotal CHECK (subtotal >= 0),
    CONSTRAINT fk_detalle_factura 
        FOREIGN KEY (id_factura) 
        REFERENCES factura(id_factura)
        ON UPDATE NO ACTION
        ON DELETE CASCADE,
    CONSTRAINT fk_detalle_consumo 
        FOREIGN KEY (id_consumo) 
        REFERENCES consumo_servicio(id_consumo)
        ON UPDATE NO ACTION
        ON DELETE SET NULL
);
GO
