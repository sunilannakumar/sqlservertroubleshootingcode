set nocount on
go
----------Table to Hold Fragmented Objects----
If exists (select * from tempdb.sys.all_objects where name like '#Reorganize%' )
Drop table #Reorganize
create table #Reorganize       
(Schemaname varchar(50),
tablename varchar(50),
Indexname varchar(150),
Fragmentation float)
go
If exists (select * from tempdb.sys.all_objects where name like '#Rebuild%' )
drop table #Rebuild
create table #Rebuild      
(Schemaname varchar(100),
tablename varchar(100),
Indexname varchar(150),
Fragmentation float)
go
-----------Inserting All fragmented table where fragmentation level is between 5 to 30 in temptable----
insert into #reorganize(Schemaname,tablename,Indexname,Fragmentation)
 
select s.name,o.name,i.name,ips.avg_fragmentation_in_percent from sys.objects o left outer join sys.schemas s on
o.schema_id= s.schema_id  left outer join sys.indexes i on
o.object_id=i.object_id left outer join sys.dm_db_index_physical_stats (db_id(), NULL, NULL, NULL, NULL) AS IPS
on i.object_id=IPS.object_id and i.index_id=ips.index_id
where o.type='U' and i.index_id > 0 and avg_fragmentation_in_percent between 5and 30
go
insert into #Rebuild(Schemaname,tablename,Indexname,Fragmentation)
 
select s.name,o.name,i.name,ips.avg_fragmentation_in_percent from sys.objects o left outer join sys.schemas s on
o.schema_id= s.schema_id  left outer join sys.indexes i on
o.object_id=i.object_id left outer join sys.dm_db_index_physical_stats (db_id(), NULL, NULL, NULL, NULL) AS IPS
on i.object_id=IPS.object_id and i.index_id=ips.index_id
where o.type='U' and i.index_id > 0 and avg_fragmentation_in_percent > 40
 
-----------Cursor for reorganize---------------------
Declare @cmd varchar(1000)
DECLARE @Iname varchar(250)
DECLARE @Jname varchar(250)
declare @sname varchar(150)
declare @tname varchar(150)
DECLARE db_reindex CURSOR for
select  indexname,[SCHEMANAME],tablename from #Reorganize
OPEN db_reindex
FETCH NEXT from db_reindex into @Iname,@sname,@tname
WHILE @@FETCH_STATUS = 0
BEGIN
set @Jname= @sname + '.'+  @tname
set @cmd= 'Alter INdex ' + @Iname + ' on '+ @Jname + ' reorganize'
execute (@cmd)
FETCH NEXT from db_reindex into @iname,@sname,@tname
select 'Executed Reindex reorganize for ' + @Jname + ' '+ @Iname
END
CLOSE db_reindex
DEALLOCATE db_reindex
GO
------------Cursor For Rebuild--------------
Declare @cmd Varchar(1000)
DECLARE @Iname varchar(250)
DECLARE @Jname varchar(250)
declare @sname varchar(150)
declare @tname varchar(150)
DECLARE db_reindex CURSOR for
select  indexname,[SCHEMANAME],tablename from #Rebuild
OPEN db_reindex
FETCH NEXT from db_reindex into @Iname,@sname,@tname
WHILE @@FETCH_STATUS = 0
BEGIN
set @Jname= @sname + '.'+  @tname
set @cmd= 'Alter INdex ' + @Iname + ' on '+ @Jname + ' rebuild'
execute (@cmd)
FETCH NEXT from db_reindex into @iname,@sname,@tname
select 'Executed Reindex rebuild for ' + @Jname + ' '+ @Iname
END
CLOSE db_reindex
DEALLOCATE db_reindex
GO












----http://www.sql-server-performance.com/2012/trouble-shooting-sql-server-ra-memory-consumption/---

