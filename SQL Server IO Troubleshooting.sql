-- From the Tegile Systems webinar "How to Reduce Latency and Boost Your SQL Server Performance" 
--	Featuring Sumeet Bansal, @SumeetBansal_ , Sumeet@tegile.com and Kevin Kline, @kekline, kkline@sqlsentry.com
--
-- I/O Performance Analysis T-SQL script library.


-- STEP 1 - What is making the users wait on our SQL Server? Is I/O even one of the reasons?
--
-- Original author - Paul Randal, @PaulRandal, http://www.sqlskills.com/blogs/paul/wait-statistics-or-please-tell-me-where-it-hurts/
WITH [Waits] AS
    (SELECT
        [wait_type], [wait_time_ms] / 1000.0 AS [WaitS],
        ([wait_time_ms] - [signal_wait_time_ms]) / 1000.0 AS [ResourceS],
        [signal_wait_time_ms] / 1000.0 AS [SignalS],
        [waiting_tasks_count] AS [WaitCount],
        100.0 * [wait_time_ms] / SUM ([wait_time_ms]) OVER() AS [Percentage],
        ROW_NUMBER() OVER(ORDER BY [wait_time_ms] DESC) AS [RowNum]
    FROM sys.dm_os_wait_stats
    WHERE [wait_type] NOT IN (
        N'BROKER_EVENTHANDLER',             N'BROKER_RECEIVE_WAITFOR',
        N'BROKER_TASK_STOP',                N'BROKER_TO_FLUSH',
        N'BROKER_TRANSMITTER',              N'CHECKPOINT_QUEUE',
        N'CHKPT',                           N'CLR_AUTO_EVENT',
        N'CLR_MANUAL_EVENT',                N'CLR_SEMAPHORE',
        N'DBMIRROR_DBM_EVENT',              N'DBMIRROR_EVENTS_QUEUE',
        N'DBMIRROR_WORKER_QUEUE',           N'DBMIRRORING_CMD',
        N'DIRTY_PAGE_POLL',                 N'DISPATCHER_QUEUE_SEMAPHORE',
        N'EXECSYNC',                        N'FSAGENT',
        N'FT_IFTS_SCHEDULER_IDLE_WAIT',     N'FT_IFTSHC_MUTEX',
        N'HADR_CLUSAPI_CALL',               N'HADR_FILESTREAM_IOMGR_IOCOMPLETION',
        N'HADR_LOGCAPTURE_WAIT',            N'HADR_NOTIFICATION_DEQUEUE',
        N'HADR_TIMER_TASK',                 N'HADR_WORK_QUEUE',
        N'KSOURCE_WAKEUP',                  N'LAZYWRITER_SLEEP',
        N'LOGMGR_QUEUE',                    N'ONDEMAND_TASK_QUEUE',
        N'PWAIT_ALL_COMPONENTS_INITIALIZED',
        N'QDS_PERSIST_TASK_MAIN_LOOP_SLEEP',
        N'QDS_CLEANUP_STALE_QUERIES_TASK_MAIN_LOOP_SLEEP',
        N'REQUEST_FOR_DEADLOCK_SEARCH',     N'RESOURCE_QUEUE',
        N'SERVER_IDLE_CHECK',               N'SLEEP_BPOOL_FLUSH',
        N'SLEEP_DBSTARTUP',                 N'SLEEP_DCOMSTARTUP',
        N'SLEEP_MASTERDBREADY',             N'SLEEP_MASTERMDREADY',
        N'SLEEP_MASTERUPGRADED',            N'SLEEP_MSDBSTARTUP',
        N'SLEEP_SYSTEMTASK',                N'SLEEP_TASK',
        N'SLEEP_TEMPDBSTARTUP',             N'SNI_HTTP_ACCEPT',
        N'SP_SERVER_DIAGNOSTICS_SLEEP',     N'SQLTRACE_BUFFER_FLUSH',
        N'SQLTRACE_INCREMENTAL_FLUSH_SLEEP',
        N'SQLTRACE_WAIT_ENTRIES',           N'WAIT_FOR_RESULTS',
        N'WAITFOR',                         N'WAITFOR_TASKSHUTDOWN',
        N'WAIT_XTP_HOST_WAIT',              N'WAIT_XTP_OFFLINE_CKPT_NEW_LOG',
        N'WAIT_XTP_CKPT_CLOSE',             N'XE_DISPATCHER_JOIN',
        N'XE_DISPATCHER_WAIT',              N'XE_TIMER_EVENT')
    AND [waiting_tasks_count] > 0
 )
