/* ============================================================
   DATOS DE PRUEBA - bd_hotel_grupoAC
   Uso: ejecutar DESPUES de 02_tables.sql y 03_schemas.sql (y los objetos requeridos por los triggers)
   Contenido: 110 huespedes (10 base + 100 adicionales)
              111 reservaciones (11 base + 100 adicionales)
   ============================================================ */
USE bd_hotel_grupoAC;
GO

SET NOCOUNT ON;
GO

/* ------------------------------------------------------------
   1. HOTELES
------------------------------------------------------------ */
SET IDENTITY_INSERT catalogo.hotel ON;
INSERT INTO catalogo.hotel (id_hotel, nombre, direccion, telefono, correo, num_estrellas) VALUES
(1, 'Hotel Playa Verde', 'Av. Costanera 123, San Salvador', '2222-1001', 'info@playaverde.com', 4),
(2, 'Hotel Montaña Azul', 'Km 45 Carretera al Boquerón', '2222-1002', 'contacto@montanaazul.com', 3);
SET IDENTITY_INSERT catalogo.hotel OFF;
GO

/* ------------------------------------------------------------
   2. TIPOS DE HABITACION
------------------------------------------------------------ */
SET IDENTITY_INSERT catalogo.tipo_habitacion ON;
INSERT INTO catalogo.tipo_habitacion (id_tipo_habitacion, nombre_tipo, descripcion, capacidad, precio_noche) VALUES
(1, 'Sencilla',   'Cama individual, TV, WiFi',            1, 45.00),
(2, 'Doble',      'Dos camas dobles, TV, WiFi, minibar',  4, 75.00),
(3, 'Suite',      'King size, sala, jacuzzi, vista al mar',2, 150.00),
(4, 'Familiar',   'Dos habitaciones conectadas, 6 camas',  6, 120.00);
SET IDENTITY_INSERT catalogo.tipo_habitacion OFF;
GO

/* ------------------------------------------------------------
   3. SERVICIOS
------------------------------------------------------------ */
SET IDENTITY_INSERT catalogo.servicio ON;
INSERT INTO catalogo.servicio (id_servicio, nombre, descripcion, precio_unitario, estado_servicio, categoria) VALUES
(1, 'Desayuno buffet',      'Desayuno completo 7am-10am',   8.50,  'ACTIVO',   'Alimentacion'),
(2, 'Cena restaurante',     'Plato principal + bebida',     15.00, 'ACTIVO',   'Alimentacion'),
(3, 'Lavanderia',           'Por libra de ropa',            5.00,  'ACTIVO',   'Lavanderia'),
(4, 'Transporte aeropuerto','Van privado ida o vuelta',     25.00, 'ACTIVO',   'Transporte'),
(5, 'Spa y masajes',        'Masaje relajante 60 min',      35.00, 'ACTIVO',   'Bienestar'),
(6, 'Room service',         'Cargo por entrega a habitacion',3.00,  'ACTIVO',   'Alimentacion'),
(7, 'Guia turistico',       'Tour ciudad medio dia',        20.00, 'INACTIVO', 'Turismo');
SET IDENTITY_INSERT catalogo.servicio OFF;
GO

/* ------------------------------------------------------------
   4. HUESPEDES
   4.1 Huespedes base (1-10): usados por estancias/acompanantes
------------------------------------------------------------ */
SET IDENTITY_INSERT operaciones.huesped ON;
INSERT INTO operaciones.huesped (id_huesped, nombre, apellido, documento_identidad, telefono, correo, direccion, tipo_documento, nacionalidad, fecha_registro) VALUES
(1, 'Carlos',   'Ramirez',    '00123456-7', '7777-0001', 'carlos.ramirez@gmail.com',   'Col. Escalón, San Salvador',   'DUI',             'El Salvador',  '2025-01-10'),
(2, 'Ana',      'Martinez',   '00876543-2', '7777-0002', 'ana.martinez@gmail.com',     'Santa Tecla, La Libertad',     'DUI',             'El Salvador',  '2025-01-15'),
(3, 'John',     'Smith',      'P1234567',   '7777-0003', 'john.smith@outlook.com',     'New York, USA',                'PASAPORTE',       'Estados Unidos','2025-02-01'),
(4, 'Maria',    'Fernandez',  '00987654-1', '7777-0004', 'maria.fernandez@gmail.com',  'San Miguel, San Miguel',       'DUI',             'El Salvador',  '2025-02-05'),
(5, 'Lucia',    'Gomez',      'P7654321',   '7777-0005', 'lucia.gomez@gmail.com',      'Madrid, España',               'PASAPORTE',       'España',       '2025-02-20'),
(6, 'Pedro',    'Hernandez',  '00567891-3', '7777-0006', 'pedro.hernandez@gmail.com',  'Soyapango, San Salvador',      'DUI',             'El Salvador',  '2025-03-01'),
(7, 'Sofia',    'Lopez',      'P1122334',   '7777-0007', 'sofia.lopez@gmail.com',      'Ciudad de México, México',     'PASAPORTE',       'México',       '2025-03-10'),
(8, 'Ricardo',  'Torres',     '00334455-6', '7777-0008', 'ricardo.torres@gmail.com',   'Sonsonate, Sonsonate',         'DUI',             'El Salvador',  '2025-03-15'),
(9, 'Elena',    'Castillo',   '00778899-0', '7777-0009', 'elena.castillo@gmail.com',   'Santa Ana, Santa Ana',         'DUI',             'El Salvador',  '2025-04-01'),
(10,'David',    'Ortiz',      'P9988776',   '7777-0010', 'david.ortiz@gmail.com',      'Toronto, Canadá',              'PASAPORTE',       'Canadá',       '2025-04-10');
SET IDENTITY_INSERT operaciones.huesped OFF;
GO

