/*
--Antigo
--CREATE TABLE master.dbo.FileSize (FileName VARCHAR(128), SizeMB DECIMAL(12,2), file_size_mb decimal(12,2), FreeSpaceInPages int, free_space_MB decimal(12,2), GetTime datetime)
--use buy4_bo
--go

----INSERT INTO master.dbo.FileSize 
select 
	name
	, CAST(size AS BIGINT) *8./1024. AS SizeMB
	--, CAST(size AS BIGINT) *8/1024 + 1024
	, convert(decimal(12,2),round(sysfiles.size/128.,2)) as file_size_MB
	--, convert(decimal(12,2),round(fileproperty(sysfiles.name,'SpaceUsed')/128.,2)) as space_used_MB
	, sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed') AS FreSpaceInPages
	, convert(decimal(12,2),round((sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed'))/128.,2)) as free_space_MB
	--, CONVERT(DECIMAL(10,2),((sysfiles.SIZE/128.0 - CAST(FILEPROPERTY(sysfiles.NAME, 'SPACEUSED') AS INT)/128.0)/(sysfiles.SIZE/128.0))*100) AS [FreeSpace_%] 
	, GETDATE() AS GetTime
	, ' DATABASE [Buy4_bo] MODIFY FILE ( NAME = N''' + name + ''', SIZE = ' + CAST(CAST(size AS BIGINT) *8/1024 + 1024 AS VARCHAR(128)) + 'MB )'
from sys.sysfiles
where
	name like 'dbo_AMR_MOVEMENT_Index_FgNext%'
	or name like 'dbo_AMR_MOVEMENT_FgNext%'
	or name like 'dbo_ATX_CONFIRMED_TRANSACTION_FgNext%'
	or name like 'dbo_ATX_CONFIRMED_TRANSACTION_Index_FgNext%'
	or name like 'clr_AuthorizationMessage_Fg01%'

select *
from master.dbo.FileSize where
	filename like 'clr_%'
order by  gettime
go
select *
from master.dbo.FileGrowth 
go



select 
	name
	, CAST(size AS BIGINT) *8./1024. AS SizeMB
	, CAST(size AS BIGINT) *8/1024 + 1024
	, *
	
from sys.sysfiles
















--
--CREATE TABLE master.dbo.FileGrowth (StartTime datetime, EventName varchar(128), databaseName varchar(128), [FileName] varchar(128), GrowthMB decimal(18,3), DurMs int, SessionLoginName varchar(128), CONSTRAINT [PK_FileGrowth] PRIMARY KEY (StartTime, [FileName]))

DROP TABLE IF EXISTS #Growth 

CREATE TABLE #Growth (StartTime datetime, EventName varchar(128), databaseName varchar(128), [FileName] varchar(128), GrowthMB decimal(18,3), DurMs int)

DECLARE @filename NVARCHAR(1000);
DECLARE @bc INT;
DECLARE @ec INT;
DECLARE @bfn VARCHAR(1000);
DECLARE @efn VARCHAR(10);
 
-- Get the name of the current default trace
SELECT @filename = CAST(value AS NVARCHAR(1000))
FROM ::fn_trace_getinfo(DEFAULT)
WHERE traceid = 1 AND property = 2;
 
-- rip apart file name into pieces
SET @filename = REVERSE(@filename);
SET @bc = CHARINDEX('.',@filename);
SET @ec = CHARINDEX('_',@filename)+1;
SET @efn = REVERSE(SUBSTRING(@filename,1,@bc));
SET @bfn = REVERSE(SUBSTRING(@filename,@ec,LEN(@filename)));
 
-- set filename without rollover number
SET @filename = @bfn + @efn
 
-- process all trace files

SELECT 
  ftg.StartTime
,te.name AS EventName
,DB_NAME(ftg.databaseid) AS DatabaseName  
,ftg.Filename
,(ftg.IntegerData*8)/1024.0 AS GrowthMB 
,(ftg.duration/1000)AS DurMS
, SessionLoginName
FROM ::fn_trace_gettable(@filename, DEFAULT) AS ftg 
INNER JOIN sys.trace_events AS te ON ftg.EventClass = te.trace_event_id  
WHERE (ftg.EventClass = 92  -- Date File Auto-grow
    OR ftg.EventClass = 93) -- Log File Auto-grow
ORDER BY ftg.StartTime


select *
from master.dbo.FileGrowth
where
	databasename = 'buy4_bo'
ORDER BY
	FileName ASC
	, 
	StartTime asc
	
	
	
  DATABASE [Buy4_bo] MODIFY FILE ( NAME = N'dbo_AMR_MOVEMENT_FgNext_F01', SIZE = MB )
2014163
2011603.00


Rodar comando get-WindowsUpdate e verificar se hรก update pendente. Caso sim:
rodar: Install-WindowsUpdate   .                       
Reiniciar VM .
Voltar ao passo (1).


*/

