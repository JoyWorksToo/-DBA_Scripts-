
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

/************************/
/*	Setting Max Memory	*/
/************************/

------------------------------------------------
-- Itanium is not supported in this calculation!
------------------------------------------------
-- MemToApps and RoomForOS should be manually 
-- specified below.
------------------------------------------------
USE [master]
GO
SET NOCOUNT ON
-- Memory for applications in MB
DECLARE @MemToApps int;
SET @MemToApps= 2048;
-- Memory allocated to the OS in MB
DECLARE @RoomForOS int; 
SET @RoomForOS = 2048;

-- querying max worker threads
DECLARE @WT int
SET @WT = (SELECT [max_workers_count] FROM sys.dm_os_sys_info);
-- querying physical memory
DECLARE @PhysicalMemory int
SET @PhysicalMemory = (SELECT physical_memory_kb / (1024) FROM sys.dm_os_sys_info);
--select @PhysicalMemory
IF OBJECT_ID('tempdb..#memory') IS NOT NULL
	DROP TABLE #memory;

CREATE TABLE #memory
(
	[PhysicalMemory] int,
	[RoomForOS] int,
	[MemToApps] int,
	[WorkerThreadMemory] int,
	[CalculatedMaxServerMemoryMB] int,
	[ConfiguredMaxServerMemoryMB] int,
	[ActiveMaxServerMemoryMB] int
);

-- Memory allocated to other apps than SQL Server.
-- Eg.: antivirus, backups software + 1024 MB for multi-page alocation, sqlxml, etc.
IF EXISTS (SELECT 1 FROM sys.configurations WHERE NAME LIKE '%64%')
BEGIN
	-- 64 bit platform:
	INSERT INTO #memory
	SELECT
		@PhysicalMemory AS [PhysicalMemory], 
		@RoomForOS AS [RoomForOS], 
		@MemToApps AS [MemToApps], 
		CAST((@WT * 2) AS int) AS [WorkerThreadMemory],
		CAST((@PhysicalMemory - @RoomForOS - @MemToApps - (@WT * 2)) AS int) AS [CalculatedMaxServerMemoryMB],
		CAST([value] AS int) AS [ConfiguredMaxServerMemoryMB],
		CAST([value_in_use] AS int) AS [ActiveMaxServerMemoryMB]
	FROM sys.configurations
	WHERE [name] = 'max server memory (MB)';
END
ELSE BEGIN
	-- 32 bit platform:
	INSERT INTO #memory
	SELECT
		@PhysicalMemory AS [PhysicalMemory], 
		@RoomForOS AS [RoomForOS], 
		@MemToApps AS [MemToApps], 
		CAST((@WT * 0.5) AS int) AS [WorkerThreadMemory],
		CAST((@PhysicalMemory - @RoomForOS - @MemToApps - (@WT * 0.5)) AS int) AS [CalculatedMaxServerMemoryMB],
		CAST([value] AS int) AS [ConfiguredMaxServerMemoryMB],
		CAST([value_in_use] AS int) AS [ActiveMaxServerMemoryMB]
	FROM sys.configurations
	WHERE [name] = 'max server memory (MB)';
END

-- Returning results:
DECLARE @FinalMemory INT 
SELECT @FinalMemory = CalculatedMaxServerMemoryMB FROM #memory
	
IF (SELECT [value_in_use]
	FROM sys.configurations
	WHERE name like '%max server memory (MB)%') <> @FinalMemory
BEGIN
	PRINT 'Server Memory IN MB: ' + CAST(@PhysicalMemory AS VARCHAR(64))
	PRINT 'Calculated Max Server Memory IN MB: ' + CAST(@FinalMemory AS VARCHAR(64))
	PRINT 'Memory Left for SO IN MB: ' + CAST(@PhysicalMemory - @FinalMemory AS VARCHAR(64))
	PRINT 'Setting Max Memory ... '

	DECLARE @ShowAdvOptions VARCHAR(1024)= 'sp_configure ''show advanced options'', 1;'
	DECLARE @Reconfigure VARCHAR(64) = 'RECONFIGURE;'
	DECLARE @SetMaxMemory VARCHAR(8000) = 'sp_configure ''max server memory'', ' + CAST(@FinalMemory AS VARCHAR(64)) + ';'

	EXEC (@ShowAdvOptions)
	EXEC (@Reconfigure)
	EXEC (@SetMaxMemory)
	EXEC (@Reconfigure)
END
ELSE PRINT 'Max Memory is OK. Is: ' + CAST(@FinalMemory AS VARCHAR(64)) + ' MB.'
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

