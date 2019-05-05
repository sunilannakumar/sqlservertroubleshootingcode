
-- Notes (Calculation Schema):
--------
-- a. Re-organise Data:	Spread Data/Indexes as follows - 
--- 1. EiCPDataWarehouse (exist)		=	Heap Tables 				[PRIMARY - Default]
--- 2. PMDataWarehouse  (exist)			=	Clustered Indexes			[PMDATA]
--- 3. PMWorkDataWarehouse (exist)		= 	Heap Tables					[PMWORKDATA]
     -- To be considered for partitioning HEAP Tables after Query Plan review]
--- 4. PMDataWarehouse02 (not exist)	=	Non-Clustered Indexes		[PMDATA02]
-- Note that 2. & 4. is to be based on Query Plans for concurrent access
-------------------------------------------------------------------------
select a.name as LogicalName, f.name as filegroup 
from sys.master_files a
 INNER JOIN sys.filegroups f
  ON a.data_space_id = f.data_space_id
where DB_NAME(a.database_id) = 'SAPBW_DataWarehouse';
-------------------------------------------------------------------------
LogicalName			filegroup
-----------------	---------
EiCPDataWarehouse	PRIMARY
PMDataWarehouse		PMDATA
PMWorkDataWarehouse	PMWORKDATA
PMDataWarehouse02	PMDATA02
-------------------------------------------------------------------------
-------------------------------------------------------------------------
-- Prerequisites
-- 1. Create Folders in partitions: (Set Full Control Permissions to domain user running SQL Server Engine)
------ Ensure that every child folder has Full Control Permissions
-- 1a. D:\Mount\DWDataMain\DWMain2\MSSQL11.MSSQLSERVER\MSSQL

USE SAPBW_DataWarehouse;
go

-- Create new filegroup [PMDATA02] -- this will hold Clustered Indexes
ALTER DATABASE SAPBW_DataWarehouse 
   ADD FILEGROUP PMDATA02
go

-- Add a file to file group
-- PMDATA02
ALTER DATABASE SAPBW_DataWarehouse
   ADD FILE (
      NAME = PMDataWarehouse02,
      FILENAME = 'D:\Mount\DWDataMain\DWMain2\MSSQL11.MSSQLSERVER\MSSQL\PMDATA02.ndf',
      SIZE = 1GB,
      MAXSIZE = 100GB,
      FILEGROWTH = 100MB
      )
   TO FILEGROUP PMDATA02
go

-----------------------------------------------
-- AS-IS
-----------------------------------------------
--- a. Heap Table Location/Filegroup
-----------------------------------------------
SELECT  s.name AS schema_name, o.name AS object_name, i.name AS index_name, f.name as FileGroup
FROM    sys.indexes i
JOIN    sys.objects o ON i.object_id = o.object_id
JOIN    sys.schemas s ON o.schema_id = s.schema_id
JOIN	sys.filegroups f ON  f.data_space_id = i.data_space_id
WHERE   i.type = 0 -- Clustered index
AND       o.is_ms_shipped = 0 -- Uncomment if you want to see only user objects
AND schema_name(o.schema_id) = 'Calculation'
AND     NOT EXISTS (
    SELECT  * 
    FROM    sys.index_columns ic 
	 INNER JOIN sys.columns c ON c.object_id = ic.object_id
	 AND c.column_id = ic.column_id
    WHERE   ic.object_id = i.object_id AND ic.index_id = i.index_id
    AND     c.is_identity = 1 -- Is identity column
)
ORDER BY schema_name, f.name, object_name, index_name;
-----------------
-- Sample Results
-----------------
schema_name	object_name			index_name	FileGroup
----------- -----------------   ----------	---------
Calculation	INT_WeeklyReports	NULL		PRIMARY
Calculation	INT_WeeklyScheme	NULL		PRIMARY
Calculation	Temp_WeeklyReports	NULL		PRIMARY
Calculation	TimelineLayer		NULL		PRIMARY
Calculation	UMCClockStatus		NULL		PRIMARY



--- b. Clustered Indexes Location/Filegroup
-----------------------------------------------------------------------------------------------
SELECT  s.name AS schema_name, o.name AS object_name, i.name AS index_name, f.name as FileGroup
FROM    sys.indexes i
JOIN    sys.objects o ON i.object_id = o.object_id
JOIN    sys.schemas s ON o.schema_id = s.schema_id
JOIN	sys.filegroups f ON  f.data_space_id = i.data_space_id
WHERE   i.type = 1 -- Clustered index
AND       o.is_ms_shipped = 0 -- Uncomment if you want to see only user objects
AND schema_name(o.schema_id) = 'Calculation'
AND     NOT EXISTS (
    SELECT  * 
    FROM    sys.index_columns ic 
	 INNER JOIN sys.columns c ON c.object_id = ic.object_id
	 AND c.column_id = ic.column_id
    WHERE   ic.object_id = i.object_id AND ic.index_id = i.index_id
    AND     c.is_identity = 1 -- Is identity column
)
ORDER BY schema_name, f.name, object_name, index_name;
-----------------
-- Sample Results
-----------------
--	schema_name	object_name				index_name					FileGroup
------------------------------------------------------------------------------
--	Calculation	GSoPPosition			PK_GSoPPosition				PMDATA
--	Calculation	CapturePointExemption	PK_CapturePointExemption_1	PRIMARY		[To move to PMDATA]
--	Calculation	CapturePointExtension	PK_CapturePointExtension_1	PRIMARY		[To move to PMDATA]
--	Calculation	CapturePointTimestamp	PK_CapturePointTimestamp	PRIMARY		[To move to PMDATA]
--	Calculation	MaximumTimestamp		PK_MaximumTimestamp_1		PRIMARY		[To move to PMDATA]
--	Calculation	TaskPosition			PK_TaskPosition				PRIMARY		[To move to PMDATA]