DECLARE
	@DatabaseName VARCHAR(128) = 'Buy4_bo'
	, @SampleDays INT = 60
	, @BringFiles BIT = 0
	, @help TINYINT = 0

--Pegar o tamanho dos arquivos e onde ele ta localizado
	DECLARE 
		  @endDate DATE = DATEADD(DAY, 1, GETDATE())
		, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())

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
		INNER JOIN MyDatabases AS dbs 
			ON dbs.DatabaseId = insDbVol.DatabaseId
		WHERE
			(dbs.DatabaseName = @DatabaseName OR @DatabaseName IS NULL)
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
		SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY DatabaseName, FileName ORDER BY [Date] ASC), DATEADD(DAY, 1, CAST(GETDATE() AS DATE))) AS NextDate
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

----------------------------------------
DROP TABLE IF EXISTS #FileSizesByDay_2
SELECT 
	FileName,
	FileTotalSpaceMB AS SizeMB,
	FileUsedSpaceMB AS UsedSpaceMB,
	Date AS GetTime
INTO #FileSizesByDay_2
FROM #FileSizesByDay

DROP TABLE IF EXISTS #LastDataCollected
SELECT FileName, UsedSpaceMB, SizeMB, GetTime
INTO #LastDataCollected
FROM (
	SELECT *
		, ROW_NUMBER() OVER (PARTITION BY FileName ORDER BY GetTime DESC) AS RowNo
	FROM #FileSizesByDay_2
	WHERE
		GetTime >= DATEADD(DD, -15, GETDATE())
) AS x
WHERE
	X.RowNo = 1

DROP TABLE IF EXISTS #DiffSizeByDay
SELECT 
	FileName
	, SizeMB - LEAD(SizeMB, 1, null) OVER(PARTITION BY FileName ORDER BY GetTime DESC) AS DIFF_Size
	, UsedSpaceMB - LEAD(UsedSpaceMB, 1, null) OVER(PARTITION BY FileName ORDER BY GetTime DESC) AS DIFF_FileUsedSpaceMB
	--, (SizeMB- (LEAD(SizeMB, 1, null) OVER(PARTITION BY FileName ORDER BY GetTime DESC))) / (LEAD(SizeMB, 1, null) OVER(PARTITION BY FileName ORDER BY GetTime DESC)) as GrowthRate
INTO #DiffSizeByDay
FROM (
	SELECT 
		FileName
		, MAX(SizeMB) AS SizeMB
		, MAX(UsedSpaceMB) as UsedSpaceMB
		, CAST(GetTime AS DATE) AS GetTime
	FROM #FileSizesByDay_2
	WHERE
		GetTime >= DATEADD(DD, -15, GETDATE())
	--WHERE
	--	FileName like 'dbo_BUY4_RECEIVABLES_ADVANCE_HOT_DATA_Fg01_F01%'
	GROUP BY 
		FileName, CAST(GetTime AS DATE) 
) AS x

