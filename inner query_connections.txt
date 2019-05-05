SELECT dec.client_net_address ,
des.host_name ,
dest.text
FROM sys.dm_exec_sessions des
INNER JOIN sys.dm_exec_connections dec
ON des.session_id = dec.session_id
CROSS APPLY sys.dm_exec_sql_text(dec.most_recent_sql_handle) dest
WHERE des.program_name LIKE 'Microsoft SQL Server Management Studio%'
ORDER BY des.program_name ,
dec.client_net_address