--- c. Non- Clustered Indexes (HEAP) Location/Filegroup
----------------------------------------------------------------------------
SELECT o.name, i.type_desc, o.type_desc, f.name as FileGroup 
FROM sys.indexes i
INNER JOIN sys.objects o
 ON  i.object_id = o.object_id
INNER JOIN sys.filegroups f
 ON  f.data_space_id = i.data_space_id
WHERE o.type_desc = 'USER_TABLE'
AND i.type_desc = 'HEAP'
AND schema_name(schema_id) = 'Calculation'
ORDER BY o.name
GO
-----------------
-- Sample Results
-----------------
--	INT_WeeklyReports	HEAP	USER_TABLE	PRIMARY			[To move to PMDATA02]
--	INT_WeeklyScheme	HEAP	USER_TABLE	PRIMARY			[To move to PMDATA02]
--	Temp_WeeklyReports	HEAP	USER_TABLE	PRIMARY			[To move to PMDATA02]
--	TimelineLayer		HEAP	USER_TABLE	PRIMARY			[To move to PMDATA02]
--	UMCClockStatus		HEAP	USER_TABLE	PRIMARY			[To move to PMDATA02]



------------------------------------------------
-- Relocation Script
------------------------------------------------

--- a. Heap Table Location/Filegroup
--- All HEAP tables already in PRIMARY/EiCPDataWarehouse
--------------------------------------------------------

--- b. Clustered Indexes Location/Filegroup
--------------------------------------------------------
---- 1. CapturePointExemption
CREATE UNIQUE CLUSTERED INDEX PK_CapturePointExemption_1 
ON Calculation.CapturePointExemption (CapturePointExemptionID) 
WITH (DROP_EXISTING = ON)
ON PMDATA;
GO

---- 2. CapturePointExtension
CREATE UNIQUE CLUSTERED INDEX PK_CapturePointExtension_1 
ON Calculation.CapturePointExtension (CapturePointExtensionID) 
WITH (DROP_EXISTING = ON)
ON PMDATA;
GO

---- 3. CapturePointTimestamp
CREATE UNIQUE CLUSTERED INDEX PK_CapturePointTimestamp 
ON Calculation.CapturePointTimestamp (CapturePointTimestampID) 
WITH (DROP_EXISTING = ON)
ON PMDATA;
GO

---- 4. MaximumTimestamp
CREATE UNIQUE CLUSTERED INDEX PK_MaximumTimestamp_1 
ON Calculation.MaximumTimestamp (JobPhaseStandardID, PenaltyReasonCode) 
WITH (DROP_EXISTING = ON)
ON PMDATA;
GO

---- 5. TaskPosition
CREATE UNIQUE CLUSTERED INDEX PK_TaskPosition 
ON Calculation.TaskPosition (TimeLineTaskID) 
WITH (DROP_EXISTING = ON)
ON PMDATA;
GO


--- c. Non- Clustered Indexes Location/Filegroup
--------------------------------------------------------
---- 1. INT_WeeklyReports
CREATE CLUSTERED INDEX INDXTMP_INT_WeeklyReports
ON Calculation.INT_WeeklyReports (TaskNumber, jobphaseid)
ON PMDATA02;
GO

DROP INDEX INDXTMP_INT_WeeklyReports
ON Calculation.INT_WeeklyReports;
GO

---- 2. INT_WeeklyScheme
CREATE CLUSTERED INDEX INDXTMP_INT_WeeklyScheme
ON Calculation.INT_WeeklyScheme (jobphaseid, TotalTasks)
ON PMDATA02;
GO

DROP INDEX INDXTMP_INT_WeeklyScheme
ON Calculation.INT_WeeklyScheme;
GO

---- 3. Temp_WeeklyReports
CREATE CLUSTERED INDEX INDXTMP_Temp_WeeklyReports
ON Calculation.Temp_WeeklyReports (JobCode, jobphaseid)
ON PMDATA02;
GO

DROP INDEX INDXTMP_Temp_WeeklyReports
ON Calculation.Temp_WeeklyReports;
GO

---- 4. TimelineLayer
CREATE CLUSTERED INDEX INDXTMP_TimelineLayer
ON Calculation.TimelineLayer (TimeLineLayerID, TimeLineID)
ON PMDATA02;
GO

DROP INDEX INDXTMP_TimelineLayer
ON Calculation.TimelineLayer;
GO

---- 4. UMCClockStatus
CREATE CLUSTERED INDEX INDXTMP_UMCClockStatus
ON Calculation.UMCClockStatus (UMCClockStatusID)
ON PMDATA02;
GO

DROP INDEX INDXTMP_UMCClockStatus
ON Calculation.UMCClockStatus;
GO






