
use master

SELECT 
	ag.name AS ag_name
	, ar.replica_server_name AS ag_replica_server
	, db_name(database_id) AS DatabaseName
	, dr_state.log_send_queue_size AS [Amount of log records not sent (KB)] --Amount of log records of the primary database that has not been sent to the secondary databases, in kilobytes (KB).
	, is_ag_replica_local = CASE
		WHEN ar_state.is_local = 1 THEN N'LOCAL'
		ELSE 'REMOTE'
	 END 
	 , ag_replica_role = CASE
		WHEN ar_state.role_desc IS NULL THEN N'DISCONNECTED'
		ELSE ar_state.role_desc
	 END
	 , log_send_rate AS [Log Send Rate (KB/s)]
	 , CASE WHEN log_send_queue_size = 0 THEN 0
		WHEN log_send_rate = 0 THEN 0
		ELSE CAST(log_send_queue_size / (log_send_rate*1.0) AS NUMERIC(12,3))
		END AS SecToLogSend
	, redo_queue_size
	, redo_rate AS [redo_rate (KB/s)]
	, CASE WHEN redo_queue_size = 0 THEN 0
		WHEN redo_rate = 0 THEN 0
		ELSE CAST(redo_queue_size / (redo_rate*60.0) AS NUMERIC(12,3))
		END AS MinutesToRedoEnd

FROM (( sys.availability_groups AS ag JOIN sys.availability_replicas AS ar ON ag.group_id = ar.group_id )
JOIN sys.dm_hadr_availability_replica_states AS ar_state ON ar.replica_id = ar_state.replica_id)
JOIN sys.dm_hadr_database_replica_states dr_state on
	ag.group_id = dr_state.group_id and dr_state.replica_id = ar_state.replica_id

ORDER BY 3 DESC, 6 ASC


