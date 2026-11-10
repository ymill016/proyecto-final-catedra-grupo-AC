/* ============================================================
   EVIDENCIA PARA DEFENSA - ESTADO Y EJECUCION DE JOBS
   Mostrar los 3 jobs, sus horarios y el ultimo resultado.
   ============================================================ */
USE msdb;
GO
SELECT
    j.name AS job,
    CASE WHEN j.enabled = 1 THEN 'Habilitado' ELSE 'Deshabilitado' END AS estado,
    s.name AS calendario,
    CASE WHEN h.run_status = 1 THEN 'Correcto'
         WHEN h.run_status = 0 THEN 'Fallido'
         WHEN h.run_status IS NULL THEN 'Aun no ejecutado'
         ELSE 'Revisar historial' END AS ultimo_resultado,
    h.run_date AS fecha_yyyymmdd,
    h.run_time AS hora_hhmmss,
    h.message AS detalle
FROM msdb.dbo.sysjobs AS j
LEFT JOIN msdb.dbo.sysjobschedules AS js ON js.job_id = j.job_id
LEFT JOIN msdb.dbo.sysschedules AS s ON s.schedule_id = js.schedule_id
OUTER APPLY (
    SELECT TOP (1) h.run_status, h.run_date, h.run_time, h.message
    FROM msdb.dbo.sysjobhistory AS h
    WHERE h.job_id = j.job_id AND h.step_id = 0
    ORDER BY h.instance_id DESC
) AS h
WHERE j.name IN (N'AC_Backup_FULL', N'AC_Backup_DIFF', N'AC_Backup_LOG')
ORDER BY j.name;
GO
