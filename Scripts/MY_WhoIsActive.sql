
SELECT 
	execr.session_id
	--, execr.start_time
	--, execs.last_request_start_time
	--, execs.last_request_end_time
	, CAST(DATEADD(MILLISECOND, execr.total_elapsed_time, 0) AS TIME) AS ElapsedTime
	, execs.original_login_name AS LoginName
	, execr.status
	, DB_NAME(execr.database_id) AS DatabaseName
	, CASE execr.transaction_isolation_level
		WHEN 1 THEN 'ReadUncomitted'
		WHEN 2 THEN 'ReadCommitted'
		WHEN 3 THEN 'Repeatable'
		WHEN 4 THEN 'Serializable'
		WHEN 5 THEN 'Snapshot'
		ELSE 'Unspecified' END 
	  AS transaction_isolation_level
	, sh.text
	, ph.query_plan
	, execr.command
	, execr.wait_type
	, execr.wait_time
	, execr.wait_resource
	, execr.last_wait_type
	, execr.total_elapsed_time
	, execr.open_transaction_count
	, execr.percent_complete
	, execr.estimated_completion_time
	, execs.host_name
	, execs.program_name
	, execs.client_interface_name
FROM sys.dm_exec_sessions AS execs with(nolock)
LEFT JOIN sys.dm_exec_requests execr with(nolock)
	on execr.session_id = execs.session_id
OUTER APPLY sys.dm_exec_sql_text(execr.sql_handle) sh 
OUTER APPLY sys.dm_exec_query_plan(execr.plan_handle) ph
WHERE
	execR.[status] not like 'background'
	AND execR.session_id > 50
	AND execR.command <> 'TASK MANAGER'
order by ElapsedTime desc
go


SELECT
	execs.session_id
	--, execr.start_time
	--, execs.last_request_start_time
	--, execs.last_request_end_time
	, CAST(DATEADD(MILLISECOND, execs.total_elapsed_time, 0) AS TIME) AS ElapsedTime
	--, DATEDIFF(MILLISECOND, execs.last_request_end_time, getdate())
	,execs.last_request_end_time
	, execs.original_login_name AS LoginName
	, execs.status
	, DB_NAME(execs.database_id) AS DatabaseName
	, CASE execr.transaction_isolation_level
		WHEN 1 THEN 'ReadUncomitted'
		WHEN 2 THEN 'ReadCommitted'
		WHEN 3 THEN 'Repeatable'
		WHEN 4 THEN 'Serializable'
		WHEN 5 THEN 'Snapshot'
		ELSE 'Unspecified' END 
	  AS transaction_isolation_level
	, sh.text
	, ph.query_plan
	, execr.command
	, execr.wait_type
	, execr.wait_time
	, execr.wait_resource
	, execr.last_wait_type
	, execs.total_elapsed_time
	, execs.open_transaction_count
	, execr.percent_complete
	, execr.estimated_completion_time
	, execs.host_name
	, execs.program_name
	, execs.client_interface_name
	, execs.*
from sys.dm_exec_sessions AS execs with(nolock)
LEFT JOIN sys.dm_exec_requests execr with(nolock)
	on execr.session_id = execs.session_id
OUTER APPLY sys.dm_exec_sql_text(execr.sql_handle) sh 
OUTER APPLY sys.dm_exec_query_plan(execr.plan_handle) ph
WHERE 
	   (execs.[status] <> 'sleeping') 
	OR (execs.[status] = 'sleeping' and execs.open_transaction_count > 0)
go