DROP TABLE IF EXISTS #ZScore 
SELECT 
	FileName
	, COUNT(*) as CNT
	, AVG(DIFF_Size) AS AVG_DIFF_SIZE
	, STDEV(DIFF_Size) AS STDEV_DIFF_SIZE
	, AVG(DIFF_FileUsedSpaceMB) AS AVG_DIFF_FileUsedSpaceMB
	, STDEV(DIFF_FileUsedSpaceMB) AS STDEV_DIFF_FileUsedSpaceMB
INTO #ZScore
FROM #DiffSizeByDay
WHERE
	DIFF_Size IS NOT NULL
GROUP BY 
	FileName
--HAVING SUM(DIFF_Size) > 0

--SELECT *
--FROM #FileSizesByDay_2
--WHERE
--FILENAME = 'dbo_AMR_MOVEMENT_Fg06_F01'
--ORDER BY GetTime ASC

SELECT *
FROM #ZScore
ORDER BY 1 ASC
--WHERE
--	FileName = 'sett_Index_FG_F04'

DROP TABLE IF EXISTS #SizeNormalized
SELECT
	F.FileName
	, F.DIFF_Size
	, F.DIFF_FileUsedSpaceMB
	--, F.GrowthRate
	, CASE WHEN Z.STDEV_DIFF_SIZE = 0 THEN 0 ELSE (ABS((F.DIFF_Size - Z.AVG_DIFF_SIZE ) / Z.STDEV_DIFF_SIZE)) END AS DIFF_NORMALIZED
	, CASE WHEN Z.STDEV_DIFF_FileUsedSpaceMB = 0 THEN 0 ELSE (ABS((F.DIFF_FileUsedSpaceMB - Z.AVG_DIFF_FileUsedSpaceMB ) / Z.STDEV_DIFF_FileUsedSpaceMB)) END AS DIFF_FileUsedSpaceMB_NORMALIZED
	--, ABS((F.GrowthRate - Z.AVG_GrowthRate ) / Z.STDEV_GrowthRate) AS GROWTH_NORMALIZED
INTO #SizeNormalized
FROM #DiffSizeByDay AS F
JOIN #ZScore AS Z
	ON Z.FileName = F.FileName


SELECT *
FROM #SizeNormalized
ORDER BY 1 ASC

DROP TABLE IF EXISTS #diff_size, #diff_UsedSize
select 
	FileName, AVG(DIFF_Size) AS AVG_DIFF_Size_MB
INTO #diff_size
from #SizeNormalized
WHERE
	DIFF_NORMALIZED < 2
	AND DIFF_Size IS NOT NULL
GROUP BY 
	FileName
HAVING 
	AVG(DIFF_Size) > 0
ORDER BY 
	FileName ASC

select 
	FileName, AVG(DIFF_FileUsedSpaceMB) AS AVG_DIFF_FileUsedSpaceMB
INTO #diff_UsedSize
from #SizeNormalized
WHERE
	DIFF_FileUsedSpaceMB_NORMALIZED < 2
	AND DIFF_FileUsedSpaceMB IS NOT NULL
GROUP BY 
	FileName
HAVING 
	AVG(DIFF_FileUsedSpaceMB) > 0
ORDER BY 
	FileName ASC

SELECT *
FROM (
	SELECT *
		, ROW_NUMBER() OVER (PARTITION BY FileName ORDER BY GetTime DESC) AS RowNo
	FROM #FileSizesByDay_2
) AS x
WHERE
	X.RowNo = 1

SELECT *
FROM #diff_size AS fs
FULL OUTER JOIN #diff_UsedSize AS Us
ON fs.FileName = us.FileName
ORDER BY 3 ASC

