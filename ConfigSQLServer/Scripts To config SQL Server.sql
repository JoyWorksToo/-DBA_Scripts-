/*
SELECT DISTINCT parent_node_id
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
	  AND parent_node_id < 64;

select *
from sys.dm_os_memory_nodes
where memory_node_id <> 64 --dedicated to DACav

SELECT *
FROM sys.dm_os_nodes 
WHERE node_id <> 64; --Excluded DAC node
*/

/****************/
/*	AuditMode	*/
/****************/
USE [master]
GO
SET NOCOUNT ON

DECLARE @Results TABLE (Value varchar(300), Data int)
INSERT INTO @Results
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel'

IF (SELECT [Data] FROM @Results) <> 3
BEGIN
	PRINT 'Audit Level is not 3, changing ...'
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'AuditLevel', REG_DWORD, 3
END
ELSE PRINT 'Audit Level OK.'


/************************/
/*	Disable sa account	*/
/************************/
IF (select is_disabled from sys.server_principals where sid = 1) <> 1
BEGIN
	PRINT 'SA is not disabled, disabling login ...'
	DECLARE @saName VARCHAR(128) = (SELECT name FROM sys.server_principals where SID = 1)
	DECLARE @exec VARCHAR(1000) = 'ALTER LOGIN ' + @saName + ' DISABLE'
	EXEC (@exec)
END
ELSE PRINT 'SA is disabled.'
GO

/************************/
/*	Renaming SA account	*/
/************************/
USE [master]
GO
SET NOCOUNT ON

IF ((select name from sys.server_principals where sid = 1) <> 'Stone_admin')
BEGIN
	PRINT 'SA name is not Stone_admin, altering...'
	DECLARE @saName VARCHAR(128) = (SELECT name FROM sys.server_principals where SID = 1)
	DECLARE @exec VARCHAR(1000) = 'ALTER LOGIN ' + @saName + ' WITH NAME = Stone_admin'
	EXEC (@exec)
END
ELSE PRINT 'SA name is Stone_admin.'
GO

/****************************************/
/*	Altering Number of errorlog Files	*/
/****************************************/
USE [master]
GO
SET NOCOUNT ON

declare @Results table (Value varchar(300), Data int)
declare @data int
insert into @Results
EXEC xp_instance_regread N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs'

select @data = [data] from @Results

IF (ISNULL(@data, 0) <> 15)
BEGIN
	PRINT 'Number of errorlog files is not 15, changing ... '
	EXEC xp_instance_regwrite N'HKEY_LOCAL_MACHINE', N'Software\Microsoft\MSSQLServer\MSSQLServer', N'NumErrorLogs', REG_DWORD, 15
END
ELSE PRINT 'Number of errorlogs is 15.'
GO

/****************************/
/*	Altering User Options	*/
/****************************/
USE [master]
GO
SET NOCOUNT ON

IF ((SELECT CAST([value] AS INT ) FROM sys.configurations WHERE [name] = 'user options') <> 17440)
BEGIN
PRINT 'User options is not 17440 (Capela recomended it), Default Connection Options:'
PRINT 'ANSI NULLS'
PRINT 'ANSI NULLS Default ON'
PRINT 'xact abort'
PRINT 'Altering ... '
EXEC sp_configure 'user options', N'17440' ;  
RECONFIGURE
END
ELSE PRINT 'User Options is 17440.'
GO

/********************************************/
/*	REVOKE EXECUTE on xp_regread TO PUBLIC	*/
/********************************************/
USE [master]
GO
SET NOCOUNT ON


IF (
	SELECT 
		perm.state_desc
		--obj.name, roleprinc.name, perm.state_desc, perm.permission_name, obj.name
	FROM sys.database_principals AS roleprinc
	LEFT JOIN sys.database_permissions AS perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
	LEFT JOIN sysobjects AS obj ON obj.[id] = perm.[major_id]
	WHERE 
		obj.name = 'xp_regread'
) <> 'REVOKE'
BEGIN
	PRINT 'PUBLIC has EXECUTE to xp_regread, REVOKING permission ...'
	REVOKE EXECUTE ON xp_dirtree TO PUBLIC; 
