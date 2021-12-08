--Contador de UNDO
SELECT [object_name],
[counter_name],
[cntr_value], * FROM sys.dm_os_performance_counters
WHERE [object_name] LIKE '%Database Replica%'
AND [counter_name] = 'Log remaining for undo'
go



USE master
GO
SELECT 
	ag.name AS ag_name
	, ar.replica_server_name AS Replica_Server
	--, is_ag_replica_local = CASE
	--	WHEN ar_state.is_local = 1 THEN N'LOCAL'
	--	ELSE 'REMOTE'
	-- END 
	, ag_replica_role = CASE
		WHEN ar_state.role_desc IS NULL THEN N'DISCONNECTED'
		ELSE ar_state.role_desc
	 END
	, db_name(database_id) AS DatabaseName
	, dr_state.log_send_queue_size AS [LOG records not sent (KB)] --Amount of log records of the primary database that has not been sent to the secondary databases, in kilobytes (KB).
	, log_send_rate AS [Log Send Rate (KB/s)]
	, CASE WHEN log_send_queue_size = 0 THEN 0
		WHEN log_send_rate = 0 THEN 0
		ELSE CAST(log_send_queue_size / (log_send_rate*1.0) AS NUMERIC(12,3))
		END AS SecToLogEnd
	, dr_state.redo_queue_size as redo_queue_size_KB
	, redo_rate AS [redo_rate (KB/s)]
	, CASE WHEN redo_queue_size = 0 THEN 0
		WHEN redo_rate = 0 THEN 0
		ELSE CAST(redo_queue_size / (redo_rate*60.0) AS NUMERIC(12,3))
		END AS MinutesToRedoEnd
FROM sys.availability_groups AS ag
JOIN sys.availability_replicas AS ar 
	ON ag.group_id = ar.group_id
JOIN sys.dm_hadr_availability_replica_states AS ar_state 
	ON ar.replica_id = ar_state.replica_id
JOIN sys.dm_hadr_database_replica_states dr_state 
	ON ag.group_id = dr_state.group_id AND dr_state.replica_id = ar_state.replica_id
ORDER BY
	--DatabaseName ASC, ag_replica_role ASC
	dr_state.log_send_queue_size + dr_state.redo_queue_size DESC



/* Verifica se tem read_only_routing_url */
select 
	ar.replica_server_name
	, ar.endpoint_url
	, ar.read_only_routing_url
	, secondary_role_allow_connections_desc
	, ars.synchronization_health_desc
	--, *
from sys.availability_replicas ar 
join sys.dm_hadr_availability_replica_states ars 
	on ar.replica_id=ars.replica_id

/* prioridade de rota */
SELECT 
	ag.name as "Availability Group"
	, ar.replica_server_name as "When Primary Replica Is"
	, rl.routing_priority as "Routing Priority"
	, ar2.replica_server_name as "RO Routed To"
	, ar.secondary_role_allow_connections_desc
	, ar2.read_only_routing_url
FROM 
	sys.availability_read_only_routing_lists rl
	inner join sys.availability_replicas ar on rl.replica_id = ar.replica_id
	inner join sys.availability_replicas ar2 on rl.read_only_replica_id = ar2.replica_id
	inner join sys.availability_groups ag on ar.group_id = ag.group_id
ORDER BY 
	ag.name
	, ar.replica_server_name
	, rl.routing_priority

/* Add Routing List URL */
ALTER AVAILABILITY GROUP [AG_Name]
MODIFY REPLICA ON
N'Instance_name' WITH   
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TPC to ReadOnly'));  
-- (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://WSCHAB4DB-01-1.buy4sc.local:31433'));  


/* Add Routing List */
ALTER AVAILABILITY GROUP [AG_Name]
MODIFY REPLICA ON
N'Instance_name' WITH  
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('Instance_1','Instance_2', 'Instance_3')));  


/* Alter AVAILABILITY_MODE */
ALTER AVAILABILITY GROUP [AG_Name]
MODIFY REPLICA ON
N'Instance_name' WITH (AVAILABILITY_MODE = SYNCHRONOUS_COMMIT)
GO
ALTER AVAILABILITY GROUP [AG_Name]
MODIFY REPLICA ON
N'Instance_name' WITH (AVAILABILITY_MODE = ASYNCHRONOUS_COMMIT)
GO

/* Alter FAILOVER_MODE */
ALTER AVAILABILITY GROUP [AG_Name]
MODIFY REPLICA ON
N'Instance_name' WITH (FAILOVER_MODE = MANUAL)
GO

ALTER AVAILABILITY GROUP [AG_Name]
MODIFY REPLICA ON
N'Instance_name' WITH (FAILOVER_MODE = AUTOMATIC)
GO


