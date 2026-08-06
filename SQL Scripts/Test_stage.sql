USE ROLE NR_DATA_ENGINEER;
USE DATABASE NORTHERN_RIDGE_DB;
USE SCHEMA BRONZE;

LIST @STG_LANDING_ZONE;

--Monitor tasks from last 2 hours
SELECT
    name,
    state,
    completed_time,
    error_message
FROM TABLE(INFORMATION_SCHEMA.TASK_HISTORY(
    task_name => 'TSK_AUTO_INGEST_BRONZE',
    scheduled_time_range_start => DATEADD('hour', -2, CURRENT_TIMESTAMP())
))
ORDER BY completed_time DESC;