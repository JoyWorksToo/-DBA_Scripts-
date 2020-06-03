USE [master]
GO

/****** Object:  DdlTrigger [replicate_logins]    Script Date: 6/3/2020 8:54:27 PM ******/
SET ANSI_NULLS ON
GO

SET QUOTED_IDENTIFIER ON
GO

​
CREATE TRIGGER [replicate_logins]
ON ALL SERVER
FOR CREATE_LOGIN AS
	
	DECLARE @loginName VARCHAR(1000)
	DECLARE @SID VARCHAR(1000)
	DECLARE @password VARCHAR(1000)
	DECLARE @type VARCHAR(1)
	DECLARE @hasaccess int
	DECLARE @denylogin int
	DECLARE @is_disabled int
	DECLARE @is_policy_checked varchar (3)
	DECLARE @is_expiration_checked varchar (3)
	DECLARE @defaultdb sysname
​
	DECLARE @serverName VARCHAR(1000)
	DECLARE @cmd VARCHAR(4000)
	DECLARE @replCmd VARCHAR(4000)
​
	PRINT 'activated "CRATE_LOGIN SERVER TRIGGER" on server ' + @@SERVERNAME
​
	IF (SELECT
			ars.role_desc
		FROM sys.dm_hadr_availability_replica_states ars
		INNER JOIN sys.availability_groups ag
			ON ars.group_id = ag.group_id
		WHERE 
			ars.is_local = 1
			AND role_desc = 'Primary') = 'PRIMARY'
	BEGIN
​
		DECLARE @x xml = eventdata()
​
		SELECT 
			@loginName = T.c.value('(ObjectName/text())[1]', 'nvarchar(128)') ,
			@SID = CONVERT(VARCHAR(1000), T.c.value('(SID/text())[1]', 'varbinary(128)'), 2)
		FROM   @x.nodes('/EVENT_INSTANCE') AS T(c)
​
		SELECT @password = CONVERT(VARCHAR(1000), LOGINPROPERTY(@loginName, 'PasswordHash'), 2)
​
		SELECT 
			@type = p.type
			, @is_disabled = p.is_disabled
			, @defaultdb = p.default_database_name
			, @hasaccess = l.hasaccess
			, @denylogin = l.denylogin 
		FROM sys.server_principals p 
		LEFT JOIN sys.syslogins l
			ON ( l.name = p.name ) 
		WHERE 
			p.type IN ( 'S', 'G', 'U' ) 
			AND p.name = @loginName
​
		IF (@type IN ( 'G', 'U'))
		BEGIN -- NT authenticated account/group
​
			SET @cmd = 'CREATE LOGIN ' + QUOTENAME( @loginName ) + ' FROM WINDOWS WITH DEFAULT_DATABASE = [' + @defaultdb + ']'
​
		END
​
		ELSE BEGIN -- SQL Server authentication
​
			SELECT @is_policy_checked = CASE is_policy_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @loginName
​
			SELECT @is_expiration_checked = CASE is_expiration_checked WHEN 1 THEN 'ON' WHEN 0 THEN 'OFF' ELSE NULL END FROM sys.sql_logins WHERE name = @loginName
 
			SET @cmd = 'CREATE LOGIN ' + QUOTENAME( @loginName ) + ' WITH PASSWORD = 0x' + @password + ' HASHED, SID = 0x' + @SID + ', DEFAULT_DATABASE = [' + @defaultdb + ']'
	
			IF ( @is_policy_checked IS NOT NULL )
			BEGIN
				SET @cmd = @cmd + ', CHECK_POLICY = ' + @is_policy_checked
			END
​
			IF ( @is_expiration_checked IS NOT NULL )
			BEGIN
				SET @cmd = @cmd + ', CHECK_EXPIRATION = ' + @is_expiration_checked
			END
​
		END
​
		IF (@denylogin = 1)
		BEGIN -- login is denied access
		  SET @cmd = @cmd + '; DENY CONNECT SQL TO ' + QUOTENAME( @loginName )
		END
​
		ELSE IF (@hasaccess = 0)
		BEGIN -- login exists but does not have access
		  SET @cmd = @cmd + '; REVOKE CONNECT SQL TO ' + QUOTENAME( @loginName )
		END
​
		IF (@is_disabled = 1)
		BEGIN -- login is disabled
		  SET @cmd = @cmd + '; ALTER LOGIN ' + QUOTENAME( @loginName ) + ' DISABLE'
		END
    
		DECLARE primary_server_cursor CURSOR FAST_FORWARD FOR
			SELECT DISTINCT
				RCS.replica_server_name
			FROM sys.availability_groups_cluster AS AGC
			INNER JOIN sys.dm_hadr_availability_replica_cluster_states AS RCS
				ON RCS.group_id = AGC.group_id
			WHERE RCS.replica_server_name <> @@SERVERNAME
​
		OPEN primary_server_cursor
		FETCH NEXT FROM primary_server_cursor INTO @serverName
		WHILE @@FETCH_STATUS = 0 
		BEGIN
​
			--SET @replCmd = ('sqlcmd -S ' + @serverName + ' -Q "' + @cmd + '" ')
​
			--EXEC master..xp_cmdshell @replCmd, NO_OUTPUT;
​
			PRINT '--REPLICATE USE THIS COMMAND:
				:CONNECT ' + @serverName + '
				' + @cmd + '
				'
​
			FETCH NEXT FROM primary_server_cursor INTO @serverName
		END
​
		CLOSE primary_server_cursor
		DEALLOCATE primary_server_cursor
​
		--PRINT 'created on PRIMARY and REPLICATED to SECONDARY'
​
	END
​
	ELSE BEGIN
​
		PRINT 'LOGIN CREATED ON SECONDARY SERVER'
​
	END

GO

ENABLE TRIGGER [replicate_logins] ON ALL SERVER
GO

