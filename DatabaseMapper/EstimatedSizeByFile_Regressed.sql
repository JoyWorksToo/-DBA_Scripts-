--Média por arquivo
DECLARE 
	@DatabaseName VARCHAR(128) = NULL
	, @SampleDays INT = 90
	, @BringFiles BIT = 0
	, @help TINYINT = 0
	, @ServerName VARCHAR(128) = 'bo-v-sql1-2p01'
	, @stdt date = '20200501'

DECLARE 
		@endDate DATE = DATEADD(DAY, 1, @stdt)
	, @startDate DATE = DATEADD(DAY, -@sampleDays, @stdt)

DROP TABLE IF EXISTS #FileSizes
SELECT
	a.DatabaseName
	, a.[FileName]
	, FileLocation.FileLocation
	, FileLocation.VolumeDrive
	, FileTotalSpaceMB
	, FileUsedSpaceMB
	, [Date]
INTO #FileSizes
FROM (
	SELECT
		dbs.DatabaseName
		, insDbVol.[FileName]
		, insDbVol.FileTotalSpaceMB
		, CASE WHEN insDbVol.[Type] NOT LIKE 'ROWS' THEN 0 ELSE (insDbVol.FileTotalSpaceMB - insDbVol.FileFreeSpaceMB) END AS FileUsedSpaceMB
		, CAST(insDbVol.SysStart AS DATE) AS [Date]
		, ROW_NUMBER() OVER (PARTITION BY dbs.DatabaseName, insDbVol.FileName, CAST(insDbVol.SysStart AS DATE) ORDER BY insDbVol.SysStart DESC) AS RowNum
	FROM dbo.InstanceDatabaseVolume 
		FOR SYSTEM_TIME FROM @startDate TO @endDate --coloquei uma data no futuro pra pegar o atual tmb 
		AS insDbVol
	INNER JOIN [dbo].[InstanceDatabase] AS insdb
			ON insdb.SQLInstanceId = insDbVol.SQLInstanceId 
			AND insdb.DatabaseId = insDbVol.DatabaseId
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDbVol.SQLInstanceId
	INNER JOIN MyServer AS ser
		ON ins.MyServerId = ser.MyServerId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDbVol.DatabaseId
	WHERE
		ser.Servername = @serverName
		AND insdb.IsActive = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
) AS a
LEFT JOIN (
--esse select aqui é pra pegar o fileLocation
	SELECT
		dbs.DatabaseName
		, insDbVol.[FileName]
		, insDbVol.FileLocation
		, SerVol.VolumeDrive
	FROM dbo.InstanceDatabaseVolume AS insDbVol
	INNER JOIN [dbo].[InstanceDatabase] AS insdb
			ON insdb.SQLInstanceId = insDbVol.SQLInstanceId 
			AND insdb.DatabaseId = insDbVol.DatabaseId
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDbVol.SQLInstanceId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDbVol.DatabaseId
	INNER JOIN ServerVolume AS SerVol
		ON SerVol.ServerVolumeId = insDbVol.ServerVolumeId
	WHERE 
		(dbs.DatabaseName = @DatabaseName OR @DatabaseName IS NULL)
		AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
) AS FileLocation
	ON FileLocation.[FileName] = a.[FileName]
	AND FileLocation.DatabaseName = a.DatabaseName
WHERE
	a.RowNum = 1


--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (@sampleDays + 10)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-2, @startDate)
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;

	
--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #FileSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY DatabaseName, FileName ORDER BY [Date] ASC), DATEADD(DAY, 1, @stdt)) AS NextDate
	--SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY DatabaseName, FileName ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #FileSizes
)
SELECT 
	DatabaseName
	, FileName
	, FileLocation
	, VolumeDrive
	, FileTotalSpaceMB
	, FileUsedSpaceMB
	, c.d AS [Date]
