USE master
GO

:setvar AGName AGNAME
:setvar CurrentPrimary server\instance
:setvar NewPrimary server\instance
:setvar SyncronousServer server\instance


:setvar __IsSqlCmdEnabled "True"
:on error exit

IF N'$(__IsSqlCmdEnabled)' NOT LIKE N'True'
    BEGIN
        PRINT N'SQLCMD mode must be enabled to successfully execute this script.';
		RAISERROR (N'SQLCMD mode must be enabled to successfully execute this script.', 15, 10) WITH NOWAIT
        SET NOEXEC ON;
    END
GO


PRINT 'Validando Variaveis ... '
PRINT ''

PRINT 'Validando nome do AvailabilityGroup $(AGName) ...'
IF (
	SELECT Groups.name
	FROM master.sys.availability_groups Groups
	WHERE
		Groups.name = '$(AGName)'
) = '$(AGName)'
BEGIN 
	PRINT 'AvailabilityGroup $(AGName) existe.'
	PRINT ''
END
ELSE BEGIN
	PRINT 'AvailabilityGroup $(AGName) NAO existe.'
	RAISERROR (N'AvailabilityGroup $(AGName) NAO existe.', 15, 10) WITH NOWAIT
END
GO

PRINT 'Validando replica $(CurrentPrimary) ...'
IF (
	SELECT replica_server_name
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas 
		ON Groups.group_id = Replicas.group_id
	WHERE
		Groups.name = '$(AGName)'
		AND replica_server_name = '$(CurrentPrimary)'
) = '$(CurrentPrimary)'
BEGIN 
	PRINT 'Replica $(CurrentPrimary) existe.'
	PRINT ''
END
ELSE BEGIN
	PRINT 'Replica $(CurrentPrimary) NAO existe.'
	RAISERROR (N'Replica $(CurrentPrimary) NAO existe.', 15, 10) WITH NOWAIT
END
GO

PRINT 'Validando replica $(NewPrimary) ...'
IF (
	SELECT replica_server_name
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas 
		ON Groups.group_id = Replicas.group_id
	WHERE
		Groups.name = '$(AGName)'
		AND replica_server_name = '$(NewPrimary)'
) = '$(NewPrimary)'
BEGIN 
	PRINT 'Replica $(NewPrimary) existe.'
	PRINT ''
END
ELSE BEGIN
	PRINT 'Replica $(NewPrimary) NAO existe.'
	RAISERROR (N'Replica $(NewPrimary) NAO existe.', 15, 10) WITH NOWAIT
END
GO

PRINT 'Validando replica $(SyncronousServer) ...'
IF (
	SELECT replica_server_name
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas 
		ON Groups.group_id = Replicas.group_id
	WHERE
		Groups.name = '$(AGName)'
		AND replica_server_name = '$(SyncronousServer)'
) = '$(SyncronousServer)'
BEGIN 
	PRINT 'Replica $(SyncronousServer) existe.'
	PRINT ''
END
ELSE BEGIN
	PRINT 'Replica $(SyncronousServer) NAO existe.'
	RAISERROR (N'Replica $(SyncronousServer) NAO existe.', 15, 10) WITH NOWAIT
END
GO


PRINT 'Validando se replica $(CurrentPrimary) é primaria ...'
IF (
	SELECT
		States.primary_replica
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.dm_hadr_availability_group_states States 
		ON Groups.group_id = States.group_id
	WHERE
		Groups.name = '$(AGName)'
		AND primary_replica = '$(CurrentPrimary)') = '$(CurrentPrimary)' 
BEGIN
	PRINT 'Replica $(CurrentPrimary) é primaria.'
	PRINT ''
END
ELSE  BEGIN
	PRINT 'Replica $(CurrentPrimary) é secundaria.'
	RAISERROR (N'Replica $(CurrentPrimary) é secundaria, abortando...', 15, 10) WITH NOWAIT
END
GO

PRINT 'Validando se estou na replica primaria ... '
IF (SELECT @@SERVERNAME) = '$(CurrentPrimary)'
BEGIN
	PRINT 'Logado na replica primaria, continuando com os passos...'
END
ELSE BEGIN
	PRINT 'Nao estamos logado na replica primaria, abortando...'
	RAISERROR (N'Nao estamos logado na replica primaria, abortando...', 15, 10) WITH NOWAIT
END
GO


PRINT 'Validando se $(NewPrimary) é sincrona...'
IF (
	SELECT
		[availability_mode] AS [Synchronous]
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas 
		ON Groups.group_id = Replicas.group_id
	INNER JOIN master.sys.dm_hadr_availability_group_states States 
		ON Groups.group_id = States.group_id
	WHERE
		Groups.name = '$(AGName)'
		AND [availability_mode] = 1
		AND replica_server_name = '$(NewPrimary)') = 1
