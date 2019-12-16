
-- Verifica se tem read_only_routing_url
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

	
--prioridade de rota
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
	
ALTER AVAILABILITY GROUP [AG_Name]
 MODIFY REPLICA ON  
N'Instance_name' WITH   
(SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TPC to ReadOnly'));  
-- (SECONDARY_ROLE (READ_ONLY_ROUTING_URL = N'TCP://WSCHAB4DB-01-1.buy4sc.local:31433'));  



--CONFIG PARA ORDER QUANDO A MÁQUINA FOR A PRIMÁRIA

ALTER AVAILABILITY GROUP [AG_Name]
 MODIFY REPLICA ON  
N'Instance_name' WITH  
(PRIMARY_ROLE (READ_ONLY_ROUTING_LIST=('Instance_1','Instance_2', 'Instance_3')));  


  