DECLARE @TableName VARCHAR(255)
DECLARE @sql NVARCHAR(500)
DECLARE @fillfactor INT
SET @fillfactor = 80
DECLARE TableCursor CURSOR FOR
SELECT OBJECT_SCHEMA_NAME([object_id])+'.'+name AS TableName
FROM sys.tables
OPEN TableCursor
FETCH NEXT FROM TableCursor INTO @TableName
WHILE @@FETCH_STATUS = 0
BEGIN
SET @sql = 'ALTER INDEX ALL ON ' + @TableName + ' REBUILD WITH (FILLFACTOR = ' + CONVERT(VARCHAR(3),@fillfactor) + ')'
EXEC (@sql)
FETCH NEXT FROM TableCursor INTO @TableName
END
CLOSE TableCursor
DEALLOCATE TableCursor
GO