BEGIN
	PRINT 'Replica $(NewPrimary) é sincrona.'
END
ELSE IF ( 
	SELECT COUNT(*)
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas 
		ON Groups.group_id = Replicas.group_id
	INNER JOIN master.sys.dm_hadr_availability_group_states States 
		ON Groups.group_id = States.group_id
	WHERE
		primary_replica <> replica_server_name 
		AND [availability_mode] = 1) < 3
	BEGIN
		PRINT '$(NewPrimary) NAO é sincrona, alterando ... '
		PRINT 'Alterando replica $(NewPrimary) para AVAILABILITY_MODE = SYNCHRONOUS_COMMIT e FAILOVER_MODE = AUTOMATIC. Executando comando:'
		PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);');
		PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (FAILOVER_MODE = AUTOMATIC);');
		EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);');
		EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (FAILOVER_MODE = AUTOMATIC)');
		--RAISERROR ('Comandos executados, aguardando 1 minuto para continuar...', 0,1) WITH NOWAIT
		--WAITFOR DELAY '00:01:00'
		PRINT ''
	END 
	ELSE BEGIN
		PRINT 'Temos mais de duas replicas em modo SYNCHRONOUS_COMMIT, nao e possivel ter mais de 2 replicas nesse modo.'
		RAISERROR (N'Mais de duas replicas em modo SYNCHRONOUS_COMMIT, nao e possivel realizar a operacao.', 15, 10) WITH NOWAIT
	END
GO


:CONNECT $(NewPrimary)
	PRINT ''
	PRINT 'Verificando se a replica $(NewPrimary) esta ok para receber o failover...'
	
	WHILE (
		SELECT
			is_failover_ready
		FROM sys.dm_hadr_database_replica_cluster_states as sts
		INNER JOIN sys.availability_replicas agr
			ON sts.replica_id = agr.replica_id
		INNER JOIN master.sys.availability_groups Groups
			ON Groups.group_id = agr.group_id
		WHERE
			replica_server_name = '$(NewPrimary)'
			AND name = '$(AGName)'
			AND is_failover_ready <> 1) IS NOT NULL
	BEGIN
		
		DECLARE @DBNotReady VARCHAR(8000)

		SELECT @DBNotReady = 'Databases NOT READY: ' + (STUFF((
			SELECT
				', ' + database_name
			FROM sys.dm_hadr_database_replica_cluster_states as sts
			INNER JOIN sys.availability_replicas agr
				ON sts.replica_id = agr.replica_id
			INNER JOIN master.sys.availability_groups Groups
				ON Groups.group_id = agr.group_id
			WHERE
				replica_server_name = '$(NewPrimary)'
				AND name = '$(AGName)'
				AND is_failover_ready <> 1
		FOR XML PATH('')), 1, 1,'') ) + '. Aguardando 1 minuto...'
		
		RAISERROR (@DBNotReady, 0,1) WITH NOWAIT
		WAITFOR DELAY '00:01:00'
	END

	RAISERROR (N'Replica $(NewPrimary) OK para receber o failover. executando comando:', 0,1) WITH NOWAIT
	RAISERROR (N'ALTER AVAILABILITY GROUP [$(AGName)] FAILOVER', 0,1) WITH NOWAIT
	--PRINT ('Replica $(NewPrimary) OK para receber o failover. executando comando:')
	--PRINT ('ALTER AVAILABILITY GROUP [$(AGName)] FAILOVER')
	ALTER AVAILABILITY GROUP [$(AGName)] FAILOVER

	PRINT 'FAILOVER feito com SUCESSO!'
	PRINT ''
GO



