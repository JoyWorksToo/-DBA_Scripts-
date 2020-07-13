
--Pegar o tamanho dos arquivos e onde ele ta localizado
DECLARE @dbName VARCHAR(128)-- = 'VillaLobos'
, @startDate DATE = DATEADD(MONTH, -3, GETDATE())
, @endDate DATE = DATEADD(DAY, 1, GETDATE())

DROP TABLE IF EXISTS #FileSizes
SELECT
	a.DatabaseName
	, a.[FileName]
	, FileLocation.FileLocation
	, SUBSTRING(FileLocation.FileLocation, 0, 4) AS DataDisk
	, FileTotalSpaceMB
	, FileUsedSpaceMB
	, [Date]
INTO #FileSizes
FROM (
	SELECT
		dbs.DatabaseName
		, insDbVol.[FileName]
		, MAX(insDbVol.FileTotalSpaceMB) AS FileTotalSpaceMB
		, MAX(insDbVol.FileTotalSpaceMB - insDbVol.FileFreeSpaceMB) AS FileUsedSpaceMB
		, CAST(insDbVol.SysStart AS DATE) AS [Date]
	FROM dbo.InstanceDatabaseVolume 
		FOR SYSTEM_TIME FROM @startDate TO @endDate --coloquei uma data no futuro pra pegar o atual tmb 
		AS insDbVol
	INNER JOIN [dbo].[InstanceDatabase] AS insdb
		 ON insdb.SQLInstanceId = insDbVol.SQLInstanceId 
		 AND insdb.DatabaseId = insDbVol.DatabaseId
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDbVol.SQLInstanceId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDbVol.DatabaseId
	WHERE
		(dbs.DatabaseName = @dbName OR @dbName IS NULL)
		--AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
	GROUP BY
		dbs.DatabaseName
		, insDbVol.[FileName]
		, CAST(insDbVol.SysStart AS DATE)
) AS a
INNER JOIN (
--esse select aqui é pra pegar o ultimo fileLocation porque ao inves de atualizar quando a gente faz movimentação de arquivo, ele insere uma linha nova.
SELECT *
FROM (
	SELECT
		dbs.DatabaseName
		, insDbVol.[FileName]
		, ROW_NUMBER() OVER (PARTITION BY insDbVol.[FileName] ORDER BY insDbVol.SysStart DESC) as RowNo
		, insDbVol.FileLocation
	FROM dbo.InstanceDatabaseVolume AS insDbVol
	INNER JOIN [dbo].[InstanceDatabase] AS insdb
			ON insdb.SQLInstanceId = insDbVol.SQLInstanceId 
			AND insdb.DatabaseId = insDbVol.DatabaseId
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDbVol.SQLInstanceId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDbVol.DatabaseId
	WHERE
		(dbs.DatabaseName = @dbName OR @dbName IS NULL)
		--AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
	GROUP BY
		dbs.DatabaseName,insDbVol.[FileName], insDbVol.SysStart, insDbVol.FileLocation
	) AS x
	WHERE x.RowNo = 1
) AS FileLocation
	ON FileLocation.[FileName] = a.[FileName]


--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (900)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, '20180101')
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;

--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #FileSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #FileSizes
)
SELECT 
	DatabaseName
	, FileName
	, FileLocation
	, DataDisk
	, FileTotalSpaceMB
	, FileUsedSpaceMB
	, c.d AS [Date]
INTO #FileSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);



--Espaço utilizado por cada arquivo, interno e externo, por dia
SELECT
	[FileName]
	, [DataDisk]
	, FileTotalSpaceMB
	, FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY X.[FileName] ORDER BY X.[Date] DESC) AS DIFFFileTotalSpaceMB
	, FileUsedSpaceMB
	, FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY X.[FileName] ORDER BY X.[Date] DESC) AS DIFFFileUsedSpaceMB
	, [Date]
FROM (
	SELECT 
		[FileName]
		, [DataDisk]
		, SUM(FileTotalSpaceMB) AS FileTotalSpaceMB
		, SUM(FileUsedSpaceMB) AS FileUsedSpaceMB
		, [Date]
	FROM #FileSizesByDay
	WHERE
		Date > '20190101'
	GROUP BY
		[FileName]
		, [DataDisk]
		, [Date]
)AS X