SELECT
    MAX ([W1].[wait_type]) AS [WaitType],
    CAST (MAX ([W1].[WaitS]) AS DECIMAL (16,2)) AS [Wait_S],
    CAST (MAX ([W1].[ResourceS]) AS DECIMAL (16,2)) AS [Resource_S],
    CAST (MAX ([W1].[SignalS]) AS DECIMAL (16,2)) AS [Signal_S],
    MAX ([W1].[WaitCount]) AS [WaitCount],
    CAST (MAX ([W1].[Percentage]) AS DECIMAL (5,2)) AS [Percentage],
    CAST ((MAX ([W1].[WaitS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgWait_S],
    CAST ((MAX ([W1].[ResourceS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgRes_S],
    CAST ((MAX ([W1].[SignalS]) / MAX ([W1].[WaitCount])) AS DECIMAL (16,4)) AS [AvgSig_S]
FROM [Waits] AS [W1]
	INNER JOIN [Waits] AS [W2] ON [W2].[RowNum] <= [W1].[RowNum]
GROUP BY [W1].[RowNum]
	HAVING SUM ([W2].[Percentage]) - MAX ([W1].[Percentage]) < 95; -- percentage threshold
GO


-- STEP 2 - IO by Database
--  
-- Calculating the proportional rank of I/O for each database
-- Original author - Glenn Berry, @GlennAlanBerry
--
-- Helps you rank which layer within a Tegile array you might want to place your objects!
WITH 
  Agg_IO_Stats AS 
    (SELECT   DB_NAME(database_id) AS database_name,
       CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576. AS DECIMAL(12, 2)) AS io_in_mb
    FROM     sys.dm_io_virtual_file_stats(NULL, NULL) AS DM_IO_Stats
    GROUP BY database_id)
SELECT   ROW_NUMBER() OVER (ORDER BY io_in_mb DESC) AS [rank], 
  database_name, io_in_mb, CAST(io_in_mb / SUM(io_in_mb) OVER () * 100 AS DECIMAL(5, 2)) AS pct
FROM Agg_IO_Stats
ORDER BY [rank];

-- With reads and writes broken out from the totals, but without percent rankings.
SELECT
  DB_NAME(database_id) AS database_name,
  CAST(SUM(num_of_bytes_read + num_of_bytes_written) / 1048576. AS DECIMAL(12, 2)) AS io_in_mb,
  CAST(SUM(num_of_bytes_read) / 1048576. AS DECIMAL(12, 2)) AS reads_in_mb,
  CAST(SUM(num_of_bytes_written) / 1048576. AS DECIMAL(12, 2)) AS writes_in_mb
FROM sys.dm_io_virtual_file_stats(NULL, NULL) AS DM_IO_Stats
GROUP BY database_id
ORDER BY io_in_mb DESC;

-- IO and latency by database files.
--
-- Original author - Jonathan Kehayias, @sqlpoolboy
--
-- Remember these latencies: Excellent: < 1ms, Very good: < 5ms, Good: 5 – 10ms, Poor: 10 – 20ms, 
--		Bad: 20 – 100ms, Shocking: 100 – 500ms, Horror show: > 500ms
--
-- Also remember IO stalls are a good indication of disk IO pressure.
SELECT  DB_NAME(vfs.database_id) AS database_name , vfs.database_id , vfs.file_id ,
        io_stall_read_ms / NULLIF(num_of_reads, 0) AS avg_read_latency ,
        io_stall_write_ms / NULLIF(num_of_writes, 0) AS avg_write_latency ,
        io_stall_write_ms / NULLIF(num_of_writes + num_of_writes, 0) AS avg_total_latency ,
        num_of_bytes_read / NULLIF(num_of_reads, 0) AS avg_bytes_per_read ,
        num_of_bytes_written / NULLIF(num_of_writes, 0) AS avg_bytes_per_write ,
        vfs.io_stall , vfs.num_of_reads , vfs.num_of_bytes_read ,vfs.io_stall_read_ms ,
        vfs.num_of_writes ,vfs.num_of_bytes_written , vfs.io_stall_write_ms ,
        size_on_disk_bytes / 1024 / 1024. AS size_on_disk_mbytes , physical_name
FROM    sys.dm_io_virtual_file_stats(NULL, NULL) AS vfs
	JOIN sys.master_files AS mf 
		ON vfs.database_id = mf.database_id AND vfs.file_id = mf.file_id
ORDER BY avg_total_latency DESC;


-- STEP 3 - What indexes have the most IO?
--
-- The following query applies to the database in which it is run (i.e. database scope). 
-- It returns counts of different types of index operations and the times each type of operation was performed. 
SELECT TOP 50 OBJECT_NAME(s.[object_id]) AS objectName
	,i.[name] AS indexName
	,(s.user_seeks + s.user_scans + s.user_lookups) AS Usage
FROM sys.dm_db_index_usage_stats AS s
	INNER JOIN sys.indexes AS i ON s.[object_id] = i.[object_id] AND s.index_id = i.index_id
WHERE OBJECTPROPERTY(s.[object_id], 'IsMsShipped') = 0
	AND s.database_id = DB_ID()
	AND (s.user_seeks + s.user_scans + s.user_lookups) > 1
	AND i.[name] IS NOT NULL
ORDER BY usage DESC;

-- STEP 4 - Statement-level IO
-- 
-- Top 25 statements in the plan cache ranked by average IO incurred
SELECT TOP 25
  (qs.total_logical_reads + qs.total_logical_writes) / qs.execution_count AS [Avg IO],
  SUBSTRING(qt.text, qs.statement_start_offset / 2,
    (CASE 
       WHEN qs.statement_end_offset = -1 THEN LEN(CONVERT(NVARCHAR(MAX), qt.text)) * 2
       ELSE qs.statement_end_offset
     END - qs.statement_start_offset) / 2) AS query_text,
  DB_NAME(qt.dbid),
  qt.objectid
FROM sys.dm_exec_query_stats AS qs
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
ORDER BY [Avg IO] DESC;


-- Finding the most expensive queries, with flexibility for many different metrics
--
-- Original Author: Jimmy May, Sandisk, @aspiringgeek
SELECT   TOP 25
  -- the following four columns are NULL for ad hoc and prepared batches
  DB_Name(qp.dbid) AS dbname,
  qp.dbid,
  qp.objectid,
  qp.number, 
  -- qp.query_plan, --the query plan can be *very* useful; enable if desired
  qt.text,
  SUBSTRING(qt.text, (qs.statement_start_offset / 2) + 1, 
		((CASE statement_end_offset WHEN -1 THEN DATALENGTH(qt.text) 
			ELSE qs.statement_end_offset 
		END - qs.statement_start_offset) / 2) + 1) AS statement_text,
  qs.creation_time,
  qs.last_execution_time,
  qs.execution_count,
  qs.total_worker_time / qs.execution_count AS avg_worker_time,
  qs.total_physical_reads / qs.execution_count AS avg_physical_reads,
  qs.total_logical_reads / qs.execution_count AS avg_logical_reads,
  qs.total_logical_writes / qs.execution_count AS avg_logical_writes,
  qs.total_elapsed_time / qs.execution_count AS avg_elapsed_time,
  --qs.total_clr_time / qs.execution_count AS avg_clr_time,
  qs.total_worker_time,
  qs.last_worker_time,
  qs.min_worker_time,
  qs.max_worker_time,
  qs.total_physical_reads,
  qs.last_physical_reads,
  qs.min_physical_reads,
  qs.max_physical_reads,
  qs.total_logical_reads,
  qs.last_logical_reads,
  qs.min_logical_reads,
  qs.max_logical_reads,
  qs.total_logical_writes,
  qs.last_logical_writes,
  qs.min_logical_writes,
  qs.max_logical_writes,
  qs.total_elapsed_time,
  qs.last_elapsed_time,
  qs.min_elapsed_time,
  qs.max_elapsed_time,
  --qs.total_clr_time, qs.last_clr_time, qs.min_clr_time, qs.max_clr_time, 
  --, qs.sql_handle , qs.statement_start_offset , qs.statement_end_offset
  qs.plan_generation_num -- , qp.encrypted
FROM sys.dm_exec_query_stats AS qs
  CROSS APPLY sys.dm_exec_query_plan(qs.plan_handle) AS qp
  CROSS APPLY sys.dm_exec_sql_text(qs.sql_handle) AS qt
-- WHERE...
ORDER BY qs.total_physical_reads DESC --CPU

--ORDER BY qs.execution_count      DESC  --Frequency
--ORDER BY qs.total_elapsed_time   DESC  --Durn
--ORDER BY qs.total_logical_reads  DESC  --Reads
--ORDER BY qs.total_logical_writes DESC  --Writes
--ORDER BY qs.total_physical_reads DESC  --PhysicalReads
--ORDER BY avg_worker_time         DESC  --AvgCPU
--ORDER BY avg_elapsed_time        DESC  --AvgDurn
--ORDER BY avg_logical_reads       DESC  --AvgReads
--ORDER BY avg_logical_writes      DESC  --AvgWrites
--ORDER BY avg_physical_reads      DESC  --AvgPhysicalReads

--Sample WHERE clauses. Modify WHERE & ORDER BY clauses to suit circumstances
--WHERE last_execution_time > '20070507 15:00'
--WHERE execution_count = 1
--WHERE SUBSTRING(qt.text, (qs.statement_start_offset/2) + 1,
--    ((CASE statement_end_offset
--        WHEN -1 THEN DATALENGTH(qt.text)
--        ELSE qs.statement_end_offset END
--            - qs.statement_start_offset)/2) + 1)
--      LIKE '%MyText%'


-- STEP x: Correlating evidence from PerfMon
--
SELECT (a.cntr_value * 1.0 / b.cntr_value) * 100.0 AS BufferCacheHitRatio
   FROM sys.dm_os_performance_counters  a
   JOIN  (SELECT cntr_value,OBJECT_NAME
       FROM sys.dm_os_performance_counters  
       WHERE counter_name = 'Buffer cache hit ratio base'
           AND OBJECT_NAME = 'SQLServer:Buffer Manager') b ON  a.OBJECT_NAME = b.OBJECT_NAME
   WHERE a.counter_name = 'Buffer cache hit ratio'
     AND a.OBJECT_NAME = 'SQLServer:Buffer Manager';

-- Page Life Expectancy (PLE) value for default instance
-- Good indicator of memory pressure if less than 300
SELECT cntr_value AS [Page Life Expectancy]
FROM   sys.dm_os_performance_counters
WHERE  object_name = 'SQLServer:Buffer Manager' -- Modify this if you have named instances
  AND  counter_name = 'Page life expectancy';



/*
-- In some situations, you may need to clear the wait stats. Here's how:
DBCC SQLPERF (N'sys.dm_os_wait_stats', CLEAR);
GO
*/


-- Percent of Update Operations on the Object
SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.leaf_update_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Update]
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o ON o.object_id = i.object_id
JOIN sys.indexes x ON x.object_id = i.object_id AND x.index_id = i.index_id
WHERE (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
ORDER BY [Percent_Update] DESC;

-- Percent of Scan Operations on the Object
SELECT o.name AS [Table_Name], x.name AS [Index_Name],
       i.partition_number AS [Partition],
       i.index_id AS [Index_ID], x.type_desc AS [Index_Type],
       i.range_scan_count * 100.0 /
           (i.range_scan_count + i.leaf_insert_count
            + i.leaf_delete_count + i.leaf_update_count
            + i.leaf_page_merge_count + i.singleton_lookup_count
           ) AS [Percent_Scan]
FROM sys.dm_db_index_operational_stats (db_id(), NULL, NULL, NULL) i
JOIN sys.objects o ON o.object_id = i.object_id
JOIN sys.indexes x ON x.object_id = i.object_id AND x.index_id = i.index_id
WHERE (i.range_scan_count + i.leaf_insert_count
       + i.leaf_delete_count + leaf_update_count
       + i.leaf_page_merge_count + i.singleton_lookup_count) != 0
AND objectproperty(i.object_id,'IsUserTable') = 1
ORDER BY [Percent_Scan] DESC;

