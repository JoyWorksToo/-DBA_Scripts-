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
		duration >= 120000000 --by leaving off the event name, you can easily change to capture diff events
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
	duration >= 120000000
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
SET filename='D:\sql_log\LongRunningQuery.xet', metadatafile='D:\sql_log\LongRunningQuery.xem'),

-- Add target for capturing the data - Ring Buffer. Can query while live, or just see how chatty it is
ADD TARGET package0.ring_buffer
(SET max_memory = 4096)
WITH (max_dispatch_latency = 1 SECONDS, TRACK_CAUSALITY = ON)
GO
 
 
-- Enable Event, aka Turn It On
ALTER EVENT SESSION LongRunningQuery ON SERVER
STATE=START
GO