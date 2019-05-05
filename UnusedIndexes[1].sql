/*
Each index not only brings benefits but also cost efforts when data are updated.
But when the index is never used, these are unnecessary costs and the index could be removed.

This Transact-SQL statement list all indexes which haven't been used since the last server start, whereby only user tables and views are considered.
Disabled indexes are excluded as well as heap.
Primary keys and unique indexes are also excluded, because they are part of business logic and required for FK constraints.

Works with SQL Server 2005 and higher versions in all editions.
Requires VIEW SERVER STATE permissions.
*/

-- Unused indexes
SELECT SCH.name + '.' + OBJ.name AS ObjectName
      ,OBJ.type_desc AS ObjectType
      ,IDX.name AS IndexName
      ,IDX.type_desc AS IndexType
FROM sys.indexes AS IDX
     LEFT JOIN sys.dm_db_index_usage_stats AS IUS
         ON IUS.index_id = IDX.index_id
            AND IUS.object_id = IDX.object_id
     INNER JOIN sys.objects AS OBJ
         ON IDX.object_id = OBJ.object_id
     INNER JOIN sys.schemas AS SCH
         ON OBJ.schema_id = SCH.schema_id
WHERE OBJ.is_ms_shipped = 0       -- Exclude MS objects
      AND OBJ.type IN ('U', 'V')  -- Only user defined tables & views
      AND IDX.type > 0            -- Ignore heaps
      AND IDX.is_disabled = 0     -- Disabled indexes aren't used anyway
      AND IDX.is_primary_key = 0  -- Exclude PK => FK constraints / part of business logic
      AND IDX.is_unique = 0       -- Exclude unique indexes => part of business logic
      AND IUS.object_id IS NULL
ORDER BY ObjectName
        ,IndexName;