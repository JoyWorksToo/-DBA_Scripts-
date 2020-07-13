

/*
Calculando o tempo para o disco morrer, fazendo previsoes e calculando pontos fora da curva para remove-los
https://www.aquare.la/o-que-sao-outliers-e-como-trata-los-em-uma-analise-de-dados/
https://www.geeksforgeeks.org/find-mean-mode-sql-server/
https://www.ctspedia.org/do/view/CTSpedia/OutLier
https://www.researchgate.net/post/Which_is_the_best_method_for_removing_outliers_in_a_data_set
file:///C:/Users/aalmeida/Downloads/KDD95-044.pdf
https://www.mssqltips.com/sqlservertip/3464/using-tsql-to-perform-zscore-column-normalization-in-sql-server/

*/


DECLARE @sampleDays INT = 30
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) = 'Buy4_bo'

DROP TABLE IF EXISTS #DiskSizes
SELECT
	ser.ServerName
	, SerVol.VolumeDrive
	, MAX(SerVol.VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
	, MAX(SerVol.VolumeFreeSpaceGB) AS VolumeFreeSpaceGB
	, CAST(SerVol.SysStart AS DATE) AS [Date]
INTO #DiskSizes
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
	AND ins.IsMonitored = 1
GROUP BY
	  ser.serverName
	, SerVol.VolumeDrive
	, CAST(SerVol.SysStart AS DATE)
	, CAST(SerVol.SysStart AS DATE)

--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (@sampleDays + 10)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, @startDate)
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;


--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #DiskSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #DiskSizes
)
SELECT 
	ServerName
	, VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeFreeSpaceGB
	, c.d AS [Date]
INTO #DiskSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);

SELECT
	ServerName
	, VolumeDrive
	--, LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC))
	, LOG(0.1, 1+GrowthRate)
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeFreeSpaceGB) AS DIFFVolumeFreeSpaceGB
		, STDEV(DIFFVolumeFreeSpaceGB) AS stdevVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			ServerName
			, VolumeDrive
			, VolumeTotalSpaceGB
			, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
			, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
		FROM #DiskSizesByDay
	) AS AVGs
	GROUP BY
		ServerName
		, VolumeDrive
) AS Growth

--LOG((SELECT VolumeTotalSpaceGB FROM ServerVolume WHERE ServerVolumeId = AVGs.ServerVolumeId) / LastDbSizeUsedSpaceGB, (1+GrowthRateTotalSpace)) AS EstimatedDaysLeft
drop table if exists #zScore
SELECT
	COUNT(*) AS RowQnt
	, AVG(DIFFVolumeFreeSpaceGB) as AVG_DIFFVolumeFreeSpaceGB
	, STDEV(DIFFVolumeFreeSpaceGB) AS STDEV_DIFFVolumeFreeSpaceGB
	, AVG(GrowthRate) AS AVG_GrowthRate
	, STDEV(GrowthRate) AS STDEV_GrowthRate
INTO #zScore
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
		, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
		, [Date]
	FROM #DiskSizesByDay
	WHERE
		VolumeDrive = 'M:\DataDisks\DataDisk07'
		AND Servername = 'BO-V-SQL1-1P01'
) AS X

declare @meanX as decimal(7,3)
declare @standardDeviationX as decimal(7,3)
declare @meanY as decimal(7,3)
declare @standardDeviationY as decimal(7,3)