--Space By File
SELECT 
	[FileName]
	, [DataDisk]
	, ISNULL(REPLACE(AVG(DIFFFileTotalSpaceMB/1024), '.', ','), '0,0') AS GrowthFileTotalSpaceGBPerDay
	, ISNULL(REPLACE(AVG(DIFFFileUsedSpaceMB/1024), '.', ','), '0,0') AS GrowthFileUsedSpaceGBPerDay
FROM (
	SELECT
		[FileName]
		, [DataDisk]
		, FileTotalSpaceMB
		, FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY X.[FileName] ORDER BY X.[Date] DESC) AS DIFFFileTotalSpaceMB
		, FileUsedSpaceMB
		, FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY X.[FileName] ORDER BY X.[Date] DESC) AS DIFFFileUsedSpaceMB
		, [Date]
	FROM (
		SELECT 
			[FileName]
			, [DataDisk]
			, SUM(FileTotalSpaceMB) AS FileTotalSpaceMB
			, SUM(FileUsedSpaceMB) AS FileUsedSpaceMB
			, [Date]
		FROM #FileSizesByDay
		WHERE
			Date > '20190718'--dateadd(month, -3, getdate())
		GROUP BY
			[FileName]
			, [DataDisk]
			, [Date]
	)AS X
) AS x
GROUP BY
	[FileName]
	, [DataDisk]
ORDER BY
	[FileName]



	/*
	GDFSKJFGHSAJKLFHDSAJKFHDSAJKFHADSJKLHFDSJKLAFGDFSKJFGHSAJKLFHDSAJKFHDSAJKFHADSJKLHFDSJKLAF
	GDFSKJFGHSAJKLFHDSAJKFHDSAJKFHADSJKLHFDSJKLAFGDFSKJFGHSAJKLFHDSAJKFHDSAJKFHADSJKLHFDSJKLAF
	*/
--Espaço utilizado por cada arquivo, interno e externo, por dia




SELECT
	DatabaseName
	, LastDate AS [Date]
	, LastDbSizeTotalSpaceGB AS DBSizeGB
	, GrowthRateTotalSpace	
	, LastDbSizeTotalSpaceGB*POWER((1+GrowthRateTotalSpace),30)  AS EstimatedDbSizeTotalSpaceIn30Days
	, LastDbSizeTotalSpaceGB*POWER((1+GrowthRateTotalSpace),60)  AS EstimatedDbSizeTotalSpaceIn60Days
	, LastDbSizeTotalSpaceGB*POWER((1+GrowthRateTotalSpace),90)  AS EstimatedDbSizeTotalSpaceIn90Days
	, LastDbSizeTotalSpaceGB*POWER((1+GrowthRateTotalSpace),120) AS EstimatedDbSizeTotalSpaceIn120Days
	, LastDbSizeUsedSpaceGB
	, GrowthRateUsedSpace
	, LastDbSizeUsedSpaceGB*POWER((1+GrowthRateUsedSpace),30)  AS EstimatedDbSizeUsedSpaceIn30Days
	, LastDbSizeUsedSpaceGB*POWER((1+GrowthRateUsedSpace),60)  AS EstimatedDbSizeUsedSpaceIn60Days
	, LastDbSizeUsedSpaceGB*POWER((1+GrowthRateUsedSpace),90)  AS EstimatedDbSizeUsedSpaceIn90Days
	, LastDbSizeUsedSpaceGB*POWER((1+GrowthRateUsedSpace),120) AS EstimatedDbSizeUsedSpaceIn120Days
	, DIFFFileTotalSpaceGB
	, DIFFFileUsedSpaceGB
