# Dashboard de Power BI

Dashboard basado en las 3 consultas de `database/04_views.sql`. El proyecto se preparó en Linux y **todavía no se ha abierto en Power BI Desktop**: falta probarlo en Windows y generar el `.pbix`.

## Qué necesitas

- Windows con SQL Server y SSMS.
- Power BI Desktop actualizado.
- La rama `feature/powerbi-dashboard` de este repositorio.

## 1. Cargar la base en SQL Server

Ejecuta estos scripts en SSMS, en este orden:

1. `database/01_create_database.sql`
2. `database/02_tables.sql`: **antes de ejecutarlo, elige `bd_hotel_grupoAC` en el selector de base de datos.** El script no tiene `USE` y, si no, crea las tablas en `master`.
3. `database/03_schemas.sql`
4. `database/04_views.sql`
5. `database/05_procedures.sql`
6. `database/06_triggers.sql`
7. `database/11_sample_data.sql`

El paso 7 da un error de FOREIGN KEY `fk_estancia_reserva`, y las tablas de estancias y facturas quedan vacías. Es un problema conocido de los datos y **no afecta a este dashboard**. Comprueba que `operaciones.reservacion` tenga 111 filas y `operaciones.huesped` 110.

## 2. Abrir el proyecto

1. Abre `powerbi/HotelGrupoAC.pbip` con doble clic.
2. Si Power BI no lo abre, activa en *Archivo > Opciones > Características en versión preliminar* las opciones de proyecto de Power BI (`.pbip`), TMDL y PBIR. Reinicia Power BI.
3. En *Transformar datos > Editar parámetros*, deja `BaseDatos` como está y pon en `ServidorSQL` tu servidor (`localhost` o, por ejemplo, `.\SQLEXPRESS`).
4. Conéctate con **credenciales de Windows**. Si avisa de que la conexión no está cifrada, acepta.
5. Pulsa **Actualizar**.

## 3. Comprobar los valores

Sin ningún filtro aplicado, el dashboard debe mostrar:

| Indicador | Valor |
|---|---|
| Reservas totales | 111 |
| Tasa de confirmación | 36,9 % (41 de 111) |
| Tasa de cancelación | 31,5 % (35 de 111) |
| Huéspedes | 110 |
| Nacionalidades | 10 |

| Consulta 1: tipo | Reservas |
|---|---|
| Doble | 29 |
| Suite | 28 |
| Familiar | 27 |
| Sencilla | 27 |

| Consulta 2: canal | Confirmadas | Pendientes | Canceladas |
|---|---|---|---|
| WEB | 13 | 8 | 9 |
| TELEFONO | 10 | 8 | 9 |
| AGENCIA | 9 | 9 | 9 |
| RECEPCION | 9 | 10 | 8 |

| Consulta 3: posición | Nacionalidad | Huéspedes |
|---|---|---|
| 1 | El Salvador | 74 |
| 2 | Guatemala, México | 8 cada una |
| 3 | Costa Rica, Honduras | 6 cada una |
| 4 | Colombia, España, Estados Unidos | 2 cada una |
| 5 | Canadá, Italia | 1 cada una |

Revisa también que cada filtro cambie su gráfico y que los tres textos de "Lectura" se lean completos.

## 4. Entregar

1. Guarda con *Archivo > Guardar como* en formato `.pbix`: `powerbi/HotelGrupoAC.pbix`.
2. Toma una captura de la página completa con los valores, y otra con un filtro aplicado.
3. Envía el `.pbix`, las capturas y cualquier error que haya salido, con su texto exacto.

## Si el proyecto no abre

Copia el mensaje de error completo. Si no se resuelve, el dashboard se puede montar a mano en un `.pbix` nuevo:

1. *Obtener datos > SQL Server*, modo **Importar**, base `bd_hotel_grupoAC`.
2. Carga las 3 vistas de `operaciones` y renómbralas `TipoHabitacion`, `CanalEstado` y `Nacionalidad`.
3. Crea las medidas: están escritas en `HotelGrupoAC.SemanticModel/definition/tables/`.
4. Monta los elementos en este orden:
   - Título.
   - 5 tarjetas con los indicadores de la tabla anterior.
   - 3 filtros desplegables: tipo, canal y nacionalidad.
   - Barras de la consulta 1, columnas apiladas de la consulta 2 y tabla de ranking de la consulta 3.
   - Una tarjeta con la medida `Narrativa ...` bajo cada visual.

## Limitación del modelo

Las 3 vistas no comparten ninguna columna, así que no hay relaciones entre ellas. Cada filtro afecta solo a su propia consulta y a las tarjetas que dependen de ella. Tampoco hay filtro por fecha, porque las vistas no incluyen fechas.