--Set the variables
set @meanX=(select AVG_DIFFVolumeFreeSpaceGB from #zScore)
set @standardDeviationX=(select STDEV_DIFFVolumeFreeSpaceGB from #zScore)
set @meanY=(select AVG_GrowthRate from #zScore)
set @standardDeviationY=(select STDEV_GrowthRate from #zScore)


/************************************************************************************************************************************************/
/************************************************************************************************************************************************/
/************************************************************************************************************************************************/
/************************************************************************************************************************************************/


DECLARE @sampleDays INT = 30
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) = 'Buy4_bo'

DROP TABLE IF EXISTS #DiskSizes
SELECT
	ser.ServerName
	, SerVol.VolumeDrive
	, MAX(SerVol.VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
	, MAX(SerVol.VolumeFreeSpaceGB) AS VolumeFreeSpaceGB
	, CAST(SerVol.SysStart AS DATE) AS [Date]
INTO #DiskSizes
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
	AND ins.IsMonitored = 1
GROUP BY
	  ser.serverName
	, SerVol.VolumeDrive
	, CAST(SerVol.SysStart AS DATE)
	, CAST(SerVol.SysStart AS DATE)

--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (@sampleDays + 10)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, @startDate)
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;


--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #DiskSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #DiskSizes
)
SELECT 
	ServerName
	, VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeFreeSpaceGB
	, VolumeTotalSpaceGB - VolumeFreeSpaceGB AS VolumeLeftSpaceGB
	, c.d AS [Date]
INTO #DiskSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);

SELECT
	ServerName
	, VolumeDrive
	--, LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC))
	, LOG(0.1, 1+GrowthRate)
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeFreeSpaceGB) AS DIFFVolumeFreeSpaceGB
		, STDEV(DIFFVolumeFreeSpaceGB) AS stdevVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			ServerName
			, VolumeDrive
			, VolumeTotalSpaceGB
			, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
			, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
		FROM #DiskSizesByDay
	) AS AVGs
	GROUP BY
		ServerName
		, VolumeDrive
) AS Growth

--LOG((SELECT VolumeTotalSpaceGB FROM ServerVolume WHERE ServerVolumeId = AVGs.ServerVolumeId) / LastDbSizeUsedSpaceGB, (1+GrowthRateTotalSpace)) AS EstimatedDaysLeft
drop table if exists #zScore
SELECT
	  VolumeDrive 
	, Servername 
	, COUNT(*) AS RowQnt
	, AVG(DIFFVolumeFreeSpaceGB) as AVG_DIFFVolumeFreeSpaceGB
	, STDEV(DIFFVolumeFreeSpaceGB) AS STDEV_DIFFVolumeFreeSpaceGB
	, AVG(GrowthRate) AS AVG_GrowthRate
	, STDEV(GrowthRate) AS STDEV_GrowthRate
INTO #zScore
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
		, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
		, [Date]
	FROM #DiskSizesByDay
) AS X
GROUP BY
	VolumeDrive 
	, Servername 

select *
 from #zScore

SELECT
	ServerName
	, VolumeDrive
	--, LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC))
	, CASE WHEN GrowthRate = 0 THEN NULL ELSE LOG(0.001, 1+GrowthRate) END AS PredictedDaysLeft
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeFreeSpaceGB) AS DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			a.ServerName
			, a.VolumeDrive
			, VolumeTotalSpaceGB
			, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
			, CASE WHEN b.STDEV_DIFFVolumeFreeSpaceGB = 0 THEN NULL ELSE ((VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_DIFFVolumeFreeSpaceGB) / b.STDEV_DIFFVolumeFreeSpaceGB END AS DIFFVolumeFreeSpaceGB_Normalized
			, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, CASE WHEN b.STDEV_GrowthRate  = 0 THEN NULL ELSE ((VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_GrowthRate) / b.STDEV_GrowthRate END AS GrowthRate_Normalized
			, [Date]
		FROM #DiskSizesByDay as a
		INNER JOIN #zScore as b
			ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
	) AS AVGs
	WHERE
		AVGs.DIFFVolumeFreeSpaceGB_Normalized < 3
		AND AVGs.DIFFVolumeFreeSpaceGB_Normalized > -3
		AND AVGs.GrowthRate_Normalized < 3
		AND AVGs.GrowthRate_Normalized > -3
	GROUP BY
		ServerName
		, VolumeDrive
) AS y


SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeFreeSpaceGB) AS DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			ServerName
			, VolumeDrive
			, VolumeTotalSpaceGB
			, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
			, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
		FROM #DiskSizesByDay
	) AS AVGs
	GROUP BY
		ServerName
		, VolumeDrive
		
		
		
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/



DECLARE @sampleDays INT = 30
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) = 'Buy4_bo'

DROP TABLE IF EXISTS #DiskSizes
SELECT
	ser.ServerName
	, SerVol.VolumeDrive
	, MAX(SerVol.VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
	, MAX(SerVol.VolumeFreeSpaceGB) AS VolumeFreeSpaceGB
	, CAST(SerVol.SysStart AS DATE) AS [Date]
INTO #DiskSizes
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
	AND ins.IsMonitored = 1
GROUP BY
	  ser.serverName
	, SerVol.VolumeDrive
	, CAST(SerVol.SysStart AS DATE)
	, CAST(SerVol.SysStart AS DATE)

--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (@sampleDays + 10)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, @startDate)
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;


--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #DiskSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #DiskSizes
)
SELECT 
	ServerName
	, VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeFreeSpaceGB
	, VolumeTotalSpaceGB - VolumeFreeSpaceGB AS VolumeLeftSpaceGB
	, c.d AS [Date]
INTO #DiskSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);

	
SELECT
	ServerName
	, VolumeDrive
	, CASE WHEN GrowthRate = 0 THEN NULL ELSE LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeTotalSpaceGB - VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END
	--, LOG(0.1, 1+GrowthRate)
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeLeftSpaceGB) AS DIFFVolumeFreeSpaceGB
		, STDEV(DIFFVolumeLeftSpaceGB) AS stdevVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			ServerName
			, VolumeDrive
			, VolumeTotalSpaceGB
			, VolumeLeftSpaceGB
			, (VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeLeftSpaceGB
			, (VolumeLeftSpaceGB -( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
		FROM #DiskSizesByDay
	) AS AVGs
	GROUP BY
		ServerName
		, VolumeDrive
) AS Growth

--LOG((SELECT VolumeTotalSpaceGB FROM ServerVolume WHERE ServerVolumeId = AVGs.ServerVolumeId) / LastDbSizeUsedSpaceGB, (1+GrowthRateTotalSpace)) AS EstimatedDaysLeft
drop table if exists #zScore
SELECT
	  VolumeDrive 
	, Servername 
	, COUNT(*) AS RowQnt
	, AVG(DIFFVolumeLeftSpaceGB) as AVG_DIFFVolumeLeftSpaceGB
	, STDEV(DIFFVolumeLeftSpaceGB) AS STDEV_DIFFVolumeLeftSpaceGB
	, AVG(GrowthRate) AS AVG_GrowthRate
	, STDEV(GrowthRate) AS STDEV_GrowthRate
INTO #zScore
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, (VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeLeftSpaceGB
			, (VolumeLeftSpaceGB -( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
	FROM #DiskSizesByDay
) AS X
GROUP BY
	VolumeDrive 
	, Servername 

select *
 from #zScore

SELECT
	ServerName
	, VolumeDrive
	--, LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC))
	, CASE WHEN GrowthRate = 0 THEN NULL ELSE LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeTotalSpaceGB - VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeLeftSpaceGB) AS DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			a.ServerName
			, a.VolumeDrive
			, VolumeTotalSpaceGB
			, (VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeLeftSpaceGB 
			, CASE WHEN b.STDEV_DIFFVolumeLeftSpaceGB = 0 THEN NULL ELSE ((VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_DIFFVolumeLeftSpaceGB) / b.STDEV_DIFFVolumeLeftSpaceGB END AS DIFFVolumeLeftSpaceGB_Normalized
			, (VolumeLeftSpaceGB-( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, CASE WHEN b.STDEV_GrowthRate  = 0 THEN NULL ELSE ((VolumeLeftSpaceGB-( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_GrowthRate) / b.STDEV_GrowthRate END AS GrowthRate_Normalized
			, [Date]
		FROM #DiskSizesByDay as a
		INNER JOIN #zScore as b
			ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
	) AS AVGs
	WHERE
		AVGs.DIFFVolumeLeftSpaceGB_Normalized < 3
		AND AVGs.DIFFVolumeLeftSpaceGB_Normalized > -3
		AND AVGs.GrowthRate_Normalized < 3
		AND AVGs.GrowthRate_Normalized > -3
	GROUP BY
		ServerName
		, VolumeDrive
) AS y


SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeFreeSpaceGB) AS DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			ServerName
			, VolumeDrive
			, VolumeTotalSpaceGB
			, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
			, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
		FROM #DiskSizesByDay
	) AS AVGs
	GROUP BY
		ServerName
		, VolumeDrive
		
		
-------------------------------------------

		
		
/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/



DECLARE @sampleDays INT = 90
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) = 'buy4_bo'

DROP TABLE IF EXISTS #DiskSizes
SELECT
	ser.ServerName
	, SerVol.VolumeDrive
	, SerVol.VolumeTotalSpaceGB
	, SerVol.VolumeFreeSpaceGB
	, SerVol.SysStart 
	, ROW_NUMBER () OVER (PARTITION BY ser.ServerName, serVol.VolumeDrive, CAST(serVol.Sysstart AS DATE) ORDER BY CAST(serVol.Sysstart AS TIME) DESC) AS RowNum
		--, MAX(SerVol.VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
	--, MAX(SerVol.VolumeFreeSpaceGB) AS VolumeFreeSpaceGB
	--, CAST(SerVol.SysStart AS DATE) AS [Date]
--INTO #DiskSizes
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
	AND ins.IsMonitored = 1
	AND insdb.IsActive = 1
ORDER BY ser.ServerName, serVol.VolumeDrive, SysStart desc
--GROUP BY
--	  ser.serverName
--	, SerVol.VolumeDrive
--	, CAST(SerVol.SysStart AS DATE)
--	, CAST(SerVol.SysStart AS DATE)

--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (@sampleDays + 10)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, @startDate)
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;


--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #DiskSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #DiskSizes
)
SELECT 
	ServerName
	, VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeFreeSpaceGB
	, VolumeTotalSpaceGB - VolumeFreeSpaceGB AS VolumeLeftSpaceGB
	, c.d AS [Date]