END
ELSE PRINT 'PLUBLIC does not have permission to EXECUTE on xp_dirtree.'
GO

/********************************************/
/*	REVOKE EXECUTE on xp_dirtree TO PUBLIC	*/
/********************************************/
USE [master]
GO
SET NOCOUNT ON


IF (
	SELECT 
		perm.state_desc
		--obj.name, roleprinc.name, perm.state_desc, perm.permission_name, obj.name
	FROM sys.database_principals AS roleprinc
	LEFT JOIN sys.database_permissions AS perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
	LEFT JOIN sysobjects AS obj ON obj.[id] = perm.[major_id]
	WHERE 
		obj.name = 'xp_dirtree'
) <> 'REVOKE'
BEGIN
	PRINT 'PUBLIC has EXECUTE to xp_dirtree, REVOKING permission ...'
	REVOKE EXECUTE ON xp_dirtree TO PUBLIC; 
END
ELSE PRINT 'PLUBLIC does not have permission to EXECUTE on xp_dirtree.'



/************************************************/
/*	REVOKE EXECUTE on xp_fixeddrives TO PUBLIC	*/
/************************************************/
USE [master]
GO
SET NOCOUNT ON

IF (
	SELECT 
		perm.state_desc
		--obj.name, roleprinc.name, perm.state_desc, perm.permission_name, obj.name
	FROM sys.database_principals AS roleprinc
	LEFT JOIN sys.database_permissions AS perm ON perm.[grantee_principal_id] = roleprinc.[principal_id]
	LEFT JOIN sysobjects AS obj ON obj.[id] = perm.[major_id]
	WHERE 
		obj.name = 'xp_fixeddrives'
) <> 'REVOKE'
BEGIN
	PRINT 'PUBLIC has EXECUTE to xp_fixeddrives, REVOKING permission ...'
	REVOKE EXECUTE ON xp_dirtree TO PUBLIC; 
END
ELSE PRINT 'PLUBLIC does not have permission to EXECUTE on xp_dirtree.'

/********************************/
/*	Configure Fill Factor 90	*/
/********************************/
USE [master]
GO
SET NOCOUNT ON
GO

PRINT 'Setting fillfactor 90.'

EXEC sys.sp_configure N'show advanced options', N'1'  RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'fill factor (%)', N'90'
GO
RECONFIGURE WITH OVERRIDE
GO
EXEC sys.sp_configure N'show advanced options', N'0'  RECONFIGURE WITH OVERRIDE
GO

/********************/
/*	Configure DAC	*/
/********************/
USE [master]
GO
SET NOCOUNT ON
GO

PRINT 'Setting remote admin connections.'
GO
sp_configure 'remote admin connections', 1;  
GO  
RECONFIGURE;  
GO 


/************************/
/*	Configure MAXDOP	*/
/************************/
USE [master]
GO
SET NOCOUNT ON
GO

DECLARE @TotalNumaNodes int
DECLARE @LogicalCores int
DECLARE @maxdop int

select @TotalNumaNodes = count(*) 
from sys.dm_os_memory_nodes
where memory_node_id <> 64 --dedicated to DACav

SELECT 
	@LogicalCores = cpu_count 
FROM sys.dm_os_sys_info

IF (@TotalNumaNodes = 1)
BEGIN
	IF (@LogicalCores > 16) SET @maxdop = 8
	--ELSE IF (@LogicalCores > 8 AND @LogicalCores < 16 ) SET @maxdop = 4
	--ELSE IF (@LogicalCores <= 8) SET @maxdop = @LogicalCores/2
	ELSE IF (@LogicalCores < 16) SET @maxdop = @LogicalCores/2	
