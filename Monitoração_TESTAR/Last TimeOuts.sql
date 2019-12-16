IF OBJECT_ID('tempdb..#result') IS NOT NULL
    DROP TABLE #result

DECLARE @path VARCHAR(MAX)

SELECT @path = CAST(xet.target_data AS xml).value('(/EventFileTarget/File/@name)[1]', 'varchar(max)') 
FROM sys.dm_xe_session_targets AS xet
JOIN sys.dm_xe_sessions AS xe
   ON (xe.address = xet.event_session_address)
WHERE xe.name like 'AlwaysOn_health'

	

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