SELECT
	Actual.FileName
	, Actual.GetTime
	, Actual.SizeMB
	, Actual.UsedSpaceMB
	, Actual.SizeMB - Actual.UsedSpaceMB AS FreeSpaceMB
	, Used.AVG_DIFF_FileUsedSpaceMB
	, CASE WHEN 2*(Actual.SizeMB - Actual.UsedSpaceMB) < Used.AVG_DIFF_FileUsedSpaceMB THEN 1 ELSE 0 END AS ToGrowth
FROM #LastDataCollected AS Actual
INNER JOIN #diff_UsedSize AS Used
	ON Actual.FileName = Used.FileName
WHERE
	2*(Actual.SizeMB - Actual.UsedSpaceMB) < Used.AVG_DIFF_FileUsedSpaceMB 
ORDER BY AVG_DIFF_FileUsedSpaceMB DESC





--	;WITH FileSizesByDay AS (
--		SELECT
--			  DatabaseName
--			, FileTotalSpaceMB/1024 AS FileTotalSpaceGB
--			, (FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))/1024 AS DIFFFileTotalSpaceGB
--			, (FileTotalSpaceMB-( LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))  AS GrowthRateTotalSpace
--			, FileUsedSpaceMB/1024 AS FileUsedSpaceGB
--			, (FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))/1024 AS DIFFFileUsedSpaceGB
--			, (FileUsedSpaceMB-( LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))  AS GrowthRateUsedSpace
--			, [Date]
--			, ROW_NUMBER() OVER (PARTITION BY DatabaseName ORDER BY Date DESC) AS RowNum
--		FROM (
--			SELECT 
--				DatabaseName
--				, SUM(FileTotalSpaceMB) AS FileTotalSpaceMB
--				, SUM(FileUsedSpaceMB) AS FileUsedSpaceMB
--				, [Date]
--			FROM #FileSizesByDay
--			GROUP BY
--				DatabaseName
--				, [Date]
--		)AS GroupingByDatabase
--	),
--	zScore AS (
--		SELECT
--			  DatabaseName
--			, COUNT(*) AS RowQnt
			
--			, AVG(DIFFFileTotalSpaceGB) as AVG_DIFFFileTotalSpaceGB
--			, STDEV(DIFFFileTotalSpaceGB) AS STDEV_DIFFFileTotalSpaceGB
--			, AVG(GrowthRateTotalSpace) AS AVG_GrowthRateTotalSpace
--			, STDEV(GrowthRateTotalSpace) AS STDEV_GrowthRateTotalSpace
			
--			, AVG(DIFFFileUsedSpaceGB) as AVG_DIFFFileUsedSpaceGB
--			, STDEV(DIFFFileUsedSpaceGB) AS STDEV_DIFFFileUsedSpaceGB
--			, AVG(GrowthRateUsedSpace) AS AVG_GrowthRateUsedSpace
--			, STDEV(GrowthRateUsedSpace) AS STDEV_GrowthRateUsedSpace
--		FROM FileSizesByDay
--		GROUP BY
--			DatabaseName 
--	),
--	SizeNormalized AS (
--		SELECT 
--			FileSizesByDay.DatabaseName
--			, FileSizesByDay.DIFFFileTotalSpaceGB
--			, FileSizesByDay.GrowthRateTotalSpace
--			, CASE WHEN zScore.STDEV_DIFFFileTotalSpaceGB = 0 THEN 0 ELSE
--				ABS((FileSizesByDay.DIFFFileTotalSpaceGB - zScore.AVG_DIFFFileTotalSpaceGB) / zScore.STDEV_DIFFFileTotalSpaceGB) END AS DIFFFileTotalSpaceGB_Normalized
--			, CASE WHEN zScore.STDEV_GrowthRateTotalSpace = 0 THEN 0 ELSE
--				ABS((FileSizesByDay.GrowthRateTotalSpace - zScore.AVG_GrowthRateTotalSpace) / zScore.STDEV_GrowthRateTotalSpace) END AS GrowthRateTotalSpace_Normalized
			
--			, FileSizesByDay.DIFFFileUsedSpaceGB
--			, FileSizesByDay.GrowthRateUsedSpace
--			, CASE WHEN zScore.STDEV_DIFFFileUsedSpaceGB = 0 THEN 0 ELSE
--				ABS((FileSizesByDay.DIFFFileUsedSpaceGB - zScore.AVG_DIFFFileUsedSpaceGB) / zScore.STDEV_DIFFFileUsedSpaceGB) END AS DIFFFileUsedSpaceGB_Normalized
--			, CASE WHEN zScore.STDEV_GrowthRateUsedSpace = 0 THEN 0 ELSE
--				ABS((FileSizesByDay.GrowthRateUsedSpace - zScore.AVG_GrowthRateUsedSpace) / zScore.STDEV_GrowthRateUsedSpace) END AS GrowthRateUsedSpace_Normalized
--		, [Date]
--		FROM FileSizesByDay
--		INNER JOIN zScore
--			ON FileSizesByDay.DatabaseName = zScore.DatabaseName
--	),
--	TotalSpaceNormalized AS (
--		SELECT
--			DatabaseName
--			, AVG(DIFFFileTotalSpaceGB) AS DIFFFileTotalSpaceGB
--			, CASE WHEN AVG(GrowthRateTotalSpace) > 0.2 THEN 0 ELSE AVG(GrowthRateTotalSpace) END AS GrowthRateTotalSpace
--		FROM SizeNormalized
--		WHERE
--			DIFFFileTotalSpaceGB_Normalized < 2
--			AND GrowthRateTotalSpace_Normalized < 2
--		GROUP BY
--			DatabaseName
--	),
--	UsedSpaceNormalized AS (
--		SELECT
--			DatabaseName
--			, AVG(DIFFFileUsedSpaceGB) AS DIFFFileUsedSpaceGB
--			, CASE WHEN AVG(GrowthRateUsedSpace) > 0.2 THEN 0 ELSE AVG(GrowthRateUsedSpace) END AS GrowthRateUsedSpace
--		FROM SizeNormalized
--		WHERE
--			DIFFFileUsedSpaceGB_Normalized < 2
--			AND GrowthRateUsedSpace_Normalized < 2
--		GROUP BY
--			DatabaseName
--	)
--	SELECT
--		Size.DatabaseName
		