END
ELSE IF (@TotalNumaNodes = 2) 
BEGIN
	--Nese caso temos 2 Numa
	--Se cada numa tem 16cores ou menos, teremos sempre maxdop <=8
	IF ((@LogicalCores/@TotalNumaNodes) <= 16) SET @maxdop = @LogicalCores/@TotalNumaNodes/2
	--Para mais de 16cores por Numa, maxdop vai ser 8
	ELSE SET @maxdop = 8
END
ELSE BEGIN
	SET @maxdop = 0;
	THROW 51000, 'Mais de 3 NUMAs, alterar maxdop manualmente.', 1;
END
GO

PRINT 'Setting MAXDOP to ' + CAST(@maxdop AS VARCHAR(64))
DECLARE @ShowAdvOptions VARCHAR(1024)= 'sp_configure ''show advanced options'', 1;'
DECLARE @Reconfigure VARCHAR(64) = 'RECONFIGURE WITH OVERRIDE;'
DECLARE @SetMaxDOP VARCHAR(8000) = 'sp_configure ''max degree of parallelism'', ' + CAST(@maxdop AS VARCHAR(64)) + ';'

EXEC (@ShowAdvOptions)
EXEC (@Reconfigure)
EXEC (@SetMaxDOP)
EXEC (@Reconfigure)
	
/************************/
/*	Setting Max Memory	*/
/************************/
/*
	--https://github.com/bornsql/scripts/blob/main/max_server_memory.sql
	Max Server Memory Calculator
	https://bornsql.ca/memory/
	Copyright (c) BornSQL.ca
	Written by Randolph West, released under the MIT License
	Last updated: 19 June 2020
	Based on an original algorithm by Jonathan Kehayias:
	https://www.sqlskills.com/blogs/jonathan/how-much-memory-does-my-sql-server-actually-need/
	Max Worker Thread Stack calculation based on Tiger Toolbox Maintenance Solution.
	Copyright (c) Microsoft Corporation. All rights reserved.
	https://github.com/Microsoft/tigertoolbox/tree/master/MaintenanceSolution
	SQL Server, on a standalone instance, requires the following reserved RAM for a server:
	- 1 GB of RAM for the OS
	- plus 1 GB for each 4 GB of RAM installed from 4 - 16 GB
	- plus 1 GB for every 8 GB RAM installed above 16 GB RAM
	Memory for the Thread Stack can also be taken into account:
	- 32-bit, reserve 512KB per thread * Max Worker Threads
	- 64-bit, reserve 2MB per thread * Max Worker Threads
	- 128-bit, reserve 4MB per thread * Max Worker Threads
	Thanks to @sqlEmt and @sqlstudent144 for testing.
	Thanks to the Tiger Team for version number and thread stack calculations.
v1.0 - 2016-08-19 - Initial release.
v1.1 - 2016-11-22 - Thread stack reservation; NUMA affinity; new version check.
v1.2 - 2018-09-07 - Removed reference to errant DMV.
v1.3 - 2020-03-17 - Happy St. Patrick's Day.
v1.4 - 2020-06-19 - Fixes to comments and formatting.
*/

-- Set this to 1 if you want to configure NUMA Node Affinity
DECLARE @configureNumaNodeAffinity BIT = 0;

DECLARE @physicalMemorySource DECIMAL(20, 4);
DECLARE @physicalMemory DECIMAL(20, 4);
DECLARE @recommendedMemory DECIMAL(20, 4);
DECLARE @overheadMemory DECIMAL(20, 4);

DECLARE @cpuArchitecture DECIMAL(20, 4);
DECLARE @numaNodes INT;
DECLARE @numaNodesAfinned TINYINT;
DECLARE @maxWorkerThreadCount INT;
DECLARE @threadStack DECIMAL(20, 4);

SELECT @cpuArchitecture = CASE
							  WHEN @@VERSION LIKE '%<X64>%' THEN
								  2
							  WHEN @@VERSION LIKE '%<IA64>%' THEN
								  4
							  ELSE
								  0.5
						  END;
