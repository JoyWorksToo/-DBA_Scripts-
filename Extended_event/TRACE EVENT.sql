
/*================================================================================================================*/
/*======================================= ACHAR O PATH DO ARQUIVO DO EVENT =======================================*/
/*================================================================================================================*/

-- DECLARE @path VARCHAR(MAX)
-- SELECT @path = CAST(xet.target_data AS xml).value('(/EventFileTarget/File/@name)[1]', 'varchar(max)') 
-- FROM sys.dm_xe_session_targets AS xet
-- JOIN sys.dm_xe_sessions AS xe
   -- ON (xe.address = xet.event_session_address)
-- WHERE xe.name like 'LongRunningQuery'
		-- AND xet.target_name LIKE 'event_file'

-- select @path
/*================================================================================================================*/


WITH events_cte AS (
SELECT
	DATEADD(mi, DATEDIFF(mi, GETUTCDATE(), CURRENT_TIMESTAMP), xevents.event_data.value('(event/@timestamp)[1]', 'datetime2')) AS [event time] ,
	xevents.event_data.value('(event/action[@name="username"]/value)[1]', 'nvarchar(128)') AS [Username],
	xevents.event_data.value('(event/action[@name="database_name"]/value)[1]', 'nvarchar(max)') AS [database name],
	xevents.event_data.value('(event/action[@name="client_hostname"]/value)[1]', 'nvarchar(max)') AS [client host name],
	xevents.event_data.value('(event/data[@name="statement"]/value)[1]', 'VARCHAR(MAX)') AS [statement],
	xevents.event_data.value('(event/action[@name="sql_text"]/value)[1]', 'VARCHAR(MAX)') AS [sql_text],
	xevents.event_data.value('(event/action[@name="plan_handle"]/value)[1]', 'VARCHAR(MAX)') AS [plan_handle],
	xevents.event_data.value('(event/action[@name="query_hash"]/value)[1]', 'VARCHAR(MAX)') AS [query_hash],
	xevents.event_data.value('(event/data[@name="duration"]/value)[1]', 'bigint')  AS [duration (microSecs)],
	xevents.event_data.value('(event/data[@name="cpu_time"]/value)[1]', 'bigint') AS [cpu time (microSecs)],
	xevents.event_data.value('(event/data[@name="physical_reads"]/value)[1]', 'bigint') AS [physical_reads],
	xevents.event_data.value('(event/data[@name="logical_reads"]/value)[1]', 'bigint') AS [logical reads],
	xevents.event_data.value('(event/data[@name="writes"]/value)[1]', 'bigint') AS [writes]
FROM sys.fn_xe_file_target_read_file
('D:\sql_log\LongRunningQuery*.xet', --CASO O PATH ESTIVER ERRADO, RODAR A QUERY DE CIMA E COLOCAR O @path AQUI
 NULL,
null, null)
CROSS APPLY (select CAST(event_data as XML) as event_data) as xevents
)

