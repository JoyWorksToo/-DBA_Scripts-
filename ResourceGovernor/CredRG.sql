USE master
GO

--Funcao para classificar quem entra no RG
CREATE FUNCTION dbo.UDF_RG_Classifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
DECLARE @WorkloadGroup AS SYSNAME

	--Todos que nao forem main users do Buy4 vao entrar no RG.
	IF(
		SUSER_NAME() NOT IN ('AcquirerApiAppUser'
						, 'AffiliationHangFireAppUser'
						, 'AffiliationStoneDBUser'
						, 'CaduMembershipAppUser'
						, 'ConciliationAppUser'
						, 'InternalTransferDBAppUser'
						, 'JudicialLockAppUser'
						, 'MerchantBuy4AppUser'
						, 'MonitoraAppUser'
						, 'MovementAppUser'
						, 'PaymentSlipAppUser'
						, 'ReceivablesAdvanceAppUser'
						, 'SettlementAppUser'
						, 'SettlementForwarderAppUser'
						, 'TerminalRentControlAppuser')
		AND SUSER_NAME() LIKE '%User'
		AND IS_SRVROLEMEMBER('sysadmin') <> 1
		)
	SET @WorkloadGroup = 'RG_Group_NotMainUsers'
	
	ELSE
	SET @WorkloadGroup = 'default'
	
	RETURN @WorkloadGroup
END
GO

--Vamos limitar 20% de CPU e MEMORIA
CREATE RESOURCE POOL [RG_Pool_NotMainUsers] 
WITH (
    MIN_CPU_PERCENT=0, 
    MAX_CPU_PERCENT=100, 
    CAP_CPU_PERCENT=20,
    MIN_MEMORY_PERCENT=0, 
    MAX_MEMORY_PERCENT=20, 
    AFFINITY SCHEDULER = AUTO, 
    MIN_IOPS_PER_VOLUME=0, 
    MAX_IOPS_PER_VOLUME=0
)
GO

--Criando o RG Group para a Pool
CREATE WORKLOAD GROUP [RG_Group_NotMainUsers] 
WITH (
    GROUP_MAX_REQUESTS=0, 
    IMPORTANCE=LOW, 
    REQUEST_MAX_CPU_TIME_SEC=0, 
    REQUEST_MAX_MEMORY_GRANT_PERCENT=25, 
    REQUEST_MEMORY_GRANT_TIMEOUT_SEC=0, 
    MAX_DOP=0
) USING [RG_Pool_NotMainUsers]
GO

ALTER RESOURCE GOVERNOR
WITH (CLASSIFIER_FUNCTION=dbo.UDF_RG_Classifier);
GO

ALTER RESOURCE GOVERNOR RECONFIGURE
GO 


--Para dropar o RG 
/*
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
GO
ALTER RESOURCE GOVERNOR DISABLE
GO
DROP FUNCTION dbo.UDF_RG_Classifier
GO
DROP WORKLOAD GROUP [RG_Group_NotMainUsers]
GO
DROP RESOURCE POOL [RG_Pool_NotMainUsers]
GO
ALTER RESOURCE GOVERNOR RECONFIGURE
GO
*/

--Queries para monitorar o RG
SELECT
    A.[name] AS resource_pool,
    COALESCE(SUM(B.total_request_count), 0) AS total_request_count,
    COALESCE(SUM(B.total_cpu_usage_ms), 0) AS total_cpu_usage_ms,
    (CASE WHEN SUM(B.total_request_count) > 0 THEN SUM(B.total_cpu_usage_ms) / SUM(B.total_request_count) ELSE 0 END) AS avg_cpu_usage_ms
FROM
    sys.dm_resource_governor_resource_pools AS A
    LEFT OUTER JOIN sys.dm_resource_governor_workload_groups AS B ON A.pool_id = B.pool_id
GROUP BY
    A.[name]

SELECT
    A.[name] AS resource_pool,
    B.[name] AS workload_group,
    A.total_cpu_usage_ms,
    A.min_cpu_percent,
    A.max_cpu_percent,
    A.cap_cpu_percent,
    A.total_cpu_usage_ms,
    B.total_cpu_limit_violation_count,
    B.total_cpu_usage_ms,
    B.max_request_cpu_time_ms,
    B.request_max_cpu_time_sec
FROM
    sys.dm_resource_governor_resource_pools AS A
    LEFT OUTER JOIN sys.dm_resource_governor_workload_groups AS B ON A.pool_id = B.pool_id


SELECT
    B.[name],
    A.*
FROM 
    sys.dm_exec_sessions AS A WITH (NOLOCK)
    LEFT JOIN sys.dm_resource_governor_workload_groups B ON A.group_id = B.group_id
WHERE 
    A.session_id > 50
    AND A.session_id <> @@SPID
    AND (A.[status] != 'sleeping' OR (A.[status] = 'sleeping' AND A.open_transaction_count > 0))
	
	

select * from sys.resource_governor_configuration
select * from sys.resource_governor_resource_pools
select * from sys.resource_governor_workload_groups

select * from sys.dm_resource_governor_configuration
select * from sys.dm_resource_governor_resource_pools
select * from sys.dm_resource_governor_workload_groups






/********************/

/*Precisa remover a CLASSIFIER_FUNCTION, senão retorna o erro: Cannot alter user-defined function 'UDF_RG_Classifier'. It is being used as a resource governor classifier.*/
ALTER RESOURCE GOVERNOR WITH (CLASSIFIER_FUNCTION = NULL)
GO

--reconfigura o RG
ALTER RESOURCE GOVERNOR RECONFIGURE
GO 

--Altera a função 
ALTER FUNCTION dbo.UDF_RG_Classifier()
RETURNS SYSNAME
WITH SCHEMABINDING
AS
BEGIN
DECLARE @WorkloadGroup AS SYSNAME
	--Todos que nao forem main users do Buy4 vao entrar no RG.
	IF(
		SUSER_NAME() NOT IN ('AcquirerApiAppUser'
						, 'AffiliationHangFireAppUser'
						, 'AffiliationStoneDBUser'
						, 'CaduMembershipAppUser'
						, 'ConciliationAppUser'
						, 'InternalTransferDBAppUser'
						, 'JudicialLockAppUser'
						, 'MerchantBuy4AppUser'
						, 'MonitoraAppUser'
						, 'MovementAppUser'
						, 'PaymentSlipAppUser'
						, 'ReceivablesAdvanceAppUser'
						, 'SettlementAppUser'
						, 'SettlementForwarderAppUser'
						, 'TerminalRentControlAppuser')
		AND SUSER_NAME() LIKE '%User'
		AND IS_SRVROLEMEMBER('sysadmin') <> 1
		)
	SET @WorkloadGroup = 'RG_Group_NotMainUsers'
	
	ELSE
	SET @WorkloadGroup = 'default'
	
	RETURN @WorkloadGroup
END
GO
--altera o RG
ALTER RESOURCE GOVERNOR 
WITH (CLASSIFIER_FUNCTION = dbo.UDF_RG_Classifier)
GO
--Reconfigura
ALTER RESOURCE GOVERNOR RECONFIGURE
GO