/* ------------------------------------------------------------
   4.2 Huespedes adicionales (100 registros -> ids 11 a 110)
------------------------------------------------------------ */
INSERT INTO operaciones.huesped (nombre, apellido, documento_identidad, telefono, correo, direccion, tipo_documento, nacionalidad, fecha_registro) VALUES
('Carlos', 'Rubio', '01234567-1', '7123-4567', 'carlos.rubio@gmail.com', 'Col. Escalon, San Salvador', 'DUI', 'El Salvador', '2026-01-10'),
('Sofia', 'Menjivar', '02345678-2', '7234-5678', 'sofia.menjivar@outlook.com', 'Santa Ana Centro', 'DUI', 'El Salvador', '2026-01-12'),
('Mateo', 'Gomez', 'P98765431', '502-5555-0101', 'mateo.gomez@hotmail.com', 'Zona 10, Ciudad de Guatemala', 'PASAPORTE', 'Guatemala', '2026-01-15'),
('Valeria', 'Lopez', 'P87654322', '504-9999-0202', 'vlopez@yahoo.com', 'Col. Palmira, Tegucigalpa', 'PASAPORTE', 'Honduras', '2026-01-18'),
('Diego', 'Hernandez', 'P76543213', '506-8888-0303', 'dhernandez@gmail.com', 'San Jose Centro', 'PASAPORTE', 'Costa Rica', '2026-01-20'),
('Camila', 'Martinez', 'P65432104', '52-55-1234-5678', 'camila.martinez@gmail.com', 'Polanco, CDMX', 'PASAPORTE', 'Mexico', '2026-01-22'),
('Lucas', 'Perez', 'P54321095', '1-305-555-0199', 'lucas.perez@aol.com', 'Brickell Ave, Miami', 'PASAPORTE', 'Estados Unidos', '2026-01-25'),
('Mariana', 'Rodriguez', '03456789-3', '7345-6789', 'mariana.rodriguez@gmail.com', 'San Miguel Centro', 'DUI', 'El Salvador', '2026-01-28'),
('Alejandro', 'Sanchez', 'P43210986', '34-91-555-0144', 'asanchez@hotmail.com', 'Gran Via, Madrid', 'PASAPORTE', 'Espana', '2026-02-01'),
('Lucia', 'Ramirez', 'P32109877', '57-601-555-0188', 'lramirez@gmail.com', 'El Poblado, Medellin', 'PASAPORTE', 'Colombia', '2026-02-03'),
('Fernando', 'Torres', '04567890-4', '7456-7890', 'ftorres@gmail.com', 'Antiguo Cuscatlan', 'DUI', 'El Salvador', '2026-02-05'),
('Gabriela', 'Morales', '05678901-5', '7567-8901', 'gabi.morales@outlook.com', 'Santa Tecla', 'DUI', 'El Salvador', '2026-02-08'),
('Adrian', 'Castillo', 'P21098768', '502-5555-0202', 'acastillo@gmail.com', 'Quetzaltenango', 'PASAPORTE', 'Guatemala', '2026-02-10'),
('Daniela', 'Flores', '06789012-6', '7678-9012', 'daniela.flores@yahoo.com', 'Sonsonate Centro', 'DUI', 'El Salvador', '2026-02-12'),
('Javier', 'Navarro', 'P10987659', '52-81-1234-8899', 'jnavarro@gmail.com', 'Monterrey, NL', 'PASAPORTE', 'Mexico', '2026-02-15'),
('Paula', 'Mendoza', '07890123-7', '7789-0123', 'pmendoza@gmail.com', 'Col. San Benito, San Salvador', 'DUI', 'El Salvador', '2026-02-18'),
('Hugo', 'Aguilar', 'P09876540', '504-8888-0404', 'hugo.aguilar@outlook.com', 'San Pedro Sula', 'PASAPORTE', 'Honduras', '2026-02-20'),
('Natalia', 'Rios', '08901234-8', '7890-1234', 'nrios@gmail.com', 'Ahuachapan Centro', 'DUI', 'El Salvador', '2026-02-22'),
('Emanuel', 'Reyes', 'P90123456', '506-7777-0505', 'ereyes@gmail.com', 'Heredia', 'PASAPORTE', 'Costa Rica', '2026-02-25'),
('Andrea', 'Vargas', '09012345-9', '7901-2345', 'andrea.vargas@yahoo.com', 'Cojutepeque', 'DUI', 'El Salvador', '2026-02-28'),
('Sonia', 'Alvarado', '10123456-0', '7012-3456', 'sonia.alvarado@gmail.com', 'Usulutan Centro', 'DUI', 'El Salvador', '2026-03-01'),
('Rodrigo', 'Pineda', '11234567-1', '7123-9988', 'rpineda@gmail.com', 'La Libertad Centro', 'DUI', 'El Salvador', '2026-03-02'),
('Claudia', 'Fuentes', 'P81234567', '502-4444-0303', 'cfuentes@hotmail.com', 'Antigua Guatemala', 'PASAPORTE', 'Guatemala', '2026-03-04'),
('Gonzalo', 'Miranda', '12345678-2', '7234-8877', 'gmiranda@outlook.com', 'Chalatenango Centro', 'DUI', 'El Salvador', '2026-03-05'),
('Irene', 'Carrillo', '13456789-3', '7345-7766', 'icarrillo@gmail.com', 'San Vicente Centro', 'DUI', 'El Salvador', '2026-03-07'),
('Esteban', 'Solis', 'P71234568', '506-6666-0606', 'esolis@yahoo.com', 'Alajuela', 'PASAPORTE', 'Costa Rica', '2026-03-08'),
('Monica', 'Lara', '14567890-4', '7456-6655', 'mlara@gmail.com', 'Zacatecoluca', 'DUI', 'El Salvador', '2026-03-10'),
('Samuel', 'Campos', '15678901-5', '7567-5544', 'scampos@gmail.com', 'Col. Flor Blanca, San Salvador', 'DUI', 'El Salvador', '2026-03-11'),
('Renata', 'Mejia', 'P61234569', '52-33-9988-7766', 'rmejia@outlook.com', 'Guadalajara, Jalisco', 'PASAPORTE', 'Mexico', '2026-03-13'),
('Victor', 'Cabrera', '16789012-6', '7678-4433', 'vcabrera@gmail.com', 'Merliot, La Libertad', 'DUI', 'El Salvador', '2026-03-14'),
('Alicia', 'Salazar', '17890123-7', '7789-3322', 'asalazar@yahoo.com', 'Metapan', 'DUI', 'El Salvador', '2026-03-16'),
('Guillermo', 'Pena', 'P51234570', '504-7777-0808', 'gpena@gmail.com', 'La Ceiba', 'PASAPORTE', 'Honduras', '2026-03-17'),
('Isabel', 'Franco', '18901234-8', '7890-2211', 'ifranco@gmail.com', 'Soyapango Centro', 'DUI', 'El Salvador', '2026-03-19'),
('Manuel', 'Cardenas', '19012345-9', '7901-1100', 'mcardenas@hotmail.com', 'Ilopango', 'DUI', 'El Salvador', '2026-03-20'),
('Veronica', 'Espinosa', 'P41234571', '57-604-444-0101', 'vespinosa@gmail.com', 'Bogota DC', 'PASAPORTE', 'Colombia', '2026-03-22'),
('Oscar', 'Roldan', '20123456-0', '7012-0099', 'oroldan@gmail.com', 'Apopa Centro', 'DUI', 'El Salvador', '2026-03-23'),
('Beatriz', 'Arias', '21234567-1', '7123-8811', 'barias@outlook.com', 'Meicanos', 'DUI', 'El Salvador', '2026-03-25'),
('Cesar', 'Mora', 'P31234572', '506-8888-0909', 'cmora@gmail.com', 'Cartago', 'PASAPORTE', 'Costa Rica', '2026-03-26'),
('Diana', 'Guerrero', '22345678-2', '7234-7722', 'dguerrero@yahoo.com', 'Col. Escalon Norte', 'DUI', 'El Salvador', '2026-03-28'),
('Emilio', 'Nunez', '23456789-3', '7345-6633', 'enunez@gmail.com', 'San Martin', 'DUI', 'El Salvador', '2026-03-29'),
('Fabiola', 'Paredes', 'P21234573', '502-3333-0909', 'fparedes@gmail.com', 'Escuintla', 'PASAPORTE', 'Guatemala', '2026-03-31'),
('Gabriel', 'Serrano', '24567890-4', '7456-5544', 'gserrano@hotmail.com', 'Delgado Centro', 'DUI', 'El Salvador', '2026-04-01'),
('Helena', 'Ochoa', '25678901-5', '7567-4455', 'hochoa@gmail.com', 'Cuscatancingo', 'DUI', 'El Salvador', '2026-04-03'),
('Ignacio', 'Tapia', 'P11234574', '52-55-9900-1122', 'itapia@gmail.com', 'Puebla Centro', 'PASAPORTE', 'Mexico', '2026-04-04'),
('Juliana', 'Valdez', '26789012-6', '7678-3366', 'jvaldez@outlook.com', 'San Marcos Centro', 'DUI', 'El Salvador', '2026-04-06'),
('Kevin', 'Alas', '27890123-7', '7789-2277', 'kalas@gmail.com', 'Lourdes Colon', 'DUI', 'El Salvador', '2026-04-07'),
('Lorena', 'Zelaya', '28901234-8', '7890-1188', 'lzelaya@yahoo.com', 'Ciudad Arce', 'DUI', 'El Salvador', '2026-04-09'),
('Mauricio', 'Brescia', 'P01234575', '39-06-555-0199', 'mbrescia@gmail.com', 'Roma Centro', 'PASAPORTE', 'Italia', '2026-04-10'),
('Nuria', 'Gallegos', '29012345-9', '7901-0099', 'ngallegos@gmail.com', 'Opico Centro', 'DUI', 'El Salvador', '2026-04-12'),
('Orlando', 'Corta', '30123456-0', '7012-9900', 'ocorta@gmail.com', 'Quezaltepeque', 'DUI', 'El Salvador', '2026-04-13'),
('Patricia', 'Quinteros', '31234567-1', '7123-8800', 'pquinteros@outlook.com', 'Aguilares', 'DUI', 'El Salvador', '2026-04-15'),
('Quirino', 'Bautista', 'P98761234', '502-7777-0101', 'qbautista@gmail.com', 'Chimaltenango', 'PASAPORTE', 'Guatemala', '2026-04-16'),
('Rosario', 'Santana', '32345678-2', '7234-6600', 'rsantana@yahoo.com', 'Guazapa', 'DUI', 'El Salvador', '2026-04-18'),
('Sebastian', 'Vidal', '33456789-3', '7345-5500', 'svidal@gmail.com', 'Nejapa', 'DUI', 'El Salvador', '2026-04-19'),
('Tania', 'Cisneros', '34567890-4', '7456-4400', 'tcisneros@gmail.com', 'Tonacatepeque', 'DUI', 'El Salvador', '2026-04-21'),
('Uriel', 'Pacheco', 'P88761235', '504-3333-0202', 'apacheco@hotmail.com', 'Choluteca', 'PASAPORTE', 'Honduras', '2026-04-22'),
('Vanessa', 'Guzman', '35678901-5', '7567-3300', 'vguzman@gmail.com', 'Panchimalco', 'DUI', 'El Salvador', '2026-04-24'),
('Walter', 'Portillo', '36789012-6', '7678-2200', 'wportillo@outlook.com', 'Santo Tomas', 'DUI', 'El Salvador', '2026-04-25'),
('Ximena', 'Ibarra', 'P78761236', '52-81-8877-6655', 'xibarra@gmail.com', 'Queretaro', 'PASAPORTE', 'Mexico', '2026-04-27'),
('Yolanda', 'Sola', '37890123-7', '7789-1100', 'ysola@yahoo.com', 'Santiago Texacuangos', 'DUI', 'El Salvador', '2026-04-28'),
('Zacarias', 'Benitez', '38901234-8', '7890-0011', 'zbenitez@gmail.com', 'Rosario de Mora', 'DUI', 'El Salvador', '2026-04-30'),
('Alvaro', 'Montes', '39012345-9', '7901-9922', 'amontes@gmail.com', 'Zaragoza', 'DUI', 'El Salvador', '2026-05-02'),
('Bianca', 'Sosa', 'P68761237', '506-2222-0303', 'bsosa@outlook.com', 'Puntarenas', 'PASAPORTE', 'Costa Rica', '2026-05-03'),
('Camilo', 'Duarte', '40123456-0', '7012-8833', 'cduarte@gmail.com', 'San Jose Villanueva', 'DUI', 'El Salvador', '2026-05-05'),
('Delia', 'Nieto', '41234567-1', '7123-7744', 'dnieto@yahoo.com', 'Huizucar', 'DUI', 'El Salvador', '2026-05-06'),
('Edgar', 'Coronado', 'P58761238', '502-6666-0404', 'ecoronado@gmail.com', 'Coban', 'PASAPORTE', 'Guatemala', '2026-05-08'),
('Flavia', 'Olivares', '42345678-2', '7234-6655', 'folivares@gmail.com', 'Nuevo Cuscatlan', 'DUI', 'El Salvador', '2026-05-09'),
('Gustavo', 'Barrios', '43456789-3', '7345-5566', 'gbarrios@hotmail.com', 'Col. Utila, Santa Tecla', 'DUI', 'El Salvador', '2026-05-11'),
('Hilda', 'Tellez', '44567890-4', '7456-4477', 'htellez@gmail.com', 'San Juan Opico', 'DUI', 'El Salvador', '2026-05-12'),
('Ismael', 'Palacios', 'P48761239', '504-2222-0505', 'ipalacios@outlook.com', 'Comayagua', 'PASAPORTE', 'Honduras', '2026-05-14'),
('Jacqueline', 'Mora', '45678901-5', '7567-3388', 'jmora@gmail.com', 'Ciudad Merliot', 'DUI', 'El Salvador', '2026-05-15'),
('Leonel', 'Samayoa', '46789012-6', '7678-2299', 'lsamayoa@yahoo.com', 'Santa Rosa de Lima', 'DUI', 'El Salvador', '2026-05-17'),
('Miriam', 'Villegas', 'P38761240', '52-55-4433-2211', 'mvillegas@gmail.com', 'Veracruz', 'PASAPORTE', 'Mexico', '2026-05-18'),
('Nelson', 'Orellana', '47890123-7', '7789-1100', 'norellana@gmail.com', 'Chalchuapa', 'DUI', 'El Salvador', '2026-05-20'),
('Olga', 'Escobar', '48901234-8', '7890-0011', 'oescobar@hotmail.com', 'Atiquizaya', 'DUI', 'El Salvador', '2026-05-21'),
('Pablo', 'Cornejo', '49012345-9', '7901-9922', 'pcornejo@gmail.com', 'Jujutla', 'DUI', 'El Salvador', '2026-05-23'),
('Raquel', 'Rivas', 'P28761241', '502-8888-0505', 'rrivas@outlook.com', 'Huehuetenango', 'PASAPORTE', 'Guatemala', '2026-05-24'),
('Saul', 'Chavez', '50123456-0', '7012-8833', 'schavez@gmail.com', 'Sonsonate Centro', 'DUI', 'El Salvador', '2026-05-26'),
('Teresa', 'Galdamez', '51234567-1', '7123-7744', 'tgaldamez@yahoo.com', 'Izalco', 'DUI', 'El Salvador', '2026-05-27'),
('Ulises', 'Melendez', '52345678-2', '7234-6655', 'umelendez@gmail.com', 'Nahuizalco', 'DUI', 'El Salvador', '2026-05-29'),
('Vilma', 'Funes', '53456789-3', '7345-5566', 'vfunes@gmail.com', 'Acajutla', 'DUI', 'El Salvador', '2026-05-30'),
('Wilfredo', 'Ceron', '54567890-4', '7456-4477', 'wceron@hotmail.com', 'Armenia', 'DUI', 'El Salvador', '2026-06-01'),
('Xiomara', 'Lazo', 'P18761242', '504-9999-0606', 'xlazo@gmail.com', 'Copan Ruinas', 'PASAPORTE', 'Honduras', '2026-06-02'),
('Yamil', 'Bukele', '55678901-5', '7567-3388', 'ybukele@gmail.com', 'Col. Escalon, San Salvador', 'DUI', 'El Salvador', '2026-06-04'),
('Zulma', 'Aparicio', '56789012-6', '7678-2299', 'zaparicio@outlook.com', 'Berlin, Usulutan', 'DUI', 'El Salvador', '2026-06-05'),
('Armando', 'Paz', '57890123-7', '7789-1100', 'apaz@gmail.com', 'Santiago de Maria', 'DUI', 'El Salvador', '2026-06-07'),
('Brenda', 'Molina', '58901234-8', '7890-0011', 'bmolina@yahoo.com', 'Jiquilisco', 'DUI', 'El Salvador', '2026-06-08'),
('Cristian', 'Lemus', 'P08761243', '506-3333-0707', 'clemus@gmail.com', 'Liberia, Guanacaste', 'PASAPORTE', 'Costa Rica', '2026-06-10'),
('Dora', 'Recinos', '59012345-9', '7901-9922', 'drecinos@gmail.com', 'Ilobasco', 'DUI', 'El Salvador', '2026-06-11'),
('Efrain', 'Beltran', '60123456-0', '7012-8833', 'ebeltran@hotmail.com', 'Sensuntepeque', 'DUI', 'El Salvador', '2026-06-13'),
('Gisela', 'Soriano', '61234567-1', '7123-7744', 'gsoriano@gmail.com', 'San Rafael Cedros', 'DUI', 'El Salvador', '2026-06-14'),
('Hector', 'Castaneda', 'P97651244', '52-33-1122-3344', 'hcastaneda@outlook.com', 'Tijuana, BC', 'PASAPORTE', 'Mexico', '2026-06-16'),
('Ines', 'Osorio', '62345678-2', '7234-6655', 'iosorio@gmail.com', 'San Pedro Perulapan', 'DUI', 'El Salvador', '2026-06-17'),
('Jorge', 'Ayala', '63456789-3', '7345-5566', 'jayala@yahoo.com', 'Suchitoto', 'DUI', 'El Salvador', '2026-06-19'),
('Kenia', 'Guitron', '64567890-4', '7456-4477', 'kguitron@gmail.com', 'Tenancingo', 'DUI', 'El Salvador', '2026-06-20'),
('Lazaro', 'Calderon', 'P87651245', '502-2222-0808', 'lcalderon@gmail.com', 'Mazatenango', 'PASAPORTE', 'Guatemala', '2026-06-22'),
('Marta', 'Ventura', '65678901-5', '7567-3388', 'mventura@hotmail.com', 'Gotera, Morazan', 'DUI', 'El Salvador', '2026-06-23'),
('Noe', 'Barahona', '66789012-6', '7678-2299', 'nbarahona@gmail.com', 'Jocoro', 'DUI', 'El Salvador', '2026-06-25'),
('Ofelia', 'Guzman', '67890123-7', '7789-1100', 'oguzman@outlook.com', 'La Union Centro', 'DUI', 'El Salvador', '2026-06-26'),
('Pedro', 'Chacon', '68901234-8', '7890-0011', 'pchacon@gmail.com', 'Conchagua', 'DUI', 'El Salvador', '2026-06-28');
GO

