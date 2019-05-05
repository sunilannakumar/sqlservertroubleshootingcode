SELECT [name] AS DatabaseName
, CONVERT(varchar(10),DATABASEPROPERTYEX([Name] , 'IsAutoClose')) AS AutoClose
, CONVERT(varchar(10),DATABASEPROPERTYEX([Name] , 'IsAutoShrink')) AS AutoShrink
FROM master.dbo.sysdatabases
Order By DatabaseName