INTO #FileSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);
		

		
DROP TABLE IF EXISTS #FileSizesByDay_Final
SELECT
	  VolumeDrive
	, FileTotalSpaceMB/1024 AS FileTotalSpaceGB
	, (FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC))/1024 AS DIFFFileTotalSpaceGB
	, CASE WHEN (LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC)) = 0 THEN 0 ELSE
		(FileTotalSpaceMB-( LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC))) / (LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC)) END AS GrowthRateTotalSpace
	, FileUsedSpaceMB/1024 AS FileUsedSpaceGB
	, (FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC))/1024 AS DIFFFileUsedSpaceGB
	, CASE WHEN (LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC)) = 0 THEN 0 ELSE 
		(FileUsedSpaceMB-( LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC))) / (LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY VolumeDrive ORDER BY [Date] DESC)) END AS GrowthRateUsedSpace
	, [Date]
	, ROW_NUMBER() OVER (PARTITION BY VolumeDrive ORDER BY Date DESC) AS RowNum
INTO #FileSizesByDay_Final
FROM (
		SELECT
			VolumeDrive
			, SUM(fs.FileTotalSpaceMB) as FileTotalSpaceMB
			, SUM(fs.FileUsedSpaceMB) as FileUsedSpaceMB
			, [Date]
		FROM #FileSizesByDay as fs
		WHERE
			VolumeDrive is not null
			--AND filename not like '%clr_AuthorizationMessage%'
		GROUP BY
			VolumeDrive
			, [Date]
	) AS x

DROP TABLE IF EXISTS #zScore
SELECT
	  VolumeDrive
	, COUNT(*) AS RowQnt
			
	, AVG(DIFFFileTotalSpaceGB) as AVG_DIFFFileTotalSpaceGB
	, STDEV(DIFFFileTotalSpaceGB) AS STDEV_DIFFFileTotalSpaceGB
	, AVG(GrowthRateTotalSpace) AS AVG_GrowthRateTotalSpace
	, STDEV(GrowthRateTotalSpace) AS STDEV_GrowthRateTotalSpace
			
	, AVG(DIFFFileUsedSpaceGB) as AVG_DIFFFileUsedSpaceGB
	, STDEV(DIFFFileUsedSpaceGB) AS STDEV_DIFFFileUsedSpaceGB
	, AVG(GrowthRateUsedSpace) AS AVG_GrowthRateUsedSpace
	, STDEV(GrowthRateUsedSpace) AS STDEV_GrowthRateUsedSpace
INTO #zScore
FROM #FileSizesByDay_Final
GROUP BY
	VolumeDrive

DROP TABLE IF EXISTS #SizeNormalized
SELECT 
	FileSizesByDay.VolumeDrive
	, FileSizesByDay.DIFFFileTotalSpaceGB
	, FileSizesByDay.GrowthRateTotalSpace
	, CASE WHEN zScore.STDEV_DIFFFileTotalSpaceGB = 0 THEN 0 ELSE
		ABS((FileSizesByDay.DIFFFileTotalSpaceGB - zScore.AVG_DIFFFileTotalSpaceGB) / zScore.STDEV_DIFFFileTotalSpaceGB) END AS DIFFFileTotalSpaceGB_Normalized
	, CASE WHEN zScore.STDEV_GrowthRateTotalSpace = 0 THEN 0 ELSE
		ABS((FileSizesByDay.GrowthRateTotalSpace - zScore.AVG_GrowthRateTotalSpace) / zScore.STDEV_GrowthRateTotalSpace) END AS GrowthRateTotalSpace_Normalized
			
	, FileSizesByDay.DIFFFileUsedSpaceGB
	, FileSizesByDay.GrowthRateUsedSpace
	, CASE WHEN zScore.STDEV_DIFFFileUsedSpaceGB = 0 THEN 0 ELSE
		ABS((FileSizesByDay.DIFFFileUsedSpaceGB - zScore.AVG_DIFFFileUsedSpaceGB) / zScore.STDEV_DIFFFileUsedSpaceGB) END AS DIFFFileUsedSpaceGB_Normalized
	, CASE WHEN zScore.STDEV_GrowthRateUsedSpace = 0 THEN 0 ELSE
		ABS((FileSizesByDay.GrowthRateUsedSpace - zScore.AVG_GrowthRateUsedSpace) / zScore.STDEV_GrowthRateUsedSpace) END AS GrowthRateUsedSpace_Normalized