INTO #DiskSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);

	
--SELECT
--	ServerName
--	, VolumeDrive
--	, CASE WHEN GrowthRate = 0 THEN NULL ELSE LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeTotalSpaceGB - VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END As DaysLeft
--	--, LOG(0.1, 1+GrowthRate)
--FROM (
--	SELECT
--		ServerName
--		, VolumeDrive
--		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
--		, AVG(DIFFVolumeLeftSpaceGB) AS DIFFVolumeFreeSpaceGB
--		, STDEV(DIFFVolumeLeftSpaceGB) AS stdevVolumeFreeSpaceGB
--		, AVG(GrowthRate) AS GrowthRate
--	FROM(
--		SELECT
--			ServerName
--			, VolumeDrive
--			, VolumeTotalSpaceGB
--			, VolumeLeftSpaceGB
--			, (VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeLeftSpaceGB
--			, (VolumeLeftSpaceGB -( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
--			, [Date]
--		FROM #DiskSizesByDay
--	) AS AVGs
--	GROUP BY
--		ServerName
--		, VolumeDrive
--) AS Growth

--LOG((SELECT VolumeTotalSpaceGB FROM ServerVolume WHERE ServerVolumeId = AVGs.ServerVolumeId) / LastDbSizeUsedSpaceGB, (1+GrowthRateTotalSpace)) AS EstimatedDaysLeft
drop table if exists #zScore
SELECT
	  VolumeDrive 
	, Servername 
	, COUNT(*) AS RowQnt
	, AVG(DIFFVolumeLeftSpaceGB) as AVG_DIFFVolumeLeftSpaceGB
	, STDEV(DIFFVolumeLeftSpaceGB) AS STDEV_DIFFVolumeLeftSpaceGB
	, AVG(GrowthRate) AS AVG_GrowthRate
	, STDEV(GrowthRate) AS STDEV_GrowthRate
INTO #zScore
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, (VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeLeftSpaceGB
			, (VolumeLeftSpaceGB -( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, [Date]
	FROM #DiskSizesByDay
) AS X
GROUP BY
	VolumeDrive 
	, Servername 

select *from #zScore

SELECT
	ServerName
	, VolumeDrive
	--, LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = Growth.ServerName AND inside.VolumeDrive = Growth.VolumeDrive ORDER BY Date DESC))
	, CASE WHEN GrowthRate = 0 THEN NULL ELSE LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeTotalSpaceGB - VolumeFreeSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END AS PredictedDaysLeft
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeLeftSpaceGB) AS DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS GrowthRate
	FROM(
		SELECT
			a.ServerName
			, a.VolumeDrive
			, VolumeTotalSpaceGB
			, VolumeLeftSpaceGB
			, (VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeLeftSpaceGB 
			, CASE WHEN b.STDEV_DIFFVolumeLeftSpaceGB = 0 THEN NULL ELSE ((VolumeLeftSpaceGB - LEAD(VolumeLeftSpaceGB , 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_DIFFVolumeLeftSpaceGB) / b.STDEV_DIFFVolumeLeftSpaceGB END AS DIFFVolumeLeftSpaceGB_Normalized
			, (VolumeLeftSpaceGB-( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
			, CASE WHEN b.STDEV_GrowthRate  = 0 THEN NULL ELSE ((VolumeLeftSpaceGB-( LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeLeftSpaceGB, 1, NULL) OVER (PARTITION BY a.ServerName, a.VolumeDrive ORDER BY [date] DESC)) - b.AVG_GrowthRate) / b.STDEV_GrowthRate END AS GrowthRate_Normalized
			, [Date]
		FROM #DiskSizesByDay as a
		INNER JOIN #zScore as b
			ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
	) AS AVGs
	WHERE
		AVGs.DIFFVolumeLeftSpaceGB_Normalized < 3
		AND AVGs.DIFFVolumeLeftSpaceGB_Normalized > -3
		AND AVGs.GrowthRate_Normalized < 3
		AND AVGs.GrowthRate_Normalized > -3
	GROUP BY
		ServerName
		, VolumeDrive
) AS y


--SELECT
--		ServerName
--		, VolumeDrive
--		, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
--		, AVG(DIFFVolumeFreeSpaceGB) AS DIFFVolumeFreeSpaceGB
--		, AVG(GrowthRate) AS GrowthRate
--	FROM(
--		SELECT
--			ServerName
--			, VolumeDrive
--			, VolumeTotalSpaceGB
--			, (VolumeFreeSpaceGB - LEAD(VolumeFreeSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeFreeSpaceGB 
--			, (VolumeFreeSpaceGB-( LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeFreeSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
--			, [Date]
--		FROM #DiskSizesByDay
--	) AS AVGs
--	GROUP BY
--		ServerName
--		, VolumeDrive


---------------
TA LINDO ESSE 
---------------

/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/

DECLARE @sampleDays INT = 120
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) = 'Caju'

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
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, @startDate)
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;


--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #DiskSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
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
	, (SELECT TOP 1 VolumeTotalSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC) AS VolumeTotalSpaceGB
	, (SELECT TOP 1 VolumeUsedSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC) AS VolumeUsedSpaceGB
	, CASE WHEN GrowthRate = 0 THEN NULL ELSE LOG(VolumeTotalSpaceGB / (SELECT TOP 1 VolumeUsedSpaceGB FROM #DiskSizesByDay AS inside WHERE inside.Servername = y.ServerName AND inside.VolumeDrive = y.VolumeDrive ORDER BY Date DESC), 1+GrowthRate) END AS PredictedDaysLeft
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
		AVGs.DIFFVolumeUsedSpaceGB_Normalized < 3
		AND AVGs.DIFFVolumeUsedSpaceGB_Normalized > -3
		AND AVGs.GrowthRate_Normalized < 3
		AND AVGs.GrowthRate_Normalized > -3
	GROUP BY
		ServerName
		, VolumeDrive
) AS y


/************************************************************************************************************************/
/************************************************************************************************************************/
/************************************************************************************************************************/

DECLARE @sampleDays INT = 120
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) = 'Buy4_bo'

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
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
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

	
;WITH DiskSizeByDay AS (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, VolumeUsedSpaceGB
		, VolumeFreeSpaceGB
		, (VolumeUsedSpaceGB - LEAD(VolumeUsedSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeUsedSpaceGB
		, (VolumeUsedSpaceGB -( LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
		, [Date]
		, ROW_NUMBER() OVER (PARTITION BY ServerName, VolumeDrive ORDER BY Date DESC) AS RowNum
	FROM #DiskSizesByDay
),
zScore AS (
	SELECT
		  VolumeDrive 
		, Servername 
		, COUNT(*) AS RowQnt
		, AVG(DIFFVolumeUsedSpaceGB) as AVG_DIFFVolumeLeftSpaceGB
		, STDEV(DIFFVolumeUsedSpaceGB) AS STDEV_DIFFVolumeLeftSpaceGB
		, AVG(GrowthRate) AS AVG_GrowthRate
		, STDEV(GrowthRate) AS STDEV_GrowthRate
	FROM DiskSizeByDay
	GROUP BY
		VolumeDrive 
		, Servername 
),
SizeNormalized AS (
	SELECT
		a.ServerName
		, a.VolumeDrive
		, VolumeTotalSpaceGB
		, VolumeUsedSpaceGB
		, DIFFVolumeUsedSpaceGB 
		, CASE WHEN b.STDEV_DIFFVolumeLeftSpaceGB = 0 THEN 0 ELSE 
			ABS ((a.DIFFVolumeUsedSpaceGB - b.AVG_DIFFVolumeLeftSpaceGB) / b.STDEV_DIFFVolumeLeftSpaceGB) END AS DIFFVolumeUsedSpaceGB_Normalized
		, GrowthRate
		, CASE WHEN b.STDEV_GrowthRate = 0 THEN 0 ELSE 
			ABS((GrowthRate - b.AVG_GrowthRate) / b.STDEV_GrowthRate) END AS GrowthRate_Normalized
		, [Date]
	FROM DiskSizeByDay as a
	INNER JOIN zScore as b
		ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
)
SELECT
		ServerName
		, VolumeDrive
		--, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(DIFFVolumeUsedSpaceGB) AS AVG_DIFFVolumeFreeSpaceGB
		, AVG( GrowthRate) AS AVG_GrowthRate
		--, AVG(DIFFVolumeUsedSpaceGB) AS DIFFVolumeFreeSpaceGB
		--, AVG(GrowthRate) AS GrowthRate
	FROM SizeNormalized
	where
		DIFFVolumeUsedSpaceGB_Normalized < 2 and GrowthRate_Normalized < 2 
	GROUP BY
		ServerName
		, VolumeDrive

	
	
;WITH DiskSizeByDay AS (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, VolumeUsedSpaceGB
		, VolumeFreeSpaceGB
		, (VolumeUsedSpaceGB - LEAD(VolumeUsedSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeUsedSpaceGB
		, (VolumeUsedSpaceGB -( LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
		, [Date]
		, ROW_NUMBER() OVER (PARTITION BY ServerName, VolumeDrive ORDER BY Date DESC) AS RowNum
	FROM #DiskSizesByDay
),
zScore AS (
	SELECT
		  VolumeDrive 
		, Servername 
		, COUNT(*) AS RowQnt
		, AVG(DIFFVolumeUsedSpaceGB) as AVG_DIFFVolumeLeftSpaceGB
		, STDEV(DIFFVolumeUsedSpaceGB) AS STDEV_DIFFVolumeLeftSpaceGB
		, AVG(GrowthRate) AS AVG_GrowthRate
		, STDEV(GrowthRate) AS STDEV_GrowthRate
	FROM DiskSizeByDay
	GROUP BY
		VolumeDrive 
		, Servername 
),
SizeNormalized AS (
	SELECT
		a.ServerName
		, a.VolumeDrive
		, VolumeTotalSpaceGB
		, VolumeUsedSpaceGB
		, DIFFVolumeUsedSpaceGB 
		, CASE WHEN b.STDEV_DIFFVolumeLeftSpaceGB = 0 THEN 0 ELSE 
			ABS ((a.DIFFVolumeUsedSpaceGB - b.AVG_DIFFVolumeLeftSpaceGB) / b.STDEV_DIFFVolumeLeftSpaceGB) END AS DIFFVolumeUsedSpaceGB_Normalized
		, GrowthRate
		, CASE WHEN b.STDEV_GrowthRate = 0 THEN 0 ELSE 
			ABS((GrowthRate - b.AVG_GrowthRate) / b.STDEV_GrowthRate) END AS GrowthRate_Normalized
		, [Date]
	FROM DiskSizeByDay as a
	INNER JOIN zScore as b
		ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
)
SELECT
		ServerName
		, VolumeDrive
		--, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, (CASE WHEN DIFFVolumeUsedSpaceGB_Normalized < 2 THEN DIFFVolumeUsedSpaceGB ELSE NULL END) AS AVG_DIFFVolumeFreeSpaceGB
		, AVG(CASE WHEN GrowthRate_Normalized < 2 THEN GrowthRate ELSE NULL END) AS AVG_GrowthRate
		--, AVG(DIFFVolumeUsedSpaceGB) AS DIFFVolumeFreeSpaceGB
		--, AVG(GrowthRate) AS GrowthRate
	FROM SizeNormalized 
	GROUP BY
		ServerName
		, VolumeDrive

SELECT
	y.ServerName
	, y.VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeUsedSpaceGB
	, y.GrowthRate
	, CASE WHEN y.GrowthRate = 0 THEN NULL ELSE LOG(VolumeTotalSpaceGB / VolumeUsedSpaceGB, 1+ y.GrowthRate) END AS PredictedDaysLeft
FROM (
	SELECT
		ServerName
		, VolumeDrive
		--, MAX(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB
		, AVG(CASE WHEN DIFFVolumeUsedSpaceGB_Normalized < 2 THEN DIFFVolumeUsedSpaceGB END) AS DIFFVolumeFreeSpaceGB
		, AVG(CASE WHEN GrowthRate_Normalized < 2 THEN GrowthRate END) AS GrowthRate
		--, AVG(DIFFVolumeUsedSpaceGB) AS DIFFVolumeFreeSpaceGB
		--, AVG(GrowthRate) AS GrowthRate
	FROM SizeNormalized 
	GROUP BY
		ServerName
		, VolumeDrive
) as y
INNER JOIN DiskSizeByDay
	ON y.ServerName = DiskSizeByDay.Servername
	AND  y.VolumeDrive = DiskSizeByDay.VolumeDrive
WHERE
	DiskSizeByDay.RowNum = 1



--- Completo

DECLARE @sampleDays INT = 120
DECLARE 
	@endDate DATE = DATEADD(DAY, 1, GETDATE())
, @startDate DATE = DATEADD(DAY, -@sampleDays, GETDATE())
, @DatabaseName VARCHAR(128) --= 'Buy4_bo'

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
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
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


;WITH DiskSizeByDay AS (
	SELECT
		ServerName
		, VolumeDrive
		, VolumeTotalSpaceGB
		, VolumeUsedSpaceGB
		, VolumeFreeSpaceGB
		, (VolumeUsedSpaceGB - LEAD(VolumeUsedSpaceGB , 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC)) AS DIFFVolumeUsedSpaceGB
		, (VolumeUsedSpaceGB -( LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))) / (LEAD(VolumeUsedSpaceGB, 1, NULL) OVER (PARTITION BY ServerName, VolumeDrive ORDER BY [date] DESC))  AS GrowthRate
		, [Date]
		, ROW_NUMBER() OVER (PARTITION BY ServerName, VolumeDrive ORDER BY Date DESC) AS RowNum
	FROM #DiskSizesByDay
),
zScore AS (
	SELECT
		  VolumeDrive 
		, Servername 
		, COUNT(*) AS RowQnt
		, AVG(DIFFVolumeUsedSpaceGB) as AVG_DIFFVolumeLeftSpaceGB
		, STDEV(DIFFVolumeUsedSpaceGB) AS STDEV_DIFFVolumeLeftSpaceGB
		, AVG(GrowthRate) AS AVG_GrowthRate
		, STDEV(GrowthRate) AS STDEV_GrowthRate
	FROM DiskSizeByDay
	GROUP BY
		VolumeDrive 
		, Servername 
),
SizeNormalized AS (
	SELECT
		a.ServerName
		, a.VolumeDrive
		, VolumeTotalSpaceGB
		, VolumeUsedSpaceGB
		, DIFFVolumeUsedSpaceGB 
		, CASE WHEN b.STDEV_DIFFVolumeLeftSpaceGB = 0 THEN 0 ELSE 
			ABS ((a.DIFFVolumeUsedSpaceGB - b.AVG_DIFFVolumeLeftSpaceGB) / b.STDEV_DIFFVolumeLeftSpaceGB) END AS DIFFVolumeUsedSpaceGB_Normalized
		, GrowthRate
		, CASE WHEN b.STDEV_GrowthRate = 0 THEN 0 ELSE 
			ABS((GrowthRate - b.AVG_GrowthRate) / b.STDEV_GrowthRate) END AS GrowthRate_Normalized
		, [Date]
	FROM DiskSizeByDay as a
	INNER JOIN zScore as b
		ON a.Servername = b.Servername AND a.VolumeDrive = b.VolumeDrive
)
SELECT
	Growth.ServerName
	, Growth.VolumeDrive
	, VolumeTotalSpaceGB
	, VolumeUsedSpaceGB
	, Growth.AVG_GrowthRate
	, CASE WHEN Growth.AVG_GrowthRate = 0 THEN 9999999 ELSE 
		LOG(DiskSizeByDay.VolumeTotalSpaceGB / DiskSizeByDay.VolumeUsedSpaceGB, 1+Growth.AVG_GrowthRate) END AS PredictedDaysLeft
FROM (
	SELECT
		ServerName
		, VolumeDrive
		, AVG(DIFFVolumeUsedSpaceGB) AS AVG_DIFFVolumeFreeSpaceGB
		, AVG(GrowthRate) AS AVG_GrowthRate
	FROM SizeNormalized
	WHERE
		DIFFVolumeUsedSpaceGB_Normalized < 2 
		AND GrowthRate_Normalized < 2 
	GROUP BY
		  ServerName
		, VolumeDrive
) as Growth
INNER JOIN DiskSizeByDay
	ON Growth.ServerName = DiskSizeByDay.Servername
	AND  Growth.VolumeDrive = DiskSizeByDay.VolumeDrive
WHERE
	DiskSizeByDay.RowNum = 1
ORDER BY
	PredictedDaysLeft ASC