/* ------------------------------------------------------------
   5. EMPLEADOS
------------------------------------------------------------ */
SET IDENTITY_INSERT operaciones.empleado ON;
INSERT INTO operaciones.empleado (id_empleado, nombre, apellido, cargo, telefono, correo, estado_empleado, fecha_contratacion, turno, id_hotel) VALUES
(1, 'Marta',   'Diaz',     'Recepcionista',   '6666-0001', 'marta.diaz@playaverde.com',   'ACTIVO',     '2024-06-01', 'MANANA', 1),
(2, 'Luis',    'Perez',    'Recepcionista',   '6666-0002', 'luis.perez@playaverde.com',   'ACTIVO',     '2024-08-15', 'TARDE',  1),
(3, 'Jorge',   'Salazar',  'Cajero',          '6666-0003', 'jorge.salazar@playaverde.com','ACTIVO',     '2024-05-01', 'MANANA', 1),
(4, 'Carmen',  'Rios',     'Gerente',         '6666-0004', 'carmen.rios@playaverde.com',  'ACTIVO',     '2023-01-10', 'MANANA', 1),
(5, 'Andres',  'Molina',   'Recepcionista',   '6666-0005', 'andres.molina@montanaazul.com','ACTIVO',    '2024-09-01', 'NOCHE',  2),
(6, 'Paola',   'Vega',     'Cajero',          '6666-0006', 'paola.vega@montanaazul.com',  'VACACIONES', '2024-07-20', 'TARDE',  2),
(7, 'Raul',    'Campos',   'Botones',         '6666-0007', 'raul.campos@playaverde.com',  'INACTIVO',   '2024-03-11', 'NOCHE',  1);
SET IDENTITY_INSERT operaciones.empleado OFF;
GO

