SELECT TOP 100 
        qs.sql_handle 
        ,qs.plan_handle 
        ,cp.cacheobjtype 
        ,cp.usecounts 
        ,cp.size_in_bytes   
        ,qs.statement_start_offset 
        ,qs.statement_end_offset 
        ,qt.dbid 
        ,qt.objectid 
        ,qt.text 
        ,SUBSTRING(qt.text,qs.statement_start_offset/2,  
            (case when qs.statement_end_offset = -1  
            then len(convert(nvarchar(max), qt.text)) * 2  
            else qs.statement_end_offset end -qs.statement_start_offset)/2)  
        as statement 
FROM sys.dm_exec_query_stats qs 
cross apply sys.dm_exec_sql_text(qs.sql_handle) as qt 
inner join sys.dm_exec_cached_plans as cp on qs.plan_handle=cp.plan_handle 
where cp.plan_handle=qs.plan_handle 
--and qt.dbid = db_id() 
ORDER BY [dbid],[Usecounts] DESC 