SELECT @numaNodes = COUNT(DISTINCT parent_node_id)
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
	  AND parent_node_id < 64;
SELECT @numaNodesAfinned = COUNT(DISTINCT parent_node_id)
FROM sys.dm_os_schedulers
WHERE scheduler_id < 255
	  AND parent_node_id < 64
	  AND is_online = 1;
SELECT @maxWorkerThreadCount = max_workers_count
FROM sys.dm_os_sys_info;
SELECT @threadStack = @maxWorkerThreadCount * @cpuArchitecture / 1024.0;

-- Get physical RAM on server
SELECT @physicalMemorySource = CAST(total_physical_memory_kb AS DECIMAL(20, 4)) / CAST((1024.0) AS DECIMAL(20, 4))
FROM sys.dm_os_sys_memory;

-- Convert to nearest GB
SELECT @physicalMemory = CEILING(@physicalMemorySource / CAST(1024.0 AS DECIMAL(20, 4)));

IF (@physicalMemory <= 2.0)
BEGIN
	SELECT @overheadMemory = 0.5;
END;

IF (@physicalMemory > 2.0 AND @physicalMemory < 4.0)
BEGIN
	SELECT @overheadMemory = 2.0;
END;

IF (@physicalMemory >= 4.0 AND @physicalMemory <= 16.0)
BEGIN
	SELECT @overheadMemory = 1.0 /* Operating System minimum */
							 + (@physicalMemory / 4.0);
END;

IF (@physicalMemory > 16.0)
BEGIN
	SELECT @overheadMemory = 1.0 /* Operating System minimum */ + 4.0 /* add in reserved for <= 16GB */
							 + ((@physicalMemory - 16.0) / 8.0);
END;

-- Add in the Max Worker Threads Overhead
SELECT @overheadMemory = @overheadMemory + @threadStack;

DECLARE @editionId BIGINT = CAST(SERVERPROPERTY('EditionID') AS BIGINT);
DECLARE @enterprise BIT = 0;
DECLARE @developer BIT = 0;
DECLARE @override BIT = 0;

IF (@editionId IN ( 1804890536, 1872460670, 610778273 ))
BEGIN
	SELECT @enterprise = 1;
END;

IF (@editionId = -2117995310)
BEGIN
	SELECT @developer = 1;
END;

-- Check for Standard Edition Limitations
IF (@enterprise = 0 AND @developer = 0)
BEGIN
	DECLARE @ProductVersion INT = CONVERT(INT, (@@MICROSOFTVERSION / 0x1000000) & 0xff);

	IF (@ProductVersion >= 11)
	   AND (@physicalMemory > 128)
	BEGIN
		SELECT @overheadMemory = 1.0 + 4.0 + ((128 - 16.0) / 8.0);

		-- Set the memory value to the max allowed, if there is enough headroom
		IF (@physicalMemory - @overheadMemory >= 128)
			SELECT @recommendedMemory = 128,
				   @overheadMemory = 0,
				   @override = 1;
	END;

	IF (@ProductVersion < 11)
	   AND (@physicalMemory > 64)
	BEGIN
		SELECT @overheadMemory = 1.0 + 4.0 + ((64 - 16.0) / 8.0);

		-- Set the memory value to the max allowed, if there is enough headroom
		IF (@physicalMemory - @overheadMemory >= 64)
			SELECT @recommendedMemory = 64,
				   @overheadMemory = 0,
				   @override = 1;
	END;
END;

IF (@override = 0)
BEGIN
	SELECT @recommendedMemory = @physicalMemory - @overheadMemory;
END;

-- Configure NUMA Affinity
IF (@configureNumaNodeAffinity = 1)
BEGIN
	SELECT @recommendedMemory = (@recommendedMemory / @numaNodes) * @numaNodesAfinned;
END;