--		, Size.FileUsedSpaceGB AS DatabaseUsedSpaceSize
--		, Used.DIFFFileUsedSpaceGB AS GrowthUsedSpaceByDayGB
--		, Used.GrowthRateUsedSpace
--		, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),30) AS EstimatedDbSizeUsedSpaceIn_30_Days
--		, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),90) AS EstimatedDbSizeUsedSpaceIn_90_Days
--		, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),120) AS EstimatedDbSizeUsedSpaceIn_120_Days
--		, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),360) AS EstimatedDbSizeUsedSpaceIn_360_Days
		
--		, Size.FileTotalSpaceGB AS DatabaseTotalSize
--		, Total.DIFFFileTotalSpaceGB AS GrowthTotalSpaceByDayGB
--		, Total.GrowthRateTotalSpace
--		, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 30) AS EstimatedDbSizeTotalSpaceIn_30_Days
--		, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 90) AS EstimatedDbSizeTotalSpaceIn_90_Days
--		, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 120) AS EstimatedDbSizeTotalSpaceIn_120_Days
		
--		, Size.[Date]

--	FROM UsedSpaceNormalized AS Used
--	INNER JOIN TotalSpaceNormalized AS Total
--		ON Used.DatabaseName = Total.DatabaseName
--	INNER JOIN FileSizesByDay AS Size
--		ON Size.DatabaseName = Used.DatabaseName
--		AND Size.DatabaseName = Total.DatabaseName
--		AND Size.RowNum = 1
--	ORDER BY
--		DatabaseTotalSize DESC

