DECLARE @Last2Hours DATETIME = DATEADD(HOUR, -2, GETDATE())
DECLARE @logError TABLE (LogDate DATETIME, ProcessInfo VARCHAR(128), [Text] VARCHAR(max))
INSERT INTO @logError EXEC xp_readerrorlog 0, 1, Null, null, @Last2Hours

SELECT *
FROM @logError
WHERE
	ProcessInfo NOT LIKE 'logon'