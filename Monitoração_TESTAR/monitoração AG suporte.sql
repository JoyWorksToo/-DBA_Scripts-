-- event alwaysnOn Healty
CREATE EVENT SESSION [AlwaysOn_health] ON SERVER 
ADD EVENT sqlserver.alwayson_ddl_executed,
ADD EVENT sqlserver.availability_group_lease_expired,
ADD EVENT sqlserver.availability_replica_automatic_failover_validation,
ADD EVENT sqlserver.availability_replica_manager_state_change,
ADD EVENT sqlserver.availability_replica_state,
ADD EVENT sqlserver.availability_replica_state_change,
ADD EVENT sqlserver.error_reported(
    WHERE ([error_number]=(9691) OR [error_number]=(35204) OR [error_number]=(9693) OR [error_number]=(26024) OR [error_number]=(28047) OR [error_number]=(26023) OR [error_number]=(9692) OR [error_number]=(28034) OR [error_number]=(28036) OR [error_number]=(28048) OR [error_number]=(28080) OR [error_number]=(28091) OR [error_number]=(26022) OR [error_number]=(9642) OR [error_number]=(35201) OR [error_number]=(35202) OR [error_number]=(35206) OR [error_number]=(35207) OR [error_number]=(26069) OR [error_number]=(26070) OR [error_number]>(41047) AND [error_number]<(41056) OR [error_number]=(41142) OR [error_number]=(41144) OR [error_number]=(1480) OR [error_number]=(823) OR [error_number]=(824) OR [error_number]=(829) OR [error_number]=(35264) OR [error_number]=(35265))),
ADD EVENT sqlserver.hadr_db_partner_set_sync_state,
ADD EVENT sqlserver.lock_redo_blocked 
ADD TARGET package0.event_file(SET filename=N'AlwaysOn_health.xel',max_file_size=(5),max_rollover_files=(4))
WITH (MAX_MEMORY=4096 KB,EVENT_RETENTION_MODE=ALLOW_SINGLE_EVENT_LOSS,MAX_DISPATCH_LATENCY=30 SECONDS,MAX_EVENT_SIZE=0 KB,MEMORY_PARTITION_MODE=NONE,TRACK_CAUSALITY=OFF,STARTUP_STATE=ON)
GO

-- errors descriptions
SELECT * 
 FROM sys.messages m where language_id = 1033 -- English
 --AND m.message_id =1480
AND ([message_id]=(9691) OR [message_id]=(35204) OR [message_id]=(9693) OR [message_id]=(26024) OR [message_id]=(28047) 
    OR [message_id]=(26023) OR [message_id]=(9692) OR [message_id]=(28034) OR [message_id]=(28036) OR [message_id]=(28048) 
    OR [message_id]=(28080) OR [message_id]=(28091) OR [message_id]=(26022) OR [message_id]=(9642) OR [message_id]=(35201) 
    OR [message_id]=(35202) OR [message_id]=(35206) OR [message_id]=(35207) OR [message_id]=(26069) OR [message_id]=(26070) 
    OR [message_id]>(41047) AND [message_id]<(41056) OR [message_id]=(41142) OR [message_id]=(41144) OR [message_id]=(1480) 
    OR [message_id]=(823) OR [message_id]=(824) OR [message_id]=(829) OR [message_id]=(35264) OR [message_id]=(35265))
ORDER BY Message_id

-- path do Healty event
SELECT name, target_name, CAST(xet.target_data AS xml)
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
   ON (xe.address = xet.event_session_address)
WHERE xe.name like 'AlwaysOn_health'

-- extrair o nome direto 
SELECT  CAST(xet.target_data AS xml).value('(/EventFileTarget/File/@name)[1]', 'varchar(max)') 
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
   ON (xe.address = xet.event_session_address)
WHERE xe.name like 'AlwaysOn_health'


-- Events in XML
SELECT CAST(event_data AS XML) AS [EVENT XML]
FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn_health_0_131238952755870000.xel', null, null, null); 

--fields from objects XML

SELECT name, description 
FROM sys.dm_xe_objects 
WHERE NAME IN ( 
'availability_replica_manager_state_change', 
'availability_replica_state', 
'availability_replica_state_change')

select * from sys.dm_xe_object_columns
WHERE OBJECT_NAME IN ( 
'availability_replica_manager_state_change', 
'availability_replica_state', 
'availability_replica_state_change')
AND column_type not like 'readOnly'






