# Backups del Hotel Grupo AC (SQL Server)

Base: `bd_hotel_grupoAC` · Carpeta: `backups/` del repositorio.  
Este plan es una **propuesta propia del equipo**, no una copia de los horarios de la diapositiva.

## 1. Estrategia para explicar en defensa

| Tipo | Cuándo se hace | ¿Para qué? | Conservación propuesta |
|---|---|---|---|
| **Full** | Domingo 2:00 a. m. | Copia completa y base para recuperar | 4 semanas |
| **Diferencial** | Lunes a sábado 2:00 a. m. | Guarda cambios desde el último Full | 7 días |
| **Log** | Todos los días, :15 y :45 | Permite recuperar transacciones recientes | 7 días |

- **Modelo de recuperación:** `FULL` (el primer script lo configura).
- **RPO propuesto:** máximo 30 minutos de transacciones perdidas **si los respaldos de log funcionan**. En fallas de almacenamiento hay que comprobar qué backups sobrevivieron.
- **RTO propuesto:** hasta 60 minutos para restaurar y abrir la base. **Es un objetivo, no un resultado demostrado**; se mide en la prueba.
- **Ubicación principal:** carpeta predeterminada de respaldos del servicio SQL Server (visible al imprimir `OK - Backup ...`). Como protección ante daños del servidor, conservar una copia adicional fuera del equipo, con acceso restringido. **Esta copia externa no se automatiza con los scripts.**
- **Retención:** los valores de la tabla son política propuesta; los scripts **no borran automáticamente archivos**. Conservar las cadenas necesarias (Full + diferencial + todos los logs correspondientes).
- **Verificación:** cada script usa `CHECKSUM` y `RESTORE VERIFYONLY`. La evidencia más sólida es la **restauración real de prueba**.

## 2. Archivos y orden de uso

| Archivo | Uso |
|---|---|
| `full_backup.sql` | Primer respaldo, activa FULL recovery. |
| `differential_backup.sql` | Respaldo de cambios desde el Full. |
| `transaction_log_backup.sql` | Respaldo de transacciones recientes. |
| `restore_database.sql` | Restaura **a `bd_hotel_grupoAC_prueba`**, nunca encima de la original. |
| `jobs_backup.sql` | Crea los 3 jobs y sus calendarios en SQL Server Agent. |
| `verificar_jobs.sql` | Muestra los jobs y su último resultado. |

## 3. Demostración corta y fácil de repetir (hacer ANTES de activar los jobs)

Se necesitan **SQL Server Developer (o una edición con Agent)** y permisos de administración. Primero comprobar que existe `bd_hotel_grupoAC` y que el servicio SQL Server puede escribir en su carpeta de backups.

**Paso A — Crear datos de prueba** en una ventana de SSMS:

```sql
USE bd_hotel_grupoAC;
GO
IF OBJECT_ID(N'dbo.demo_backup_AC', N'U') IS NULL
    CREATE TABLE dbo.demo_backup_AC (
        id INT IDENTITY(1,1) PRIMARY KEY,
        etapa VARCHAR(30) NOT NULL,
        fecha DATETIME2 NOT NULL DEFAULT SYSDATETIME()
    );
GO
INSERT INTO dbo.demo_backup_AC (etapa) VALUES ('Antes del Full');
GO
```

**Paso B — FULL:** ejecutar todo `full_backup.sql` y guardar la ruta que aparece en **Messages**.

**Paso C — Cambio y DIFF:**

```sql
USE bd_hotel_grupoAC;
INSERT INTO dbo.demo_backup_AC (etapa) VALUES ('Antes del diferencial');
```

Ejecutar `differential_backup.sql` y guardar la ruta `.bak` mostrada.

**Paso D — Cambio y LOG:**

```sql
USE bd_hotel_grupoAC;
INSERT INTO dbo.demo_backup_AC (etapa) VALUES ('Antes del log');
```

Ejecutar `transaction_log_backup.sql` y guardar la ruta `.trn` mostrada.