SELECT @@VERSION AS [Version],
	   CASE
		   WHEN (@enterprise = 1) THEN
			   'Enterprise Edition'
		   WHEN (@developer = 1) THEN
			   'Developer Edition'
		   ELSE
			   'Non-Enterprise Edition'
	   END AS [Edition],
	   CAST(@physicalMemorySource AS INT) AS [Physical RAM (MB)],
	   c.[value] AS [Configured Value (MB)],
	   c.[value_in_use] AS [Running Value (MB)],
	   CAST(@recommendedMemory * 1024 AS INT) AS [Recommended Value (MB)],
	   N'EXEC sp_configure ''show advanced options'', 1; RECONFIGURE WITH OVERRIDE; EXEC sp_configure ''max server memory (MB)'', '
	   + CAST(CAST(@recommendedMemory * 1024 AS INT) AS NVARCHAR(20))
	   + '; EXEC sp_configure ''show advanced options'', 0; RECONFIGURE WITH OVERRIDE;' AS [Script]
FROM sys.configurations c
WHERE [c].[name] = N'max server memory (MB)'
OPTION (RECOMPILE);
GO

-- Returning results:
IF (SELECT [value_in_use]
	FROM sys.configurations
	WHERE name like '%max server memory (MB)%') <> @recommendedMemory --@FinalMemory
BEGIN
	PRINT 'Server Memory IN MB: ' + CAST(@PhysicalMemory AS VARCHAR(64))
	PRINT 'Calculated Max Server Memory IN MB: ' + CAST(@@recommendedMemory AS VARCHAR(64))
	PRINT 'Memory Left for SO IN MB: ' + CAST(@PhysicalMemory - @recommendedMemory AS VARCHAR(64))
	PRINT 'Setting Max Memory ... '

	DECLARE @ShowAdvOptions VARCHAR(1024)= 'sp_configure ''show advanced options'', 1;'
	DECLARE @Reconfigure VARCHAR(64) = 'RECONFIGURE;'
	DECLARE @SetMaxMemory VARCHAR(8000) = 'sp_configure ''max server memory'', ' + CAST(@recommendedMemory AS VARCHAR(64)) + ';'

	EXEC (@ShowAdvOptions)
	EXEC (@Reconfigure)
	EXEC (@SetMaxMemory)
	EXEC (@Reconfigure)
END
ELSE PRINT 'Max Memory is OK. Is: ' + CAST(@recommendedMemory AS VARCHAR(64)) + ' MB.'
GO

/****************************************/
/*	Setting MIN and MAX memory equal	*/
/****************************************/
USE [master]
GO
SET NOCOUNT ON

DECLARE @MinMemory INT
DECLARE @MaxMemory INT

SELECT @MaxMemory = CAST([value] AS INT ) FROM sys.configurations WHERE [name] = 'max server memory (MB)'
SELECT @MinMemory = CAST([value] AS INT ) FROM sys.configurations WHERE [name] = 'min server memory (MB)'

IF (@MaxMemory - @MinMemory) <> 0
BEGIN
	PRINT 'MIN memory is not equal to MAX Memory, changing MIN memory to ' + CAST(@MaxMemory AS VARCHAR(16)) + ' ...'
	DECLARE @ShowAdvOptions VARCHAR(1024)= 'sp_configure ''show advanced options'', 1;'
	DECLARE @Reconfigure VARCHAR(64) = 'RECONFIGURE;'
	DECLARE @SetMinMemory VARCHAR(8000) = 'sp_configure ''min server memory'', ' +  CAST(@MaxMemory AS VARCHAR(16)) + ';'

	EXEC (@ShowAdvOptions)
	EXEC (@Reconfigure)
	EXEC (@SetMinMemory)
	EXEC (@Reconfigure)
END
ELSE PRINT 'MAX and MIN memory are equal as ' + CAST(@MaxMemory AS VARCHAR(16)) + '.'
GO