--	IF @BringFiles = 1 BEGIN
--	--Space By File
--		;WITH FileSizesByDay AS (
--			SELECT
--					DatabaseName
--				, [FileName]
--				, VolumeDrive
--				, FileTotalSpaceMB/1024 AS FileTotalSpaceGB
--				, (FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC))/1024 AS DIFFFileTotalSpaceGB
--				, CASE WHEN (LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC)) = 0 THEN 0 ELSE
--					(FileTotalSpaceMB-( LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC))) / (LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC)) END AS GrowthRateTotalSpace
--				, FileUsedSpaceMB/1024 AS FileUsedSpaceGB
--				, (FileUsedSpaceMB - LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC))/1024 AS DIFFFileUsedSpaceGB
--				, CASE WHEN (LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC)) = 0 THEN 0 ELSE 
--					(FileUsedSpaceMB-( LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC))) / (LEAD(FileUsedSpaceMB, 1, NULL) OVER (PARTITION BY DatabaseName, [FileName] ORDER BY [Date] DESC)) END AS GrowthRateUsedSpace
--				, [Date]
--				, ROW_NUMBER() OVER (PARTITION BY DatabaseName, [FileName] ORDER BY Date DESC) AS RowNum
--			FROM #FileSizesByDay
--		),
--		zScore AS (
--			SELECT
--				  DatabaseName
--				, [FileName]
--				, COUNT(*) AS RowQnt
			
--				, AVG(DIFFFileTotalSpaceGB) as AVG_DIFFFileTotalSpaceGB
--				, STDEV(DIFFFileTotalSpaceGB) AS STDEV_DIFFFileTotalSpaceGB
--				, AVG(GrowthRateTotalSpace) AS AVG_GrowthRateTotalSpace
--				, STDEV(GrowthRateTotalSpace) AS STDEV_GrowthRateTotalSpace
			
--				, AVG(DIFFFileUsedSpaceGB) as AVG_DIFFFileUsedSpaceGB
--				, STDEV(DIFFFileUsedSpaceGB) AS STDEV_DIFFFileUsedSpaceGB
--				, AVG(GrowthRateUsedSpace) AS AVG_GrowthRateUsedSpace
--				, STDEV(GrowthRateUsedSpace) AS STDEV_GrowthRateUsedSpace
--			FROM FileSizesByDay
--			GROUP BY
--				DatabaseName
--				, [FileName]
--		),
--		SizeNormalized AS (
--			SELECT 
--				FileSizesByDay.DatabaseName
--				, FileSizesByDay.[FileName]
--				, FileSizesByDay.DIFFFileTotalSpaceGB
--				, FileSizesByDay.GrowthRateTotalSpace
--				, CASE WHEN zScore.STDEV_DIFFFileTotalSpaceGB = 0 THEN 0 ELSE
--					ABS((FileSizesByDay.DIFFFileTotalSpaceGB - zScore.AVG_DIFFFileTotalSpaceGB) / zScore.STDEV_DIFFFileTotalSpaceGB) END AS DIFFFileTotalSpaceGB_Normalized
--				, CASE WHEN zScore.STDEV_GrowthRateTotalSpace = 0 THEN 0 ELSE
--					ABS((FileSizesByDay.GrowthRateTotalSpace - zScore.AVG_GrowthRateTotalSpace) / zScore.STDEV_GrowthRateTotalSpace) END AS GrowthRateTotalSpace_Normalized
			
--				, FileSizesByDay.DIFFFileUsedSpaceGB
--				, FileSizesByDay.GrowthRateUsedSpace
--				, CASE WHEN zScore.STDEV_DIFFFileUsedSpaceGB = 0 THEN 0 ELSE
--					ABS((FileSizesByDay.DIFFFileUsedSpaceGB - zScore.AVG_DIFFFileUsedSpaceGB) / zScore.STDEV_DIFFFileUsedSpaceGB) END AS DIFFFileUsedSpaceGB_Normalized
--				, CASE WHEN zScore.STDEV_GrowthRateUsedSpace = 0 THEN 0 ELSE
--					ABS((FileSizesByDay.GrowthRateUsedSpace - zScore.AVG_GrowthRateUsedSpace) / zScore.STDEV_GrowthRateUsedSpace) END AS GrowthRateUsedSpace_Normalized
--			, [Date]
--			FROM FileSizesByDay
--			INNER JOIN zScore
--				ON FileSizesByDay.DatabaseName = zScore.DatabaseName
--				AND FileSizesByDay.[FileName] = zScore.[FileName]
--		),
--		TotalSpaceNormalized AS (
--			SELECT
--				DatabaseName
--				, [FileName]
--				, AVG(DIFFFileTotalSpaceGB) AS DIFFFileTotalSpaceGB
--				, CASE WHEN AVG(GrowthRateTotalSpace) > 0.2 THEN 0 ELSE AVG(GrowthRateTotalSpace) END AS GrowthRateTotalSpace
--			FROM SizeNormalized
--			WHERE
--				DIFFFileTotalSpaceGB_Normalized < 2
--				AND GrowthRateTotalSpace_Normalized < 2
--			GROUP BY
--				DatabaseName
--				, [FileName]
--		),
--		UsedSpaceNormalized AS (
--			SELECT
--				DatabaseName
--				, [FileName]
--				, AVG(DIFFFileUsedSpaceGB) AS DIFFFileUsedSpaceGB
--				, CASE WHEN AVG(GrowthRateUsedSpace) > 0.2 THEN 0 ELSE AVG(GrowthRateUsedSpace) END AS GrowthRateUsedSpace
--			FROM SizeNormalized
--			WHERE
--				DIFFFileUsedSpaceGB_Normalized < 2
--				AND GrowthRateUsedSpace_Normalized < 2
--			GROUP BY
--				DatabaseName
--				, [FileName]
--		)
--		SELECT
--			Size.DatabaseName
--			, Size.[FileName]
--			, VolumeDrive
			