**Paso E — Restaurar:** abrir `restore_database.sql`, reemplazar `@full`, `@diff` y `@log` por las **tres rutas reales**, ejecutar el archivo completo. Debe crear `bd_hotel_grupoAC_prueba` y mostrar las tres filas de `dbo.demo_backup_AC`.

> Importante: esta demostración supone **un único archivo de log necesario después del diferencial**. Si otros jobs de log se ejecutaron entre los pasos C y D, para una restauración real hay que aplicar **todos los logs necesarios en orden** antes de `WITH RECOVERY`. No basta con restaurar el último `.trn`. No usar este guion corto como procedimiento universal de recuperación.

La restauración se detiene si ya existe `bd_hotel_grupoAC_prueba`. **No ejecutar `DROP DATABASE` sobre la base original.**

## 4. Crear y enseñar los jobs

1. Cuando ya funcionen los respaldos manuales, ejecutar `jobs_backup.sql` **una sola vez** en SSMS con permisos de administrador. El servicio **SQL Server Agent** debe estar iniciado.
2. En el Explorador de objetos: **SQL Server Agent > Jobs**. Mostrar `AC_Backup_FULL`, `AC_Backup_DIFF` y `AC_Backup_LOG`.
3. Abrir cada job: **Properties > Steps / Schedules** para mostrar qué hace y su horario.
4. Para demostrar ejecución inmediata, clic derecho sobre el job > **Start Job at Step...**. Primero Full, luego Diff, luego Log, comprobando que finaliza cada uno.
5. Clic derecho sobre el job > **View History** (o ejecutar `verificar_jobs.sql`). Mostrar último resultado y la ruta creada en **Messages / historial**. Comprobar que el archivo existe en la carpeta del servidor.
6. Si falla: revisar **View History**, permisos de escritura de la carpeta, espacio en disco y que la base exista. Arreglar la causa y volver a ejecutar el job. **No hay alertas por correo configuradas**; estas se podrían añadir con Database Mail.

Los jobs no realizan respaldos si el equipo/servicio SQL Server Agent está apagado. Para la defensa, usar **Start Job at Step...** permite probarlos sin esperar el horario.

## 5. Escenario de recuperación para explicar RPO / RTO

**Ejemplo del equipo** (no son horas copiadas de la plantilla): jueves, el sistema falla a las **2:10 p. m.**; Full del domingo 02:00, diferencial del jueves 02:00 y último log completo del jueves 1:45 p. m. Si la cadena está íntegra, se recupera al menos hasta **1:45 p. m.**, por lo que en este caso podrían perderse **25 minutos** de transacciones. El objetivo general sigue siendo **RPO de 30 min**.

**Orden correcto de restauración:** Full con `NORECOVERY` → última diferencial compatible con `NORECOVERY` → **todos los backups de log requeridos, en orden cronológico** con `NORECOVERY` → `WITH RECOVERY`. Si todavía está accesible el archivo de log dañado parcialmente o el log activo, podría intentarse un **tail-log backup** para disminuir la pérdida; depende del tipo de falla y no está implementado en esta demostración.

**RTO:** el objetivo es **60 min**. `restore_database.sql` reporta los segundos reales que tarda la restauración técnica. Hay que registrar la medición y verificar consultas antes de afirmar que se cumplió el RTO del servicio.

## 6. Evidencias para el informe / defensa

Capturas de: (1) tabla de estrategia, (2) jobs y horarios, (3) historial con estado **Correcto**, (4) archivos `.bak` / `.trn`, (5) resultados de la restauración en `bd_hotel_grupoAC_prueba` y (6) duración observada. **No subir `.bak` con datos de huéspedes a un GitHub público.**

**Limpieza opcional después de la defensa:** puede eliminarse `dbo.demo_backup_AC` en la base original y, separadamente, la base `bd_hotel_grupoAC_prueba` cuando ya se guardó la evidencia. Nunca ejecutar estos borrados automáticamente desde los scripts.
