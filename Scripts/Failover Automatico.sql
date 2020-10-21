USE master
GO

:setvar AGName BUY4BOAG
:setvar CurrentPrimary bo-v-sql1-2p02\SQL2016
:setvar NewPrimary bo-v-sql1-1p01\SQL2016
:setvar SyncronousServer bo-v-sql1-1p02\SQL2016

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
		PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);')
		PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (FAILOVER_MODE = AUTOMATIC)')
		--EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT);'
		--EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (FAILOVER_MODE = AUTOMATIC)')
		
		PRINT ''
	END 
	ELSE BEGIN
		PRINT 'Temos mais de duas replicas em modo SYNCHRONOUS_COMMIT, nao e possivel ter mais de 2 replicas nesse modo.'
		RAISERROR (N'Mais de duas replicas em modo SYNCHRONOUS_COMMIT, nao e possivel realizar a operacao.', 15, 10) WITH NOWAIT
	END
GO

print ''
PRINT 'Configurando RoutingList da replica $(NewPrimary) do AG $(AGName) antes de executar o failover ...'
PRINT 'A routing list nao pode conter a replica que é a atual primaria.'

DECLARE @BalancedRout VARCHAR(512)
--Balanceado antes de fazer o failover
--Preciso alterar a routig list da instancia que vai ser primaria: Balancear a instancia do Portal com a que nao seja a atual primaria.
SELECT @BalancedRout = (
	STUFF((SELECT ',' +  '''' + replica_server_name + ''''
		FROM master.sys.availability_groups Groups
		INNER JOIN master.sys.availability_replicas Replicas 
			ON Groups.group_id = Replicas.group_id
		INNER JOIN master.sys.dm_hadr_availability_group_states States 
			ON Groups.group_id = States.group_id
		WHERE
			name like '$(AGName)'
			AND replica_server_name <> '$(NewPrimary)'
			AND primary_replica <> replica_server_name
		FOR XML PATH('')), 1, 1,'') 
)
PRINT 'Executando comando:'
PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=( ('+ @balancedRout +'), ''$(NewPrimary)'' )));')
--EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=( ('+ @balancedRout +'), ''$(NewPrimary)'' )));')

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

	PRINT ('Replica $(NewPrimary) OK para receber o failover. executando comando:')
	PRINT ('--ALTER AVAILABILITY GROUP [$(AGName)] FAILOVER')
	--ALTER AVAILABILITY GROUP [$(AGName)] FAILOVER

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
		--EXEC ('ALTER AVAILABILITY GROUP [' + @AGName + '] MODIFY REPLICA ON N''' + @ReplicaName + ''' WITH (FAILOVER_MODE = MANUAL)')
		--EXEC ('ALTER AVAILABILITY GROUP [' + @AGName + '] MODIFY REPLICA ON N''' + @ReplicaName + ''' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT)')
		
		PRINT 'Replica ' + @ReplicaName + ' alterada para modo ASYNCHRONOUS_COMMIT com sucesso.'
		
	FETCH NEXT FROM assyncCursor INTO @AGName, @ReplicaName  
	END

	CLOSE assyncCursor  
	DEALLOCATE assyncCursor 

	PRINT ''
	PRINT 'Alterando replica $(SyncronousServer) para modo SYNCHRONOUS_COMMIT, executando comando:'

	PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT)')
	PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (FAILOVER_MODE = AUTOMATIC)')
	--EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT)')
	--EXEC ('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(SyncronousServer)'' WITH (FAILOVER_MODE = AUTOMATIC)')

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
		RAISERROR ('Ainda temos Bases NOT_HEALTHY, aguardando 10 minutos para validar novamente', 0,1) WITH NOWAIT
		WAITFOR DELAY '00:10:00'
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

:CONNECT $(CurrentPrimary)
SET NOCOUNT ON
PRINT ''
PRINT 'AG ok, testando todas as bases com select'
PRINT 'Testando AccountControl...'
SELECT TOP 1 'AccountControl pronta para uso.' FROM AccountControl.dbo.Brand
PRINT 'AccountControl pronta para uso.'
PRINT ''
PRINT 'Testando Arena_ChargeBack...'
SELECT TOP 1 'Arena_ChargeBack pronta para uso.' FROM Arena_ChargeBack.DBO.Analyst
PRINT 'Arena_ChargeBack pronta para uso.'
PRINT ''
PRINT 'Testando Buy4_accounting...'
SELECT TOP 1 'Buy4_accounting pronta para uso.' FROM Buy4_accounting.dbo.Invoice
PRINT 'Buy4_accounting pronta para uso.'
PRINT ''
PRINT 'Testando Buy4_clearing...'
SELECT TOP 1 'Buy4_clearing pronta para uso.' FROM Buy4_clearing.dbo.ClearingFile
PRINT 'Buy4_clearing pronta para uso.'
PRINT ''
PRINT 'Testando ClearingAmex...'
SELECT TOP 1 'ClearingAmex pronta para uso.' FROM ClearingAmex.dbo.ClearingFile
PRINT 'ClearingAmex pronta para uso.'
PRINT ''
PRINT 'Testando ClearingElo...'
SELECT TOP 1 'ClearingElo pronta para uso.' FROM ClearingElo.dbo.ClearingFile
PRINT 'ClearingElo pronta para uso.'
PRINT ''
PRINT 'Testando Receivables...'
SELECT TOP 1 'Receivables pronta para uso.' FROM Receivables.dbo.Movement
PRINT 'Receivables pronta para uso.'
PRINT ''
PRINT 'Testando SchemeRepository...'
SELECT TOP 1 'SchemeRepository pronta para uso.' FROM SchemeRepository.visa.Bin
PRINT 'SchemeRepository pronta para uso.'
PRINT ''
PRINT 'Testando Buy4_bo...'
SELECT TOP 1 'Buy4_bo pronta para uso.' FROM Buy4_bo.dbo.AMR_MERCHANT
PRINT 'Buy4_bo pronta para uso.'
PRINT ''
PRINT 'Todas as bases ok!'

GO

:CONNECT $(NewPrimary)
	PRINT 'Configurando RoutingList da replica $(NewPrimary) do AG $(AGName) apos o failover ...'
	PRINT 'A routing list nao pode conter a replica primaria do portal.'

	DECLARE @portal VARCHAR(128)
	SELECT
		@portal = replica_server_name
	FROM master.sys.availability_groups Groups
	INNER JOIN master.sys.availability_replicas Replicas 
		ON Groups.group_id = Replicas.group_id
	INNER JOIN master.sys.dm_hadr_availability_group_states States 
		ON Groups.group_id = States.group_id
	WHERE
		name like 'BUY4SRVAG'
		AND primary_replica = replica_server_name

	DECLARE @BalancedRout VARCHAR(512)
	SELECT @BalancedRout = (
		STUFF((SELECT ',' +  '''' + replica_server_name + ''''
			FROM master.sys.availability_groups Groups
			INNER JOIN master.sys.availability_replicas Replicas 
				ON Groups.group_id = Replicas.group_id
			INNER JOIN master.sys.dm_hadr_availability_group_states States 
				ON Groups.group_id = States.group_id
			WHERE
				name like '$(AGName)'
				AND replica_server_name <> @Portal
				AND primary_replica <> replica_server_name
			FOR XML PATH('')), 1, 1,'') 
	)

	PRINT('ALTER AVAILABILITY GROUP [$(AGName)] MODIFY REPLICA ON N''$(NewPrimary)'' WITH (PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=( ('+ @balancedRout +'), ''$(NewPrimary)'' )));')
	PRINT ''

GO

