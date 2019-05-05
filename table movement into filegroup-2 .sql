
-- Notes (SSDM Schema):
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
/**
-- Created during Calculation Engine Reorg
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
      MAXSIZE = 50GB,
      FILEGROWTH = 100MB
      )
   TO FILEGROUP PMDATA02
go
**/
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
AND schema_name(o.schema_id) = 'SSDM'
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
schema_name	object_name								index_name	FileGroup
----------- -----------------   					----------	---------
SSDM		DimUserStatus							NULL		PRIMARY
SSDM		FactProcessStepInstance					NULL		PRIMARY
SSDM		FactSalesServiceOrderAndServiceRequest	NULL		PRIMARY
SSDM		ServiceRequestCPDates_cubes				NULL		PRIMARY
SSDM		ServiceRequestFlags_cubes				NULL		PRIMARY


--- b. Clustered Indexes Location/Filegroup
-----------------------------------------------------------------------------------------------
SELECT  s.name AS schema_name, o.name AS object_name, i.name AS index_name, f.name as FileGroup
FROM    sys.indexes i
JOIN    sys.objects o ON i.object_id = o.object_id
JOIN    sys.schemas s ON o.schema_id = s.schema_id
JOIN	sys.filegroups f ON  f.data_space_id = i.data_space_id
WHERE   i.type = 1 -- Clustered index
AND       o.is_ms_shipped = 0 -- Uncomment if you want to see only user objects
AND schema_name(o.schema_id) = 'SSDM'
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
--	schema_name	object_name				index_name						FileGroup
--------------- ----------------------------------------------------	---------
--	SSDM		FactCustomerComplaints	PK_FactCustomerComplaints_P_2	PRIMARY	[To move to PMDATA]


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
AND schema_name(schema_id) = 'SSDM'
ORDER BY o.name
GO
-----------------
-- Sample Results
-----------------
--	DimUserStatus							HEAP	USER_TABLE	PRIMARY
--	FactProcessStepInstance					HEAP	USER_TABLE	PRIMARY
--	FactSalesServiceOrderAndServiceRequest	HEAP	USER_TABLE	PRIMARY
--	ServiceRequestCPDates_cubes				HEAP	USER_TABLE	PRIMARY
--	ServiceRequestFlags_cubes				HEAP	USER_TABLE	PRIMARY

------------------------------------------------
-- Relocation Script
------------------------------------------------

--- a. Heap Table Location/Filegroup
--- All HEAP tables already in PRIMARY/EiCPDataWarehouse
--------------------------------------------------------

--- b. Clustered Indexes Location/Filegroup
--------------------------------------------------------
---- 1. FactCustomerComplaints
CREATE UNIQUE CLUSTERED INDEX PK_FactCustomerComplaints_P_2 
ON SSDM.FactCustomerComplaints (CRMComplaintID, CRMActivityGUID, CRMITDocNum, CRMBusTransType) 
WITH (DROP_EXISTING = ON)
ON PMDATA;
GO


--- c. Non- Clustered Indexes Location/Filegroup
--------------------------------------------------------
---- 1. DimUserStatus
CREATE CLUSTERED INDEX INDXTMP_DimUserStatus
ON SSDM.DimUserStatus (DM_ComplaintStatus_Key)
ON PMDATA02;
GO

DROP INDEX INDXTMP_DimUserStatus
ON SSDM.DimUserStatus ;
GO


---- 2. FactProcessStepInstance
CREATE CLUSTERED INDEX INDXTMP_FactProcessStepInstance
ON SSDM.FactProcessStepInstance (DW_ProcessStepInstanceID)
ON PMDATA02;
GO

DROP INDEX INDXTMP_FactProcessStepInstance
ON SSDM.FactProcessStepInstance ;
GO


---- 3. FactSalesServiceOrderAndServiceRequest
CREATE CLUSTERED INDEX INDXTMP_FactSalesServiceOrderAndServiceRequest
ON SSDM.FactSalesServiceOrderAndServiceRequest (DW_SalesServiceOrderAndServiceRequestID)
ON PMDATA02;
GO

DROP INDEX INDXTMP_FactSalesServiceOrderAndServiceRequest
ON SSDM.FactSalesServiceOrderAndServiceRequest ;
GO


---- 4. ServiceRequestCPDates_cubes
CREATE CLUSTERED INDEX INDXTMP_ServiceRequestCPDates_cubes
ON SSDM.ServiceRequestCPDates_cubes (RowKey)
ON PMDATA02;
GO

DROP INDEX INDXTMP_ServiceRequestCPDates_cubes
ON SSDM.ServiceRequestCPDates_cubes ;
GO


---- 5. ServiceRequestFlags_cubes
CREATE CLUSTERED INDEX INDXTMP_ServiceRequestFlags_cubes
ON SSDM.ServiceRequestFlags_cubes (SERVICE_REQUEST_NUMBER)
ON PMDATA02;
GO

DROP INDEX INDXTMP_ServiceRequestFlags_cubes
ON SSDM.ServiceRequestFlags_cubes ;
GO




