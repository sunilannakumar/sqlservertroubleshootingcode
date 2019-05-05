----------------------------------------------------------------------------------------------------------------
-- The sample scripts are not supported under any Microsoft standard support 
-- program or service. The sample scripts are provided AS IS without warranty  
-- of any kind. Microsoft further disclaims all implied warranties including,  
-- without limitation, any implied warranties of merchantability or of fitness for 
-- a particular purpose. The entire risk arising out of the use or performance of  
-- the sample scripts and documentation remains with you. In no event shall 
-- Microsoft, its authors, or anyone else involved in the creation, production, or 
-- delivery of the scripts be liable for any damages whatsoever (including, 
-- without limitation, damages for loss of business profits, business interruption, 
-- loss of business information, or other pecuniary loss) arising out of the use 
-- of or inability to use the sample scripts or documentation, even if Microsoft 
-- has been advised of the possibility of such damages 
-----------------------------------------------------------------------------------------------------------------

SET NOCOUNT ON;

-- Know product version since values may defer based on version

DECLARE @ProductVersion nvarchar(128);
DECLARE @charindex bigint;
DECLARE @MajorVersion nvarchar(max);
SELECT @ProductVersion = CAST(SERVERPROPERTY('ProductVersion') AS nvarchar(128));
SELECT @charindex = CHARINDEX('.', @ProductVersion);
SET @MajorVersion = SUBSTRING(@ProductVersion, 1, @charindex-1);
DECLARE @tempValue sql_variant;