FROM(
	SELECT
		DatabaseName
		, AVG(DIFFFileTotalSpaceGB) AS DIFFFileTotalSpaceGB
		, AVG(GrowthRateTotalSpace) AS GrowthRateTotalSpace
		, AVG(DIFFFileUsedSpaceGB)  AS DIFFFileUsedSpaceGB
		, CASE WHEN AVG(GrowthRateUsedSpace) > 1 THEN AVG(GrowthRateTotalSpace) ELSE AVG(GrowthRateUsedSpace) END AS GrowthRateUsedSpace
	FROM (
		SELECT
				DatabaseName
			, FileTotalSpaceMB/1024 AS FileTotalSpaceGB
			, (FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))/1024 AS DIFFFileTotalSpaceGB
			, (FileTotalSpaceMB-( LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))  AS GrowthRateTotalSpace
			, FileUsedSpaceMB/1024 AS FileUsedSpaceGB
			, (FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))/1024 AS DIFFFileUsedSpaceGB
			, (FileUsedSpaceMB-( LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))  AS GrowthRateUsedSpace
			, [Date]
		FROM (
			SELECT 
				DatabaseName
				, SUM(FileTotalSpaceMB) AS FileTotalSpaceMB
				, SUM(FileUsedSpaceMB) AS FileUsedSpaceMB
				, [Date]
			FROM #FileSizesByDay
			WHERE
				Date > dateadd(month, -3, getdate())
			GROUP BY
				DatabaseName
				, [Date]
		)AS GroupingByDatabase
	) AS X
	GROUP BY
		X.DatabaseName
) AS AVGs
CROSS APPLY (
	SELECT TOP 1
		SUM(FileTotalSpaceMB)/1024 AS LastDbSizeTotalSpaceGB
		, SUM(FileUsedSpaceMB)/1024 AS LastDbSizeUsedSpaceGB
		, [Date] AS LastDate
	FROM #FileSizesByDay AS inside
	WHERE
		inside.DatabaseName = AVGs.DatabaseName
	GROUP BY
		[Date]
	ORDER BY 
		inside.[Date] DESC
) AS LastDbSize	
order by DBSizeGB DESC






--Crescimento dos dataDisks por dia
SELECT
	DataDisk
	, FileTotalSpaceGB
	, [Date]
	, FileTotalSpaceGB - LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY X.DataDisk ORDER BY X.[Date] DESC) AS DIFFDataSizeGB
FROM (
	SELECT 
		DataDisk
		, SUM(FileTotalSpaceMB)/(1024) AS FileTotalSpaceGB
		, [Date]
	FROM #FileSizesByDay
	WHERE
		Date > dateadd(month, -3, getdate())
	GROUP BY
		DataDisk
		, [Date]
	) AS X

	
--Crescimento médio por DataDisk
SELECT DataDisk, AVG(DIFFDataSizeMB) 
FROM (
	SELECT
		DataDisk
		, FileTotalSpaceTB
		, [Date]
		, FileTotalSpaceTB - LEAD(FileTotalSpaceTB, 1, NULL) OVER (PARTITION BY X.DataDisk ORDER BY X.[Date] DESC) AS DIFFDataSizeMB
	FROM (
		SELECT 
			DataDisk
			, SUM(FileTotalSpaceMB)/(1024*1024) AS FileTotalSpaceTB
			, [Date]
		FROM #FileSizesByDay
		WHERE
			Date > '20190101'
		GROUP BY
			DataDisk
			, [Date]
	)AS X
) AS x
GROUP BY
	DataDisk

--SpaceUsedInsideFile
SELECT DataDisk, REPLACE(AVG(DIFFDataSizeGB), '.', ',') AS DIFFDataSizeMB
FROM (
	SELECT
		DataDisk
		, [FileName]
		, FileUsedSpaceMB
		, [Date]
		, (FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY X.DataDisk ORDER BY X.[Date] DESC))/1024 AS DIFFDataSizeGB
	FROM (
		SELECT 
			DataDisk
			, [FileName]
			, SUM(FileUsedSpaceMB) AS FileUsedSpaceMB
			, [Date]
		FROM #FileSizesByDay
		WHERE
			Date > '20190101'
		GROUP BY
			DataDisk
			, [FileName]
			, [Date]
	)AS x
WHERE
	Date >= '2019-07-19'
) AS x
GROUP BY
	DataDisk

	
	