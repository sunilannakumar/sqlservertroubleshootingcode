DECLARE @tracefile NVARCHAR(MAX) 
SET @tracefile = (SELECT LEFT([path],LEN([path])-CHARINDEX('\',REVERSE([path])))+ '\log.trc' FROM sys.traces WHERE [is_default] = 1) 
 
SELECT 
 gt.[ServerName] 
,gt.[DatabaseName] 
,gt.[SPID] 
,gt.[StartTime] 
,gt.[ObjectName] 
,gt.[objecttype] [ObjectTypeID]--http://msdn.microsoft.com/en-us/library/ms180953.aspx 
,sv.[subclass_name] [ObjectType] 
,e.[category_id] [CategoryID] 
,c.[Name] [Category] 
,gt.[EventClass] [EventID] 
,e.[Name] [EventName] 
,gt.[LoginName] 
,gt.[ApplicationName] 
,gt.[TextData] 
FROM fn_trace_gettable(@tracefile, DEFAULT) gt 
LEFT JOIN sys.trace_subclass_values sv ON gt.[eventclass] = sv.[trace_event_id] AND sv.[subclass_value] = gt.[objecttype] 
INNER JOIN sys.trace_events e ON gt.[eventclass] = e.[trace_event_id] 
INNER JOIN sys.trace_categories c ON e.[category_id] = c.[category_id] 
WHERE gt.[spid] > 50 
AND gt.[objecttype] <> 21587 --Ignore Statistics 
AND gt.[databasename] <> 'tempdb' --Ignore tempdb 
AND gt.[starttime] >= DATEADD(DAY,0,DATEDIFF(DAY,0,GETDATE())) --From Today 00:00:00.000