/* ------------------------------------------------------------
   6. HABITACIONES  (hotel 1: 101-110, hotel 2: 201-205)
------------------------------------------------------------ */
SET IDENTITY_INSERT catalogo.habitacion ON;
INSERT INTO catalogo.habitacion (id_habitacion, numero_habitacion, nivel, estado_habitacion, id_hotel, id_tipo_habitacion) VALUES
(1,  '101', 1, 'DISPONIBLE',  1, 1),
(2,  '102', 1, 'DISPONIBLE',  1, 2),
(3,  '103', 1, 'OCUPADA',     1, 2),
(4,  '104', 1, 'DISPONIBLE',  1, 3),
(5,  '105', 1, 'MANTENIMIENTO',1, 1),
(6,  '201', 2, 'DISPONIBLE',  1, 2),
(7,  '202', 2, 'DISPONIBLE',  1, 4),
(8,  '203', 2, 'LIMPIEZA',    1, 1),
(9,  '301', 3, 'DISPONIBLE',  1, 3),
(10, '302', 3, 'DISPONIBLE',  1, 2),
(11, '201', 2, 'DISPONIBLE',  2, 1),
(12, '202', 2, 'DISPONIBLE',  2, 2),
(13, '203', 2, 'OCUPADA',     2, 2),
(14, '204', 2, 'DISPONIBLE',  2, 4),
(15, '301', 3, 'DISPONIBLE',  2, 3);
SET IDENTITY_INSERT catalogo.habitacion OFF;
GO