SELECT
	[event time]
	, [Username]
	, [database name]
	, [client host name]
	, [statement]
	, [sql_text]
	, [plan_handle]
	, [query_hash]
	, [duration (microSecs)] / 60000000.0 AS [duration (Minute)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos
	, [cpu time (microSecs)] / 60000000.0 AS [cpu time (Minute)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos
	-- , [duration (microSecs)] / 1000.0 AS [duration (MiliSecs)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos -- para o autorizador
	-- , [cpu time (microSecs)] / 1000.0 AS [cpu time (MiliSecs)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos -- para o autorizador
	, [physical_reads]
	, [logical reads]
	, [writes]
FROM events_cte
ORDER BY [event time] DESC;




/*====================================================================================================================================*/
/*======================================= PEGAR O TEMPO MÁXIMO DA(S) QUERY(IES) ======================================================*/
/*====================================================================================================================================*/


SELECT
	--[event time]
	 [Username]
	, [database name]
	--, [client host name]
	--, [statement]
	, [sql_text]
	--, [plan_handle]
	--, [query_hash]
	--, [duration (microSecs)] / 60000000.0 AS [duration (Minute)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos
	--, [cpu time (microSecs)] / 60000000.0 AS [cpu time (Minute)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos
	--, [physical_reads]
	--, [logical reads]
	--, [writes]
	, MAX([duration (microSecs)]) / 60000000.0 AS [duration (Minute)] --O tempo é em MicroSegundos, então precisa dividir por 60000000 para pegar o tempo em minutos
FROM #temp
WHERE 1=1
--AND [Username] like 'MerchantBalanceAppUser'
--AND [event time] >= '2016-12-15 00:00:00'
AND [database name] = 'BackOffice'
GROUP BY  [sql_text], [Username], [database name]
ORDER BY 1 DESC;



/*****************/
--Queries que demoram mais que 5 segundos e que não vão nas bases Master, msdb, tempdb e model
--written by MDB and ALM for TheBakingDBA.Blogspot.Com
-- basic XE session creation written by Pinal Dave
-- http://blog.sqlauthority.com/2010/03/29/sql-server-introduction-to-extended-events-finding-long-running-queries/
-- mdb 2015/03/13 1.1 - added a query to the ring buffer's header to get # of events run, more comments
-- mdb 2015/03/13 1.2 - added model_end events, filtering on hostname, using TRACK_CAUSALITY, and multiple events
-- mdb 2015/03/18 1.3 - changed header parse to dynamic, courtesy of Mikael Eriksson on StackOverflow
-- This runs on at 2008++ (tested on 2008, 2008R2, 2012, and 2014). Because of that, no NOT LIKE exclusion
------------------------------
-- Create the Event Session --
------------------------------
 
IF EXISTS(SELECT * FROM sys.server_event_sessions WHERE name='LongRunningQuery')
DROP EVENT SESSION LongRunningQuery ON SERVER
GO
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
		,sqlserver.database_name
		,sqlserver.plan_handle
		,sqlserver.query_hash
		,sqlserver.query_plan_hash
		,sqlserver.session_nt_username
		,sqlserver.sql_text
		,sqlserver.tsql_stack
		,sqlserver.username
	-- Predicate - time 1000 milisecond
	)
	WHERE (
		duration >= 5000000 --by leaving off the event name, you can easily change to capture diff events
		and database_id > 4
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
		,sqlserver.database_name
		,sqlserver.plan_handle
		,sqlserver.query_hash
		,sqlserver.query_plan_hash
		,sqlserver.session_nt_username
		,sqlserver.sql_text
		,sqlserver.tsql_stack
		,sqlserver.username
	)
	-- Predicate - time 1000 milisecond
	WHERE (
	-- duration >= 120.000.000 -- 2 minutos
	duration >= 5000000 
	and database_id > 4
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


-- Add target for capturing the data - XML File
-- You don't need this (pull the ring buffer into temp table),
-- but allows us to capture more events (without allocating more memory to the buffer)
--!!! Remember the files will be left there when done!!!
ADD TARGET package0.asynchronous_file_target(

/*====================================================================
============ AQUI COLOCAR A PASTA ONDE O ARQUIVO VAI FICAR =========
====================================================================*/
SET filename='M:\DataDisks\DataDisk02\MSSQL13.SQL2016\MSSQL\DATA\LongRunningQuery.xet', metadatafile='M:\DataDisks\DataDisk02\MSSQL13.SQL2016\MSSQL\DATA\LongRunningQuery.xem'),

-- Add target for capturing the data - Ring Buffer. Can query while live, or just see how chatty it is
ADD TARGET package0.ring_buffer
(SET max_memory = 4096)
WITH (max_dispatch_latency = 1 SECONDS, TRACK_CAUSALITY = ON)
GO
 
 
-- Enable Event, aka Turn It On
ALTER EVENT SESSION LongRunningQuery ON SERVER
STATE=START
GO