:CONNECT $(NewPrimary)
	PRINT 'Alterando replicas para modo ASYNCHRONOUS_COMMIT.'
	
	DECLARE @AGName VARCHAR(128)
	DECLARE @ReplicaName VARCHAR(128)

	DECLARE assyncCursor CURSOR FOR   

		SELECT
			name,
			replica_server_name
		FROM master.sys.availability_groups Groups
		INNER JOIN master.sys.availability_replicas Replicas 
			ON Groups.group_id = Replicas.group_id
		INNER JOIN master.sys.dm_hadr_availability_group_states States 
			ON Groups.group_id = States.group_id
		WHERE
			name = '$(AGName)'
			AND replica_server_name NOT LIKE '$(SyncronousServer)'
			AND replica_server_name NOT LIKE '$(NewPrimary)'

	OPEN assyncCursor FETCH NEXT FROM assyncCursor INTO @AGName, @ReplicaName  
	WHILE @@FETCH_STATUS = 0 BEGIN

		PRINT ''
		PRINT 'Alterando ' + @ReplicaName + ' para modo ASYNCHRONOUS_COMMIT, executando comando:'
		PRINT('ALTER AVAILABILITY GROUP [' + @AGName + '] MODIFY REPLICA ON N''' + @ReplicaName + ''' WITH (FAILOVER_MODE = MANUAL)')
		PRINT('ALTER AVAILABILITY GROUP [' + @AGName + '] MODIFY REPLICA ON N''' + @ReplicaName + ''' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT)')
		EXEC ('ALTER AVAILABILITY GROUP [' + @AGName + '] MODIFY REPLICA ON N''' + @ReplicaName + ''' WITH (FAILOVER_MODE = MANUAL)')
		EXEC ('ALTER AVAILABILITY GROUP [' + @AGName + '] MODIFY REPLICA ON N''' + @ReplicaName + ''' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT)')
		
		PRINT 'Replica ' + @ReplicaName + ' alterada para modo ASYNCHRONOUS_COMMIT com sucesso.'
		
	FETCH NEXT FROM assyncCursor INTO @AGName, @ReplicaName  
	END

	CLOSE assyncCursor  
	DEALLOCATE assyncCursor 

	PRINT ''
	PRINT 'Alterando replica $(SyncronousServer) para modo SYNCHRONOUS_COMMIT, executando comando:'

	PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT)')
	PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (FAILOVER_MODE = AUTOMATIC)')
	EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT)')
	EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (FAILOVER_MODE = AUTOMATIC)')

	PRINT ''

GO


:CONNECT $(NewPrimary)
	--checar de 10 em 10  minutos se o AG esta healthy
	PRINT 'Validando as replicas HEALTHY e NOT_HEALTHY'

	
	DECLARE @HealthyMSG VARCHAR(8000)
	DECLARE @Not_HealthyMSG VARCHAR(8000)
	
	WHILE (
		SELECT TOP 1 1  
		FROM master.sys.availability_groups Groups
		INNER JOIN master.sys.availability_replicas Replicas 
			ON Groups.group_id = Replicas.group_id
		INNER JOIN master.sys.dm_hadr_availability_group_states States 
			ON Groups.group_id = States.group_id
		WHERE
			name = '$(AGName)'
			AND synchronization_health_desc <> 'HEALTHY'
	) IS NOT NULL 
	BEGIN
		
		SELECT @HealthyMSG = 'Replicas HEALTHY: ' + (STUFF((
			SELECT ', ' + replica_server_name
		FROM master.sys.availability_groups Groups
		INNER JOIN master.sys.availability_replicas Replicas 
			ON Groups.group_id = Replicas.group_id
		INNER JOIN master.sys.dm_hadr_availability_group_states States 
			ON Groups.group_id = States.group_id
		WHERE
			name = '$(AGName)'
			AND synchronization_health_desc = 'HEALTHY'
		FOR XML PATH('')), 1, 1,'') )


		SELECT @Not_HealthyMSG = 'Replicas NOT_HEALTHY: ' + (STUFF((
			SELECT ', ' + replica_server_name
		FROM master.sys.availability_groups Groups
		INNER JOIN master.sys.availability_replicas Replicas 
			ON Groups.group_id = Replicas.group_id
		INNER JOIN master.sys.dm_hadr_availability_group_states States 
			ON Groups.group_id = States.group_id
		WHERE
			name = '$(AGName)'
			AND synchronization_health_desc = 'NOT_HEALTHY'
		FOR XML PATH('')), 1, 1,'') )

		PRINT @HealthyMSG
		PRINT @Not_HealthyMSG
		RAISERROR ('Ainda temos Bases NOT_HEALTHY, aguardando 1 minuto para validar novamente', 0,1) WITH NOWAIT
		WAITFOR DELAY '00:01:00'
	END

	
	SELECT @HealthyMSG = 'Todas as Replicas estao HEALTHY: ' + (STUFF((
			SELECT ', ' + replica_server_name
		FROM master.sys.availability_groups Groups
		INNER JOIN master.sys.availability_replicas Replicas 
			ON Groups.group_id = Replicas.group_id
		INNER JOIN master.sys.dm_hadr_availability_group_states States 
			ON Groups.group_id = States.group_id
		WHERE
			name = '$(AGName)'
			AND synchronization_health_desc = 'HEALTHY'
	FOR XML PATH('')), 1, 1,'') ) + '. Proseguindo com os passos...'

	PRINT @HealthyMSG
GO