/* ------------------------------------------------------------
   7. RESERVACIONES
   7.1 Reservaciones base (1-11): usadas por estancias
------------------------------------------------------------ */
SET IDENTITY_INSERT operaciones.reservacion ON;
INSERT INTO operaciones.reservacion (id_reservacion, fecha_reserva, fecha_entrada, fecha_salida, estado_reserva, canal_reserva, id_huesped, id_empleado, id_tipo_habitacion) VALUES
(1,  '2025-05-01', '2025-06-01', '2025-06-05', 'CONFIRMADA', 'WEB',       1, 1, 2),
(2,  '2025-05-03', '2025-06-02', '2025-06-04', 'CONFIRMADA', 'TELEFONO',  3, 1, 3),
(3,  '2025-05-10', '2025-06-03', '2025-06-06', 'CONFIRMADA', 'RECEPCION', 5, 2, 1),
(4,  '2025-06-01', '2025-06-10', '2025-06-12', 'CONFIRMADA', 'WEB',       2, 2, 4),
(5,  '2025-06-05', '2025-06-15', '2025-06-18', 'PENDIENTE',  'AGENCIA',   7, 1, 2),
(6,  '2025-06-08', '2025-07-01', '2025-07-07', 'CONFIRMADA', 'WEB',       4, 1, 3),
(7,  '2025-06-10', '2025-07-05', '2025-07-08', 'CANCELADA',  'WEB',       6, 2, 1),
(8,  '2025-06-12', '2025-07-10', '2025-07-15', 'CONFIRMADA', 'TELEFONO',  8, 5, 2),
(9,  '2025-06-15', '2025-07-20', '2025-07-25', 'CONFIRMADA', 'AGENCIA',   9, 1, 4),
(10, '2025-07-01', '2025-08-01', '2025-08-05', 'CONFIRMADA', 'WEB',      10, 2, 3),
(11, '2025-07-05', '2025-08-10', '2025-08-14', 'PENDIENTE',  'RECEPCION', 1, 1, 2);
SET IDENTITY_INSERT operaciones.reservacion OFF;
GO