-- Create table of default values
DECLARE @tvDefaultValues TABLE (Id int IDENTITY(1,1), ConfigurationOption nvarchar(128), Value sql_variant);
INSERT INTO @tvDefaultValues VALUES ('access check cache bucket count', 0);
INSERT INTO @tvDefaultValues VALUES ('access check cache quota', 0);
INSERT INTO @tvDefaultValues VALUES ('ad hoc distributed queries', 0);
INSERT INTO @tvDefaultValues VALUES ('affinity I/O mask', 0);
INSERT INTO @tvDefaultValues VALUES ('affinity64 I/O mask', 0);
INSERT INTO @tvDefaultValues VALUES ('affinity mask', 0);
INSERT INTO @tvDefaultValues VALUES ('affinity64 mask', 0);
INSERT INTO @tvDefaultValues VALUES ('allow updates', 0);
INSERT INTO @tvDefaultValues VALUES ('backup compression default', 0);
INSERT INTO @tvDefaultValues VALUES ('blocked process threshold', 0);
INSERT INTO @tvDefaultValues VALUES ('c2 audit mode', 0);
INSERT INTO @tvDefaultValues VALUES ('clr enabled', 0);
INSERT INTO @tvDefaultValues VALUES ('common criteria compliance enabled', 0);
INSERT INTO @tvDefaultValues VALUES ('contained database authentication', 0);
INSERT INTO @tvDefaultValues VALUES ('cost threshold for parallelism', 5);
INSERT INTO @tvDefaultValues VALUES ('cross db ownership chaining', 0);
INSERT INTO @tvDefaultValues VALUES ('cursor threshold', -1);
INSERT INTO @tvDefaultValues VALUES ('Database Mail XPs', 0);
INSERT INTO @tvDefaultValues VALUES ('default full-text language', 1033);
INSERT INTO @tvDefaultValues VALUES ('default language', 0);
INSERT INTO @tvDefaultValues VALUES ('default trace enabled', 1);
INSERT INTO @tvDefaultValues VALUES ('disallow results from triggers', 0);
INSERT INTO @tvDefaultValues VALUES ('EKM provider enabled', 0);
INSERT INTO @tvDefaultValues VALUES ('filestream_access_level', 0);
INSERT INTO @tvDefaultValues VALUES ('fill factor', 0);
INSERT INTO @tvDefaultValues VALUES ('ft crawl bandwidth (max)', 100);
INSERT INTO @tvDefaultValues VALUES ('ft crawl bandwidth (min)', 0);
INSERT INTO @tvDefaultValues VALUES ('ft notify bandwidth (max)', 100);
INSERT INTO @tvDefaultValues VALUES ('ft notify bandwidth (min)', 0);
INSERT INTO @tvDefaultValues VALUES ('index create memory', 0);
INSERT INTO @tvDefaultValues VALUES ('in-doubt xact resolution', 0);
INSERT INTO @tvDefaultValues VALUES ('lightweight pooling', 0);
INSERT INTO @tvDefaultValues VALUES ('locks', 0);
INSERT INTO @tvDefaultValues VALUES ('max degree of parallelism', 0);
INSERT INTO @tvDefaultValues VALUES ('max full-text crawl range', 4);
INSERT INTO @tvDefaultValues VALUES ('max server memory', 2147483647);	-- actual name may also include 'MB', keeping per MSDN definition in link mentioned above.
INSERT INTO @tvDefaultValues VALUES ('max text repl size', 65536);
INSERT INTO @tvDefaultValues VALUES ('max worker threads', 0);
INSERT INTO @tvDefaultValues VALUES ('media retention', 0);
INSERT INTO @tvDefaultValues VALUES ('min memory per query', 1024);
INSERT INTO @tvDefaultValues VALUES ('min server memory', 0);
INSERT INTO @tvDefaultValues VALUES ('nested triggers', 1);
INSERT INTO @tvDefaultValues VALUES ('network packet size', 4096);
INSERT INTO @tvDefaultValues VALUES ('Ole Automation Procedures', 0);
INSERT INTO @tvDefaultValues VALUES ('open objects', 0);
INSERT INTO @tvDefaultValues VALUES ('optimize for ad hoc workloads', 0);
INSERT INTO @tvDefaultValues VALUES ('PH_timeout', 60);
INSERT INTO @tvDefaultValues VALUES ('precompute rank', 0);
INSERT INTO @tvDefaultValues VALUES ('priority boost', 0);
INSERT INTO @tvDefaultValues VALUES ('query governor cost limit', 0);
INSERT INTO @tvDefaultValues VALUES ('query wait', -1);
INSERT INTO @tvDefaultValues VALUES ('recovery interval', 0);
INSERT INTO @tvDefaultValues VALUES ('remote access', 1);
INSERT INTO @tvDefaultValues VALUES ('remote admin connections', 0);
IF @MajorVersion IN (9, 10) SET @tempValue = 20 ELSE SET @tempValue = 10;
INSERT INTO @tvDefaultValues VALUES ('remote login timeout', @tempValue);
INSERT INTO @tvDefaultValues VALUES ('remote proc trans', 0);
INSERT INTO @tvDefaultValues VALUES ('remote query timeout', 600);
INSERT INTO @tvDefaultValues VALUES ('Replication XPs Option', 0);
INSERT INTO @tvDefaultValues VALUES ('scan for startup procs', 0);
INSERT INTO @tvDefaultValues VALUES ('server trigger recursion', 1);
INSERT INTO @tvDefaultValues VALUES ('set working set size', 0);
INSERT INTO @tvDefaultValues VALUES ('show advanced options', 0);
INSERT INTO @tvDefaultValues VALUES ('SMO and DMO XPs', 1);
INSERT INTO @tvDefaultValues VALUES ('transform noise words', 0);
INSERT INTO @tvDefaultValues VALUES ('two digit year cutoff', 2049);
INSERT INTO @tvDefaultValues VALUES ('user connections', 0);
INSERT INTO @tvDefaultValues VALUES ('user options', 0);
INSERT INTO @tvDefaultValues VALUES ('xp_cmdshell', 0);

SELECT N'Displaying non-default Sql configuration (sp_configure) values:';
SELECT N'Disclaimer: Non-default values are just for information and are for troubleshooting reference.';
SELECT sc.name, sc.value_in_use, DF.Value AS DefaultValue 
FROM @tvDefaultValues DF JOIN sys.configurations sc 
ON sc.name LIKE '%' + DF.ConfigurationOption + '%' AND DF.Value <> sc.value_in_use 
WHERE sc.name <> 'show advanced options' ORDER BY sc.name



