DECLARE @BRPS BIGINT
SELECT @BRPS=cntr_value 
FROM sys.dm_os_performance_counters
WHERE counter_name LIKE 'Batch Requests/sec%'
WAITFOR DELAY '000:00:10'
SELECT (cntr_value-@BRPS)/10.0 AS "Batch Requests/sec"
FROM sys.dm_os_performance_counters
WHERE counter_name LIKE 'Batch Requests/sec%'