/* ------------------------------------------------------------
   7.2 Reservaciones adicionales (100 registros -> ids 12 a 111)
   Una por cada huesped adicional (ids > 10). Las fechas se
   calculan a partir de fecha_registro del huesped, asi la
   reserva nunca es anterior a su registro y el script da
   siempre el mismo resultado (no depende de GETDATE()).
   Empleados usados: 1, 2 y 5 (recepcionistas activos).
------------------------------------------------------------ */
INSERT INTO operaciones.reservacion (fecha_reserva, fecha_entrada, fecha_salida, estado_reserva, canal_reserva, id_huesped, id_empleado, id_tipo_habitacion)
SELECT
    DATEADD(DAY, 3 + (h.id_huesped % 7), h.fecha_registro)                                            AS fecha_reserva,
    DATEADD(DAY, 20 + (h.id_huesped % 15), h.fecha_registro)                                          AS fecha_entrada,
    DATEADD(DAY, 20 + (h.id_huesped % 15) + 2 + (h.id_huesped % 4), h.fecha_registro)                 AS fecha_salida,
    CASE h.id_huesped % 3
        WHEN 0 THEN 'CONFIRMADA'
        WHEN 1 THEN 'PENDIENTE'
        ELSE        'CANCELADA'
    END                                                                                               AS estado_reserva,
    CASE h.id_huesped % 4
        WHEN 0 THEN 'WEB'
        WHEN 1 THEN 'RECEPCION'
        WHEN 2 THEN 'TELEFONO'
        ELSE        'AGENCIA'
    END                                                                                               AS canal_reserva,
    h.id_huesped,
    CHOOSE((h.id_huesped % 3) + 1, 1, 2, 5)                                                           AS id_empleado,
    (h.id_huesped % 4) + 1                                                                            AS id_tipo_habitacion
FROM operaciones.huesped h
WHERE h.id_huesped > 10
ORDER BY h.id_huesped;
GO

/* ------------------------------------------------------------
   8. ESTANCIAS (varias finalizadas, 1 activa para el demo)
   Las fechas estan en el pasado para que fn_calcular_noches funcione
------------------------------------------------------------ */

SET IDENTITY_INSERT operaciones.estancia ON;
INSERT INTO operaciones.estancia
    (id_estancia, fecha_checkin, fecha_checkout,
     estado_estancia, id_reservacion,
     id_habitacion, id_empleado_checkin)