SELECT
	[EVENT XML].value('(/event/@name)[1]', 'varchar(100)') as [name]
	, [EVENT XML].value('(/event/@timestamp)[1]', 'DATETIME') as [timeStamp]
	, [EVENT XML].value('(/event/data/text)[1]', 'varchar(100)') as [previous_state]
	, [EVENT XML].value('(/event/data/text)[1]', 'varchar(100)')  as [current_state]
	, [EVENT XML].value('(/event/data/value)[6]', 'varchar(100)') as [availability_replica_name]
	, *
FROM #xml_temp
WHERE
	[EVENT XML].value('(/event/@name)[1]', 'varchar(100)') IN ('availability_replica_state_change')
ORDER BY
	[EVENT XML].value('(/event/@timestamp)[1]', 'DATETIME')
	
	
	
	
	
	
	
;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)
WHERE object_name = 'error_reported'
)
 
SELECT data.value('(/event/@timestamp)[1]','datetime') AS [timestamp],
       data.value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
       data.value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
FROM cte_HADR
WHERE data.value('(/event/data[@name=''error_number''])[1]','int') = 1480





;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)
WHERE object_name = 'availability_replica_state_change'
)
 
SELECT 
	data.value('(/event/@name)[1]', 'varchar(100)') as [name]
	, data.value('(/event/@timestamp)[1]', 'DATETIME') as [timeStamp]
	, data.value('(/event/data/text)[1]', 'varchar(100)') as [previous_state]
	, data.value('(/event/data/text)[2]', 'varchar(100)')  as [current_state]
	, data.value('(/event/data/value)[6]', 'varchar(100)') as [availability_replica_name]
FROM cte_HADR
ORDER BY
	data.value('(/event/@timestamp)[1]', 'DATETIME') DESC




;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)
WHERE object_name = 'availability_replica_state'
)
 
SELECT 
	data.value('(/event/@name)[1]', 'varchar(100)') as [name]
	, data.value('(/event/@timestamp)[1]', 'DATETIME') as [timeStamp]
	, data.value('(/event/data/text)[1]', 'varchar(100)')  as [current_state]
FROM cte_HADR
ORDER BY
	data.value('(/event/@timestamp)[1]', 'DATETIME') DESC


	

	
;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('D:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)
WHERE object_name = 'availability_replica_manager_state_change'
)
 
SELECT 
	data.value('(/event/@name)[1]', 'varchar(100)') as [name]
	, data.value('(/event/@timestamp)[1]', 'DATETIME') as [timeStamp]
	, data.value('(/event/data/text)[1]', 'varchar(100)')  as [current_state]
FROM cte_HADR
ORDER BY
	data.value('(/event/@timestamp)[1]', 'DATETIME') DESC




------------------------ FINAL !!!!!!!!!!!!

DECLARE @path VARCHAR(MAX)

SELECT @path = CAST(xet.target_data AS xml).value('(/EventFileTarget/File/@name)[1]', 'varchar(max)') 
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
   ON (xe.address = xet.event_session_address)
WHERE xe.name like 'AlwaysOn_health'

	
;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file(@path, null, null, null)
WHERE object_name = 'availability_replica_manager_state_change'
)
 
SELECT 
	data.value('(/event/@name)[1]', 'varchar(100)') as [name]
	, data.value('(/event/@timestamp)[1]', 'DATETIME') as [timeStamp]
	, data.value('(/event/data/text)[1]', 'varchar(100)')  as [current_state]
FROM cte_HADR
ORDER BY
	data.value('(/event/@timestamp)[1]', 'DATETIME') DESC








-- connection timeout

	
	
;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file('c:\Program Files\Microsoft SQL Server\MSSQL12.MSSQLSERVER\MSSQL\Log\AlwaysOn*.xel', null, null, null)
WHERE object_name = 'error_reported'
)
 
SELECT data.value('(/event/@timestamp)[1]','datetime') AS [timestamp],
       data.value('(/event/data[@name=''error_number''])[1]','int') AS [error_number],
       data.value('(/event/data[@name=''message''])[1]','varchar(max)') AS [message]
INTO #result
FROM cte_HADR
WHERE data.value('(/event/data[@name=''error_number''])[1]','int') = 35206
ORDER BY data.value('(/event/@timestamp)[1]','datetime') DESC


SELECT 'A connection timeout has occurred on ' + SUBSTRING([message],CHARINDEX('''',[message])+1, CHARINDEX('''',[message],CHARINDEX('''',[message])+1) -CHARINDEX('''',[message])-1) + ' at ' + CAST([timestamp] as varchar(100))
from #result
order by timestamp desc


