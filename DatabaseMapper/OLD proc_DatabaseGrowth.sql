USE [DatabaseMapper]
GO
/****** Object:  StoredProcedure [dbo].[proc_DatabaseGrowth]    Script Date: 11/13/2019 7:08:48 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

ALTER PROCEDURE [dbo].[proc_DatabaseGrowth]
	@DatabaseName VARCHAR(128)
	, @SampleDays INT 
	, @BringFiles BIT = 0
AS
DECLARE @Today DATE = DATEADD(HOUR, 1, Getdate())
DECLARE @LastDay DATE = DATEADD(DAY, -@sampleDays, GETDATE())

SELECT 
	@DatabaseName AS DatabaseName
	, AVG(DIFFDataSizeGB) AS GrowhPerDayGB
	, AVG(DIFFDataSizeGB) *30 AS GrowhPerMonthGB
FROM (
	SELECT
		DatabaseName
		, DataSizeGB
		, [Date]
		, DataSizeGB - LEAD(DataSizeGB, 1, NULL) OVER ( ORDER BY [Date] DESC) AS DIFFDataSizeGB
	FROM(
		SELECT 
			dbs.databaseName
			, MAX(insdb.DataSizeGB) AS DataSizeGB
			, CAST(insdb.SysStart AS DATE) AS [Date]
		FROM InstanceDatabase_HISTORY AS insdb
		INNER JOIN MyDatabases AS dbs ON insdb.DatabaseId = dbs.DatabaseId
		INNER JOIN SQLInstance AS sqlins ON sqlins.SQLInstanceID = insdb.SQLInstanceId
		INNER JOIN MyServer AS ser ON ser.MyServerId = sqlins.MyServerId
		WHERE 
			(insdb.IsPrimary = 1 OR insdb.IsPrimary IS NULL) 
			AND sqlins.IsMonitored = 1
			AND dbs.DatabaseName = @DatabaseName 
			AND insdb.SysStart >= dateadd(DAY, -@SampleDays, getdate())
		GROUP BY
			CAST(insdb.SysStart AS DATE)
			, dbs.databaseName
	) AS X
) AS Y

IF @BringFiles = 1 BEGIN
SELECT
	  @DatabaseName
	, [FileName]
	, VolumeDrive
	, ISNULL(AVG(DIFFDataSizeMB), 0) AS GrowhPerDayMB
	, ISNULL(AVG(DIFFDataSizeMB)*30, 0) AS GrowhPerMonthMB
FROM (
	SELECT
		DatabaseName	
		, VolumeDrive
		, [FileName]
		, FileTotalSpaceMB	
		, [Date]
		, FileTotalSpaceMB - LEAD(FileTotalSpaceMB, 1, NULL) OVER (PARTITION BY X.DatabaseName, [VolumeDrive], X.[FileName] ORDER BY X.[Date] DESC) AS DIFFDataSizeMB
	FROM(
		SELECT 
			  dbs.DatabaseName
			, serVol.[VolumeDrive]
			, insDbVol.[FileName]
			, MAX(insDbVol.[FileTotalSpaceMB]) AS [FileTotalSpaceMB]
			, CAST(insDbVol.SysStart AS DATE) AS [Date]
		FROM [dbo].[InstanceDatabaseVolume_HISTORY] AS insDbVol
		INNER JOIN [dbo].[InstanceDatabase] AS insdb ON insdb.SQLInstanceId = insDbVol.SQLInstanceId AND insdb.DatabaseId = insDbVol.DatabaseId
		INNER JOIN [dbo].[ServerVolume] AS serVol ON insDbVol.ServerVolumeId = serVol.ServerVolumeId
		INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = insDbVol.SQLInstanceId
		INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
		INNER JOIN MyDatabases AS dbs ON dbs.DatabaseId = insDbVol.DatabaseId
		WHERE
			(insdb.IsPrimary = 1 OR insdb.IsPrimary IS NULL)
			AND insDbVol.Type = 'Rows'
			AND dbs.DatabaseName = @DatabaseName
			AND insDbVol.SysStart >= dateadd(DAY, -@SampleDays, getdate())
			
		GROUP BY
			CAST(insDbVol.SysStart AS DATE)
			, dbs.DatabaseName
			, serVol.[VolumeDrive]
			, insDbVol.[FileName]
	) AS X
) AS Y
GROUP BY
	VolumeDrive
	, [FileName]
ORDER BY
	[FileName] DESC
END
