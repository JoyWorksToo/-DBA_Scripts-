
-- Create Event
CREATE EVENT SESSION LongRunningQuery
ON SERVER
-- Add event to capture event
ADD EVENT sqlserver.rpc_completed(
	SET collect_statement=(1)
	-- Add action - event property ; can't add query_hash in R2
    ACTION(
		sqlserver.client_app_name
		,sqlserver.client_hostname
		-- ,sqlserver.client_pid
		,sqlserver.database_name
		,sqlserver.plan_handle
		,sqlserver.query_hash
		,sqlserver.query_plan_hash
		-- ,sqlserver.session_id
		,sqlserver.session_nt_username
		,sqlserver.sql_text
		,sqlserver.tsql_stack
		,sqlserver.username
	-- Predicate - time 1000 milisecond
	)
	WHERE (
		duration >= 1800000000 --by leaving off the event name, you can easily change to capture diff events
		-- AND [sqlserver].[username]='AcquirerApiAppUser'
	)
	
	--by leaving off the event name, you can easily change to capture diff events
),


ADD EVENT sqlserver.sql_statement_completed
-- or do sqlserver.rpc_completed, though getting the actual SP name seems overly difficult
(
	SET collect_parameterized_plan_handle=(1),collect_statement=(1)
	-- Add action - event property ; can't add query_hash in R2
	ACTION(
		sqlserver.client_app_name
		,sqlserver.client_hostname
		-- ,sqlserver.client_pid
		,sqlserver.database_name
		,sqlserver.plan_handle
		,sqlserver.query_hash
		,sqlserver.query_plan_hash
		-- ,sqlserver.session_id
		,sqlserver.session_nt_username
		,sqlserver.sql_text
		,sqlserver.tsql_stack
		,sqlserver.username
	)
	-- Predicate - time 1000 milisecond
	WHERE (
	duration >= 1800000000
	-- AND [sqlserver].[username]='AcquirerApiAppUser'
	)
)

--adding Module_End. Gives us the various SPs called.
--ADD EVENT sqlserver.module_end
--(
--	ACTION (
--		sqlserver.sql_text
--		, sqlserver.tsql_stack
--		, sqlserver.client_app_name
--		, sqlserver.username
--		, sqlserver.client_hostname
--		, sqlserver.session_nt_username
--	)
--	WHERE (
--	duration > 60000000
--	--note that 1 second duration is 1million, and we still need to match it up via the causality
--	)


ADD TARGET package0.event_file(SET filename=N'E:\Events\LongRunningQuery.xel')
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=OFF)
GO