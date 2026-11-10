# Plan de respaldo y recuperación — bd_hotel_grupoAC

Scripts en `backups/` · Evidencia en `backups/evidencia/` · Prueba realizada el 10/11/2026 en SQL Server 2025 Developer (contenedor Linux, SQL Server Agent activo).

## 1. Objetivos de recuperación

| Objetivo | Valor | Por qué |
|---|---|---|
| **RPO** (cuántos datos se pueden perder) | **30 minutos** | Reservas, check-in y facturas cambian durante todo el día. Perder más de media hora obligaría a recapturar operaciones de recepción y caja. |
| **RTO** (cuánto puede tardar en volver) | **60 minutos** | El hotel puede trabajar en papel un rato, pero no un turno completo. |

El RPO lo marca la frecuencia del backup de log y el RTO lo marca la cantidad de archivos que hay que restaurar. Por eso el plan combina tres tipos de respaldo.

## 2. Estrategia y calendario

| Tipo | Frecuencia | Job | Para qué sirve | Retención propuesta |
|---|---|---|---|---|
| **Full** | Domingo 02:00 | `AC_Backup_FULL` | Copia completa; inicio de la cadena | 4 semanas |
| **Diferencial** | Lunes a sábado 02:00 | `AC_Backup_DIFF` | Cambios desde el último Full; evita restaurar una semana entera de logs | 7 días |
| **Log** | Cada 30 min (:15 y :45), todos los días | `AC_Backup_LOG` | Transacciones recientes; **es lo que cumple el RPO** | 7 días |

- **Modelo de recuperación FULL.** Sin él no existen backups de log. `full_backup.sql` lo activa si hace falta.
- **Horarios a las 02:00.** Es la hora de menor actividad del hotel. Los logs a :15 y :45 no coinciden con el Full ni con el diferencial.
- **Verificación.** Cada respaldo se crea con `CHECKSUM` y se comprueba con `RESTORE VERIFYONLY`.
- **Un archivo por ejecución.** El nombre lleva fecha y hora (`bd_hotel_grupoAC_FULL_AAAAMMDD_HHMMSS.bak`), así nunca se sobrescribe un respaldo anterior.

### Relación con el RTO

En el peor caso, una falla justo antes de las 02:00, hay que restaurar:

- el Full del domingo,
- el diferencial del día anterior,
- hasta 48 backups de log de ese día.

Sin diferenciales serían hasta 7 días de logs, unos 336 archivos, y el RTO correría peligro. En la prueba, la restauración técnica de Full, diferencial y log **tardó 1 segundo**. La base es pequeña (5,46 MB), así que el margen frente a los 60 minutos es amplio y el tiempo lo dominan los pasos humanos: localizar archivos, ejecutar y validar.

## 3. Procedimiento de recuperación

1. Si el log todavía está accesible, hacer un **tail-log backup** para no perder lo último. Esto depende del tipo de falla y no está automatizado.
2. Restaurar el **Full** más reciente con `NORECOVERY`.
3. Restaurar el **último diferencial** posterior a ese Full con `NORECOVERY`.
4. Restaurar **todos los logs** posteriores al diferencial, en orden cronológico, con `NORECOVERY`.
5. Abrir la base con `RESTORE DATABASE ... WITH RECOVERY`.
6. Validar con conteos y con las consultas del sistema antes de devolver el servicio.

`restore_database.sql` aplica este orden sobre una base nueva, `bd_hotel_grupoAC_prueba`, y **nunca sobrescribe la original**.

**Escenario de ejemplo.** El jueves la base falla a las 14:10. Se restauran el Full del domingo, el diferencial del jueves a las 02:00 y los logs desde las 02:15 hasta las 13:45. Se recupera hasta las 13:45, así que se pierden 25 minutos, dentro del RPO de 30.

## 4. Evidencia de ejecución

| Prueba | Resultado | Archivo |
|---|---|---|
| Backups manuales Full, diferencial y log | 3 respaldos creados y verificados ("The backup set on file 1 is valid") | `01_backups_manuales.txt` |
| Restauración en `bd_hotel_grupoAC_prueba` | ONLINE en **1 s**; recuperó las 3 filas de control (una antes de cada respaldo) y los conteos coinciden con la original: 111 reservas y 110 huéspedes | `02_restauracion_prueba.txt` |
| Creación y ejecución de los jobs | Los 3 jobs creados con su calendario y ejecutados con `sp_start_job` | `03_creacion_y_ejecucion_jobs.txt` |
| Historial de SQL Agent y `msdb` | `AC_Backup_FULL`, `AC_Backup_DIFF` y `AC_Backup_LOG` en estado **Correcto**; 6 respaldos registrados en `msdb.dbo.backupset`, todos con checksum | `04_verificacion_jobs_y_msdb.txt` |
| Estado final | Los 3 jobs quedaron **deshabilitados**, no borrados, para no llenar el disco del equipo de pruebas | `05_jobs_deshabilitados.txt` |
| Comprobación independiente (`backups/comprobar_plan.sql`, solo lectura) | Cadena de LSN sin huecos; últimos Full, diferencial y log legibles; `DBCC CHECKDB` sin errores en la base restaurada | `06_comprobacion_plan.txt` |

La tabla `dbo.demo_backup_AC` registra una fila antes de cada respaldo: "Antes del Full", "Antes del diferencial" y "Antes del log". Que las tres aparezcan en la base restaurada demuestra que se aplicó la cadena completa.

**Capturas para el informe, tomadas en SSMS:**

1. *SQL Server Agent > Jobs* con los 3 jobs.
2. *Properties > Schedules* de cada job.
3. *View History* con estado Correcto.
4. El resultado de `verificar_jobs.sql`.
5. La base `bd_hotel_grupoAC_prueba` con la tabla de control.

## 5. Limitaciones y mejoras

- **Copia externa.** Los respaldos quedan en el mismo servidor (`/var/opt/mssql/data`). En producción habría que copiarlos a otro equipo o a la nube, porque un daño del disco los perdería junto con la base.
- **Retención.** La retención es una política: los scripts no borran archivos viejos. Se podría automatizar con un *Maintenance Cleanup Task* o un job adicional.
- **Alertas.** No hay alertas de fallo. Se podrían añadir con Database Mail y operadores de SQL Agent.
- **Zona horaria.** En el contenedor de prueba la hora del servidor es **UTC**, y SQL Agent programa con esa hora. Ahí las "02:00" equivalen a las 20:00 de El Salvador. En un servidor Windows con hora local, los horarios se aplican tal como están escritos.
- **Seguridad.** Los `.bak` y `.trn` contienen datos de huéspedes. El `.gitignore` impide subirlos al repositorio público.