VALUES
(1, '2025-06-01 14:00', '2025-06-05 11:00', 'FINALIZADA', 1101, 2, 1),
(2, '2025-06-02 15:00', '2025-06-04 12:00', 'FINALIZADA', 1102, 4, 1),
(3, '2025-06-03 13:00', '2025-06-06 10:00', 'FINALIZADA', 1103, 1, 2),
(4, '2025-06-10 14:00', '2025-06-12 11:00', 'FINALIZADA', 1104, 7, 2),
(5, '2025-07-01 15:00', '2025-07-07 12:00', 'FINALIZADA', 1106, 9, 1),
(6, '2025-07-10 14:00', '2025-07-15 11:00', 'FINALIZADA', 1108, 6, 5),
(7, '2025-07-20 13:00', '2025-07-25 10:00', 'FINALIZADA', 1109, 10, 1),
(8, '2025-08-01 14:00', '2025-08-05 12:00', 'FINALIZADA', 1110, 4, 2),
(9, '2025-09-01 14:00', NULL, 'ACTIVA', 1105, 13, 5);
SET IDENTITY_INSERT operaciones.estancia OFF;
GO

/* El trigger de checkout puso habitaciones en LIMPIEZA al finalizar;
   las devolvemos a DISPONIBLE para que el estado actual sea coherente */
UPDATE catalogo.habitacion SET estado_habitacion = 'DISPONIBLE'
WHERE id_habitacion IN (2,4,1,7,9,6,10);
UPDATE catalogo.habitacion SET estado_habitacion = 'OCUPADA' WHERE id_habitacion = 13;
GO

/* ------------------------------------------------------------
   9. ACOMPANANTES
------------------------------------------------------------ */
SET IDENTITY_INSERT operaciones.acompanante ON;
INSERT INTO operaciones.acompanante (id_acompanante, es_titular, id_estancia, id_huesped) VALUES
(1, 1, 1, 1),
(2, 0, 1, 2),
(3, 1, 2, 3),
(4, 1, 3, 5),
(5, 1, 4, 2),
(6, 0, 4, 6),
(7, 1, 5, 4),
(8, 0, 5, 8),
(9, 1, 6, 8),
(10, 1, 7, 9),
(11, 1, 8, 10),
(12, 1, 9, 7);
SET IDENTITY_INSERT operaciones.acompanante OFF;
GO

/* ------------------------------------------------------------
   10. CONSUMOS DE SERVICIO
   (subtotal = cantidad * precio; el trigger lo valida de todos modos)
------------------------------------------------------------ */
SET IDENTITY_INSERT operaciones.consumo_servicio ON;
INSERT INTO operaciones.consumo_servicio (id_consumo, fecha_consumo, cantidad, subtotal, id_estancia, id_servicio, id_empleado) VALUES
(1,  '2025-06-01 08:00', 2, 17.00,  1, 1, 1),
(2,  '2025-06-02 20:00', 1, 15.00,  1, 2, 1),
(3,  '2025-06-03 19:30', 1, 35.00,  1, 5, 2),
(4,  '2025-06-02 09:00', 2, 17.00,  2, 1, 1),
(5,  '2025-06-03 12:00', 1, 5.00,   2, 3, 1),
(6,  '2025-06-04 08:00', 1, 8.50,   3, 1, 2),
(7,  '2025-06-10 21:00', 3, 45.00,  4, 6, 2),
(8,  '2025-06-11 13:00', 1, 25.00,  4, 4, 2),
(9,  '2025-07-02 08:00', 2, 17.00,  5, 1, 1),
(10, '2025-07-04 20:00', 1, 15.00,  5, 2, 3),
(11, '2025-07-11 10:00', 1, 25.00,  6, 4, 5),
(12, '2025-07-13 15:00', 2, 70.00,  6, 5, 5),
(13, '2025-07-21 08:00', 4, 34.00,  7, 1, 1),
(14, '2025-08-02 09:00', 2, 17.00,  8, 1, 2),
(15, '2025-08-03 18:00', 1, 15.00,  8, 2, 2);
SET IDENTITY_INSERT operaciones.consumo_servicio OFF;
GO

/* ------------------------------------------------------------
   11. FACTURAS (calculadas a mano: subtotal+servicios-desc, IVA 13%)
------------------------------------------------------------ */
SET IDENTITY_INSERT finanzas.factura ON;
INSERT INTO finanzas.factura (id_factura, fecha_emision, subtotal, impuestos, descuento, total, estado_factura, fecha_pago, tipo_pago, metodo_pago, id_empleado, id_estancia) VALUES
(1, '2025-06-05 11:30', 317.00, 41.21, 0,   358.21, 'PAGADO',    '2025-06-05 11:30', 'TARJETA',       'CONTADO', 3, 1),
(2, '2025-06-04 12:10', 320.00, 41.60, 0,   361.60, 'PAGADO',    '2025-06-04 12:10', 'EFECTIVO',      'CONTADO', 3, 2),
(3, '2025-06-06 10:20', 153.50, 19.96, 0,   173.46, 'PAGADO',    '2025-06-06 10:20', 'TARJETA',       'CONTADO', 3, 3),
(4, '2025-06-12 11:15', 325.00, 42.25, 25,  342.25, 'PAGADO',    '2025-06-12 11:15', 'TARJETA',       'CONTADO', 3, 4),
(5, '2025-07-07 12:05', 932.50, 121.23, 0,  1053.73,'PAGADO',    '2025-07-07 12:05', 'TRANSFERENCIA', 'CONTADO', 3, 5),
(6, '2025-07-15 11:00', 465.00, 60.45, 0,   525.45, 'PAGADO',    '2025-07-15 11:00', 'TARJETA',       'CONTADO', 3, 6),
(7, '2025-07-25 10:30', 634.00, 82.42, 0,   716.42, 'PENDIENTE', NULL,               'TRANSFERENCIA', 'CREDITO', 3, 7),
(8, '2025-08-05 12:20', 632.50, 82.23, 0,   714.73, 'PAGADO',    '2025-08-05 12:20', 'TARJETA',       'CONTADO', 3, 8);
SET IDENTITY_INSERT finanzas.factura OFF;
GO