--			, Size.FileUsedSpaceGB
--			, Used.DIFFFileUsedSpaceGB AS GrowthUsedSpaceByDayGB
--			, Used.GrowthRateUsedSpace
--			, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),30) AS EstimatedFileSizeUsedSpaceIn_30_Days
--			, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),90) AS EstimatedFileSizeUsedSpaceIn_90_Days
--			, Size.FileUsedSpaceGB*POWER((1+Used.GrowthRateUsedSpace),120) AS EstimatedFileSizeUsedSpaceIn_120_Days
			
--			, Size.FileTotalSpaceGB
--			, Total.DIFFFileTotalSpaceGB AS GrowthTotalSpaceByDayGB
--			, Total.GrowthRateTotalSpace
--			, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 30) AS EstimatedFileSizeTotalSpaceIn_30_Days
--			, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 90) AS EstimatedFileSizeTotalSpaceIn_90_Days
--			, Size.FileTotalSpaceGB*POWER((1+Total.GrowthRateTotalSpace), 120) AS EstimatedFileSizeTotalSpaceIn_120_Days
		
--			, Size.[Date]

--		FROM UsedSpaceNormalized AS Used
--		INNER JOIN TotalSpaceNormalized AS Total
--			ON Used.DatabaseName = Total.DatabaseName
--		INNER JOIN FileSizesByDay AS Size
--			ON Size.DatabaseName = Used.DatabaseName
--			AND Size.DatabaseName = Total.DatabaseName
--			AND Size.[FileName] = Used.[FileName]
--			AND Size.[FileName] = Total.[FileName]
--			AND Size.RowNum = 1
--		ORDER BY
--			Used.DIFFFileUsedSpaceGB DESC
--	END
--END
	