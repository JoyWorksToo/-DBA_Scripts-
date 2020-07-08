USE tempdb
GO

CREATE TABLE tempdb.dbo.IdToDelete ([Id] Id NOT NULL PRIMARY KEY)

INSERT INTO tempdb.dbo.IdToDelete ([Id])

SELECT
	Id
FROM
	TableToDelete
GO

WHILE (SELECT TOP 1 1 FROM tempdb.dbo.IdToDelete) IS NOT NULL
BEGIN
    
	SELECT TOP 1000 [Id]
	INTO #EscopoDelete 
	FROM tempdb.dbo.IdToDelete
    
	DELETE B
    FROM #EscopoDelete AS A
    INNER JOIN TableToDelete AS B
        ON A.Id = B.Id
    
	DELETE B
    FROM #EscopoDelete AS A
    INNER JOIN tempdb.dbo.IdToDelete AS B
        ON A.Id = B.Id
	
    DROP TABLE #EscopoDelete
END