, [Date]
INTO #SizeNormalized
FROM #FileSizesByDay_Final as FileSizesByDay
INNER JOIN #zScore as zScore
	ON FileSizesByDay.VolumeDrive = zScore.VolumeDrive
	

DROP TABLE IF EXISTS #TotalSpaceNormalized
SELECT
	VolumeDrive
	, AVG(DIFFFileTotalSpaceGB) AS DIFFFileTotalSpaceGB
	, CASE WHEN AVG(GrowthRateTotalSpace) > 0.2 THEN 0 ELSE AVG(GrowthRateTotalSpace) END AS GrowthRateTotalSpace
INTO #TotalSpaceNormalized
FROM #SizeNormalized
WHERE
	DIFFFileTotalSpaceGB_Normalized < 2
	AND GrowthRateTotalSpace_Normalized < 2
GROUP BY
	VolumeDrive

DROP TABLE IF EXISTS #UsedSpaceNormalized
SELECT
	VolumeDrive
	, AVG(DIFFFileUsedSpaceGB) AS DIFFFileUsedSpaceGB
	, CASE WHEN AVG(GrowthRateUsedSpace) > 0.2 THEN 0 ELSE AVG(GrowthRateUsedSpace) END AS GrowthRateUsedSpace
INTO #UsedSpaceNormalized 
FROM #SizeNormalized
WHERE
	DIFFFileUsedSpaceGB_Normalized < 2
	AND GrowthRateUsedSpace_Normalized < 2
GROUP BY
	VolumeDrive


SELECT
	Size.VolumeDrive
				
	, Size.FileUsedSpaceGB
	, Used.DIFFFileUsedSpaceGB AS GrowthUsedSpaceByDayGB
	, Used.GrowthRateUsedSpace
	--, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),30) AS EstimatedFileSizeUsedSpaceIn_30_Days
	--, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),90) AS EstimatedFileSizeUsedSpaceIn_90_Days
	--, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),120) AS EstimatedFileSizeUsedSpaceIn_120_Days
			
	, Size.FileTotalSpaceGB
	, Total.DIFFFileTotalSpaceGB AS GrowthTotalSpaceByDayGB
	, Total.GrowthRateTotalSpace
	--, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 30) AS EstimatedFileSizeTotalSpaceIn_30_Days
	--, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 90) AS EstimatedFileSizeTotalSpaceIn_90_Days
	--, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 120) AS EstimatedFileSizeTotalSpaceIn_120_Days
		
	, Size.[Date]

	, CASE WHEN Total.GrowthRateTotalSpace = 0 THEN 19893010 ELSE LOG((VolumeSize.VolumeTotalSpaceGB) / (Size.FileTotalSpaceGB), 1+Total.GrowthRateTotalSpace) END AS PredictedDaysLeft
	, CASE WHEN Total.GrowthRateTotalSpace = 0 THEN 19893010 ELSE LOG((VolumeSize.VolumeTotalSpaceGB-100) / (Size.FileTotalSpaceGB), 1+Total.GrowthRateTotalSpace) END AS PredictedDaysLeft_100GBLeft

FROM #UsedSpaceNormalized AS Used
INNER JOIN #TotalSpaceNormalized AS Total
	ON Used.VolumeDrive = Total.VolumeDrive
INNER JOIN #FileSizesByDay_Final AS Size
	ON Size.VolumeDrive = Used.VolumeDrive
	AND Size.VolumeDrive = Total.VolumeDrive
	AND Size.RowNum = 1
INNER JOIN (
		SELECT ser.Servername, VolumeDrive, VolumeTotalSpaceGB, VolumeFreeSpaceGB
		FROM  Myserver AS ser
		INNER JOIN ServerVolume AS SerVol
			ON ser.MyServerId = SerVol.MyServerId
		WHERE
			servername LIKE @ServerName) AS VolumeSize
	ON VolumeSize.VolumeDrive = size.VolumeDrive
	ORDER BY
	Size.VolumeDrive ASC
GO
