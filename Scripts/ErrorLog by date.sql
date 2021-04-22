select getdate()

DECLARE @logError TABLE (LogDate DATETIME, ProcessInfo VARCHAR(128), [Text] VARCHAR(max))
INSERT INTO @logError EXEC xp_readerrorlog 0, 1, Null, null, '2021-04-20 17:55:36.900'

SELECT *
FROM @logError
WHERE
	ProcessInfo NOT LIKE 'logon'