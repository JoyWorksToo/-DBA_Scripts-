--Media por disco
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

DROP TABLE IF EXISTS #DiskSizes
SELECT *
INTO #DiskSizes
FROM (
	SELECT
		ser.ServerName
		, SerVol.VolumeDrive
		, SerVol.VolumeTotalSpaceGB
		, SerVol.VolumeFreeSpaceGB
		, CAST(SerVol.SysStart AS DATE) AS [Date]
		, ROW_NUMBER () OVER (PARTITION BY ser.ServerName, serVol.VolumeDrive, CAST(serVol.Sysstart AS DATE) ORDER BY CAST(serVol.Sysstart AS TIME) DESC) AS RowNum
	FROM [dbo].[InstanceDatabase] AS insdb
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDb.SQLInstanceId
	INNER JOIN Myserver AS ser
		ON ser.MyServerId = ins.MyServerId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDb.DatabaseId
	INNER JOIN ServerVolume 
		FOR SYSTEM_TIME FROM @startDate TO @endDate --coloquei uma data no futuro pra pegar o atual tmb 
		AS SerVol
		ON SerVol.MyServerId = ins.MyServerId 
	WHERE 
		(dbs.DatabaseName = @DatabaseName OR @DatabaseName IS NULL)
		AND ser.Servername = @ServerName
		AND ins.IsMonitored = 1
		AND insdb.IsActive = 1
) AS DiskSizes
WHERE
	DiskSizes.RowNum = 1
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
DROP TABLE IF EXISTS #DiskSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), DATEADD(DAY, 1, CAST(GETDATE() AS DATE))) AS NextDate
	from #DiskSizes
)
SELECT 
	ServerName
	, VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeFreeSpaceGB
	, VolumeTotalSpaceGB - VolumeFreeSpaceGB AS VolumeUsedSpaceGB
	, c.d AS [Date]
INTO #DiskSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);

drop table if exists #zScore
SELECT
		VolumeDrive 
	, Servername 
	, COUNT(*) AS RowQnt
	, AVG(DIFFVolumeUsedSpaceGB) as AVG_DIFFVolumeLeftSpaceGB
	, STDEV(DIFFVolumeUsedSpaceGB) AS STDEV_DIFFVolumeLeftSpaceGB
	, AVG(GrowthRate) AS AVG_GrowthRate
	, STDEV(GrowthRate) AS STDEV_GrowthRate
INTO #zScore
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, (VolumeUsedSpaceGB - LEAD(VolumeUsedSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeUsedSpaceGB
		, (VolumeUsedSpaceGB -( LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
		, [Date]
	FROM #DiskSizesByDay
) AS X
GROUP BY
	VolumeDrive 
	, Servername 
	
SELECT
	ServerName
	, VolumeDrive
	, GrowthRate
	, DIFFVolumeFreeSpaceGB AS GrowthPerDayGB
	, (SELECT TOP 1 VolumeTotalSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC) AS VolumeTotalSpaceGB
	, (SELECT TOP 1 VolumeUsedSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC) AS VolumeUsedSpaceGB
	, CASE WHEN GrowthRate = 0 THEN 19893010 ELSE LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeUsedSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END AS PredictedDaysLeft
	, CASE WHEN GrowthRate = 0 THEN 19893010 ELSE LOG((VolumeTotalSpaceGB-100) / (SELECT TOP 1 VolumeUsedSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END AS PredictedDaysLeft_100GbLeft
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeUsedSpaceGB) AS DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			a.ServerName
			, a.VolumeDrive
			, VolumeTotalSpaceGB
			, VolumeUsedSpaceGB
			, (VolumeUsedSpaceGB - LEAD(VolumeUsedSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeUsedSpaceGB 
			, CASE WHEN b.STDEV_DIFFVolumeLeftSpaceGB = 0 THEN 0 ELSE ((VolumeUsedSpaceGB - LEAD(VolumeUsedSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_DIFFVolumeLeftSpaceGB) / b.STDEV_DIFFVolumeLeftSpaceGB END AS DIFFVolumeUsedSpaceGB_Normalized
			, (VolumeUsedSpaceGB-( LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, CASE WHEN b.STDEV_GrowthRate = 0 THEN 0 ELSE ((VolumeUsedSpaceGB-( LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_GrowthRate) / b.STDEV_GrowthRate END AS GrowthRate_Normalized
			, [Date]
		FROM #DiskSizesByDay as a
		INNER JOIN #zScore as b
			ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
	) AS AVGs
	WHERE
		AVGs.DIFFVolumeUsedSpaceGB_Normalized < 2
		AND AVGs.DIFFVolumeUsedSpaceGB_Normalized > -2
		AND AVGs.GrowthRate_Normalized < 2
		AND AVGs.GrowthRate_Normalized > -2
	GROUP BY
		ServerName
		, VolumeDrive
) AS y
ORDER BY
	VolumeDrive asc

