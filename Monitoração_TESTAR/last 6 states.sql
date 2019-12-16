DECLARE @path VARCHAR(MAX)

SELECT @path = CAST(xet.target_data AS xml).value('(/EventFileTarget/File/@name)[1]', 'varchar(max)') 
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
   ON (xe.address = xet.event_session_address)
WHERE xe.name like 'AlwaysOn_health'

	
;WITH cte_HADR AS (SELECT object_name, CONVERT(XML, event_data) AS data
FROM sys.fn_xe_file_target_read_file(@path, null, null, null)
WHERE object_name = 'availability_replica_state_change'
)
 
SELECT TOP 6
	data.value('(/event/data/value)[6]', 'varchar(100)') as [availability_replica_name]
	, data.value('(/event/@timestamp)[1]', 'DATETIME') as [timeStamp]
	, data.value('(/event/data/text)[2]', 'varchar(100)')  as [current_state]
	, data.value('(/event/data/text)[1]', 'varchar(100)') as [previous_state]
FROM cte_HADR
ORDER BY
	data.value('(/event/@timestamp)[1]', 'DATETIME') DESC