/* ------------------------------------------------------------
   12. DETALLE DE FACTURAS
------------------------------------------------------------ */
SET IDENTITY_INSERT finanzas.detalle_factura ON;
INSERT INTO finanzas.detalle_factura (id_detalle_factura, tipo_detalle, concepto, cantidad, precio_unitario, subtotal, id_factura, id_consumo) VALUES
-- Factura 1: estancia 1 (Doble, 4 noches * 75 = 300) + 3 consumos (17+15+35=67)
(1,  'HABITACION', 'Alojamiento - Doble (4 noche(s))',   4, 75.00, 300.00, 1, NULL),
(2,  'SERVICIO',   'Desayuno buffet',                    2, 8.50,   17.00,  1, 1),
(3,  'SERVICIO',   'Cena restaurante',                   1, 15.00,  15.00,  1, 2),
(4,  'SERVICIO',   'Spa y masajes',                        1, 35.00,  35.00,  1, 3),
-- Factura 2: estancia 2 (Suite, 2 noches * 150 = 300) + 2 consumos (17+5=22)... 
-- ajuste: 300 habitacion + 22 servicios - 0 = 322 -> usamos los calculos reales
(5,  'HABITACION', 'Alojamiento - Suite (2 noche(s))',     2, 150.00,300.00, 2, NULL),
(6,  'SERVICIO',   'Desayuno buffet',                    2, 8.50,   17.00,  2, 4),
(7,  'SERVICIO',   'Lavanderia',                           1, 5.00,    5.00,  2, 5),
-- Factura 3: estancia 3 (Sencilla, 3 noches * 45 = 135) + 8.50
(8,  'HABITACION', 'Alojamiento - Sencilla (3 noche(s))',  3, 45.00, 135.00, 3, NULL),
(9,  'SERVICIO',   'Desayuno buffet',                      1, 8.50,    8.50, 3, 6),
-- Factura 4: estancia 4 (Familiar, 2 noches * 120 = 240) + 70 servicios - desc 25 = 285
(10, 'HABITACION', 'Alojamiento - Familiar (2 noche(s))',  2, 120.00,240.00, 4, NULL),
(11, 'SERVICIO',   'Room service',                         3, 3.00,    9.00, 4, 7),
(12, 'SERVICIO',   'Transporte aeropuerto',                1, 25.00,  25.00, 4, 8),
-- Factura 5: estancia 5 (Suite, 6 noches * 150 = 900) + 32 servicios = 932.50
(13, 'HABITACION', 'Alojamiento - Suite (6 noche(s))',     6, 150.00,900.00, 5, NULL),
(14, 'SERVICIO',   'Desayuno buffet',                      2, 8.50,   17.00,  5, 9),
(15, 'SERVICIO',   'Cena restaurante',                     1, 15.00,  15.00, 5, 10),
-- Factura 6: estancia 6 (Doble, 5 noches * 75 = 375) + 95 servicios = 470
(16, 'HABITACION', 'Alojamiento - Doble (5 noche(s))',     5, 75.00, 375.00, 6, NULL),
(17, 'SERVICIO',   'Transporte aeropuerto',                1, 25.00,  25.00, 6, 11),
(18, 'SERVICIO',   'Spa y masajes',                        2, 35.00,  70.00, 6, 12),
-- Factura 7: estancia 7 (Doble, 5 noches * 120... Familiar 5 noches * 120 = 600) + 34 = 634
(19, 'HABITACION', 'Alojamiento - Familiar (5 noche(s))',  5, 120.00,600.00, 7, NULL),
(20, 'SERVICIO',   'Desayuno buffet',                      4, 8.50,   34.00,  7, 13),
-- Factura 8: estancia 8 (Suite, 4 noches * 150 = 600) + 32 = 632.50
(21, 'HABITACION', 'Alojamiento - Suite (4 noche(s))',     4, 150.00,600.00, 8, NULL),
(22, 'SERVICIO',   'Desayuno buffet',                      2, 8.50,   17.00,  8, 14),
(23, 'SERVICIO',   'Cena restaurante',                     1, 15.00,  15.00, 8, 15);
SET IDENTITY_INSERT finanzas.detalle_factura OFF;
GO

/* ------------------------------------------------------------
   VERIFICACION RAPIDA
   Esperado: huesped = 110, reservacion = 111
------------------------------------------------------------ */
SELECT 'hotel' AS tabla, COUNT(*) AS filas FROM catalogo.hotel
UNION ALL SELECT 'tipo_habitacion', COUNT(*) FROM catalogo.tipo_habitacion
UNION ALL SELECT 'servicio', COUNT(*) FROM catalogo.servicio
UNION ALL SELECT 'huesped', COUNT(*) FROM operaciones.huesped
UNION ALL SELECT 'empleado', COUNT(*) FROM operaciones.empleado
UNION ALL SELECT 'habitacion', COUNT(*) FROM catalogo.habitacion
UNION ALL SELECT 'reservacion', COUNT(*) FROM operaciones.reservacion
UNION ALL SELECT 'estancia', COUNT(*) FROM operaciones.estancia
UNION ALL SELECT 'acompanante', COUNT(*) FROM operaciones.acompanante
UNION ALL SELECT 'consumo_servicio', COUNT(*) FROM operaciones.consumo_servicio
UNION ALL SELECT 'factura', COUNT(*) FROM finanzas.factura
UNION ALL SELECT 'detalle_factura', COUNT(*) FROM finanzas.detalle_factura;
GO
