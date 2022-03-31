
/*
Informação sobre AG, banco que tem no AG com IP
*/
SELECT DISTINCT
	  UPPER(ags.AGName) AS AGName
	, dbs.DatabaseName
	, UPPER(AGIPs.ListenerDNS) + ',' + CAST(AGIPs.Port AS VARCHAR(128)) AS AGConnection 
	, ser.Servername + '\' + ins.InstanceName as InstanceName
	, IPs.Ip + ',' +  CAST(insIP.Port AS VARCHAR(128)) as InstanceConnectionByIPs
FROM HighAvailabilityGroup AS ags
JOIN MyDatabases AS dbs 
	ON dbs.AGId = ags.AGId
JOIN ServerInstanceAG AS serAG 
	ON serAG.AGId = ags.AGId
JOIN SQLInstance AS ins 
	ON ins.SQLInstanceID = serAG.SQLInstanceID
JOIN MyServer AS ser 
	ON ser.MyServerId = ins.MyServerId
JOIN dbo.InstanceIP AS insIP 
	ON insIP.SQLInstanceID = ins.SQLInstanceID
JOIN AGIPs 
	ON AGIPs.AGId = ags.AGId
JOIN IPs 
	ON IPs.IPsId = insIP.IPsId
WHERE
	ins.IsMonitored = 1
ORDER BY 1 ASC



/*
Informação dos últimos backups feitos
*/
SELECT 
	Servername + CASE WHEN ins.InstanceName <> 'NULL' THEN '\' + ins.InstanceName ELSE '' END AS ServerInstance
	, ag.AGName
	, dbs.DatabaseName
	, MAX(insdb.LastBackupFULL) AS LastBackupFULL
	, MAX(insdb.LastBackupDIFF) AS LastBackupDIFF
	, MAX(insdb.LastBackupLOG ) AS LastBackupLOG 
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins
	ON ser.MyServerId = ins.MyServerId
INNER JOIN InstanceDatabase AS insDb
	ON insDb.SQLInstanceId = ins.SQLInstanceID
INNER JOIN MyDatabases AS dbs 
	ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN ServerInstanceAG AS serAg
	ON serAg.SQLInstanceId = ins.SQLInstanceID
INNER JOIN HighAvailabilityGroup AS ag
	ON ag.AGId = insDb.AGId
WHERE
	ins.IsMonitored = 1
	AND insDb.IsPrimary = 1
	AND insDb.IsActive = 1
GROUP BY
	dbs.DatabaseName
	, Servername + CASE WHEN ins.InstanceName <> 'NULL' THEN '\' + ins.InstanceName ELSE '' END 
	, ag.AGName
ORDER BY 1 asc, 3 asc

--Esse é agrupado por AG
--Last Backup FULL in DAYS
SELECT 
	  ag.AGName
	, dbs.DatabaseName
	, MAX(insdb.LastBackupFULL) AS LastBackupFULL
	, DATEDIFF(DAY, MAX(insdb.LastBackupFULL), GETDATE()) AS LastBackupFullInDays
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins
	ON ser.MyServerId = ins.MyServerId
INNER JOIN InstanceDatabase AS insDb
	ON insDb.SQLInstanceId = ins.SQLInstanceID
INNER JOIN MyDatabases AS dbs 
	ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN HighAvailabilityGroup AS ag
	ON ag.AGId = insDb.AGId
WHERE
	ins.IsMonitored = 1
	AND insDb.IsActive = 1
GROUP BY
	dbs.DatabaseName
	, ag.AGName
ORDER BY
	LastBackupFullInDays DESC

--Last Backup DIFF in DAYS
SELECT 
	  ag.AGName
	, dbs.DatabaseName
	, MAX(insdb.LastBackupDIFF) AS LastBackupDIFF
	, DATEDIFF(DAY, MAX(insdb.LastBackupDIFF), GETDATE()) AS LastBackupDIFFInDays
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins
	ON ser.MyServerId = ins.MyServerId
INNER JOIN InstanceDatabase AS insDb
	ON insDb.SQLInstanceId = ins.SQLInstanceID
INNER JOIN MyDatabases AS dbs 
	ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN HighAvailabilityGroup AS ag
	ON ag.AGId = insDb.AGId
WHERE
	ins.IsMonitored = 1
	AND insDb.IsActive = 1
GROUP BY
	dbs.DatabaseName
	, ag.AGName
ORDER BY
	LastBackupDIFFInDays DESC

--Last Backup LOG in MINUTES
SELECT 
	  ag.AGName
	, dbs.DatabaseName
	,  MAX(insdb.LastBackupLOG ) AS LastBackupLOG 
	, DATEDIFF(MINUTE, MAX(insdb.LastBackupLOG), GETDATE()) AS LastBackupLOGInMinutes
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins
	ON ser.MyServerId = ins.MyServerId
INNER JOIN InstanceDatabase AS insDb
	ON insDb.SQLInstanceId = ins.SQLInstanceID
INNER JOIN MyDatabases AS dbs 
	ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN HighAvailabilityGroup AS ag
	ON ag.AGId = insDb.AGId
WHERE
	ins.IsMonitored = 1
	AND insDb.IsActive = 1
GROUP BY
	dbs.DatabaseName
	, ag.AGName
ORDER BY
	LastBackupLOGInMinutes DESC
	

/*
Informação de onde está a primária
*/
SELECT *
FROM (
	SELECT 
		UPPER(ag.AGName) AS AGName
		, UPPER(ser.Servername) as PrimaryServer
		, UPPER(RIGHT(ser.Servername, CHARINDEX('-',REVERSE(ser.Servername))-1)) AS VMPosition
		, CASE 
			WHEN RIGHT(ser.Servername, CHARINDEX('-',REVERSE(ser.Servername))-1) LIKE '1P%' THEN 'ATLANTA'
			WHEN RIGHT(ser.Servername, CHARINDEX('-',REVERSE(ser.Servername))-1) LIKE '2P%' THEN 'CHICAGO'
			ELSE 'undefined'
		END AS DataCenter
	FROM MyServer AS ser
	INNER JOIN SQLInstance AS ins
		ON ser.MyServerId = ins.MyServerId
	INNER JOIN ServerInstanceAG AS serAg
		ON serAg.SQLInstanceId = ins.SQLInstanceID
	INNER JOIN HighAvailabilityGroup AS ag
		ON ag.AGId = serAg.AGId
	WHERE
		ins.IsMonitored = 1
		AND serAg.IsPrimary = 1
) AS PrimaryAg
WHERE
	(PrimaryServer LIKE @serverName + '%' OR @serverName IS NULL)
ORDER BY
	DataCenter ASC
	, AGName ASC
	
/*
DatabaseInfo
*/
SELECT 
		UPPER(ags.AGName) AS AGName
	, ser.Servername + '\' + ins.InstanceName as InstanceName
	, dbs.DatabaseName
	, insdb.DataSizeGB
	, insdb.LogSizeGB
	, insdb.[LogSpaceUsedPercent]
	, insdb.CompatibilityLevel
	, insdb.SnapshotIsolation
	, CASE WHEN insdb.ReadCommitedSnapshot = 1 THEN 'ON' ELSE 'OFF' END AS ReadCommitedSnapshot 
FROM HighAvailabilityGroup AS ags
JOIN MyDatabases AS dbs 
	ON dbs.AGId = ags.AGId
JOIN ServerInstanceAG AS serAG 
	ON serAG.AGId = ags.AGId
JOIN SQLInstance AS ins 
	ON ins.SQLInstanceID = serAG.SQLInstanceID
JOIN MyServer AS ser 
	ON ser.MyServerId = ins.MyServerId
JOIN InstanceDatabase AS insdb
	ON insdb.DatabaseId = dbs.DatabaseId
	AND insdb.SQLInstanceId = ins.SQLInstanceID
WHERE
	insdb.IsPrimary = 1
	AND ins.IsMonitored = 1
	AND insdb.IsActive = 1
ORDER BY 1 ASC

/*
database Files INFO
*/
SELECT 
	  dbs.DatabaseName
	, ser.Servername + '\' + ins.InstanceName  AS Instance
	, serVol.[VolumeLogicalName]
	, serVol.[VolumeDrive]
	, insVol.[Type]
	, insVol.[FileName]
	, insVol.[FileGroupName]
	, insVol.[FileLocation]
	, insVol.[FileTotalSpaceMB]
	, insVol.[FileFreeSpaceMB]
	, [FileTotalSpaceMB] - [FileFreeSpaceMB] AS [FileUsedSpaceMB]
	, CAST(([FileFreeSpaceMB] / [FileTotalSpaceMB]) *100.0 AS DECIMAL(12,2)) AS [FilePercentFree] 
	, insVol.[FileMaxSize]
	, insVol.[Filegrowth]
	, insVol.[IsReadOnly]
	, insVol.[IsPercentGrowth]
	, insvol.Sysstart
FROM [dbo].[InstanceDatabaseVolume] AS insVol
INNER JOIN [dbo].[InstanceDatabase] AS insdb ON insdb.SQLInstanceId = insVol.SQLInstanceId AND insdb.DatabaseId = insVol.DatabaseId
INNER JOIN [dbo].[ServerVolume] AS serVol ON insVol.ServerVolumeId = serVol.ServerVolumeId
INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = insVol.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
INNER JOIN MyDatabases AS dbs ON dbs.DatabaseId = insVol.DatabaseId
WHERE
	(insdb.IsPrimary = 1 OR insdb.IsPrimary IS NULL)
	and ins.IsMonitored = 1
ORDER BY
	dbs.DatabaseName ASC

/*
Server Disk INFO
*/
SELECT 
	  ser.Servername
	, serVol.VolumeLogicalName
	, serVol.VolumeDrive
	, serVol.VolumeTotalSpaceGB
	, serVol.VolumeFreeSpaceGB
	, CAST((serVol.VolumeFreeSpaceGB / serVol.VolumeTotalSpaceGB) * 100.0 AS DECIMAL(12,2)) AS VolumePercentFree
	, serVol.FileSystemType
FROM [dbo].[ServerVolume] as serVol
INNER JOIN MyServer AS ser ON ser.MyServerId = serVol.MyServerId
INNER JOIN SQLInstance AS ins ON ser.MyServerId = ins.MyServerId
WHERE
	ins.IsMonitored = 1
	AND (ser.Servername LIKE @ServerName + '%' OR @ServerName IS NULL)
ORDER BY	
	Servername ASC
	, VolumeLogicalName ASC
	
/*
Index info grouped
*/

DECLARE @TableName VARCHAR(128) = NULL,
	@IndexName VARCHAR(128) = NULL,
	@DatabaseName VARCHAR(128) = 'BUY4_BO',
	@ServerName VARCHAR(128) = NULL,
	@BringUniqueKey BIT = 0
DECLARE @endDate DATETIME = getdate()
DECLARE @startDate datetime = DATEADD(DAY, -30, @endDate)
DECLARE @outDate datetime = DATEADD(DAY, -60, @startDate)

SELECT 
	SchemaName
	, TableName
	, IndexName
	, [IsUnique]
	, SUM([IndexSeeks]) AS [IndexSeeks]
	, SUM([IndexScans]) AS [IndexScans]
	, SUM([IndexLookUps]) AS [IndexLookUps]
	, MAX([LastIndexSeek]) AS [LastIndexSeek]
	, MAX([LastIndexScan]) AS [LastIndexScan]
	, MAX([LastIndexLookUp]) AS [LastIndexLookUp]
	, MAX([LastIndexUpdate]) AS [LastIndexUpdate]
	, MAX([IndexSizeGB]) AS [IndexSizeGB]
	, MAX(LastCollectedDate) as LastCollectedDate
FROM (
	SELECT 
		db.databaseName
		, ser.Servername + '\' + ins.InstanceName  AS Instance
		, dbix.[SchemaName]
		, dbix.[TableName]
		, dbix.[IndexName]
		, dbix.[IndexType]
		, dbix.[IsUnique]
		, dbix_Hist.[IndexSeeks]
		, dbix_Hist.[IndexScans]
		, dbix_Hist.[IndexLookUps]
		, dbix_Hist.[LastIndexSeek]
		, dbix_Hist.[LastIndexScan]
		, dbix_Hist.[LastIndexLookUp]
		, dbix_Hist.[LastIndexUpdate]
		, dbix_Hist.[IndexSizeGB]
		, dbix_Hist.[SysStart]
		, dbix.[SysStart] AS LastCollectedDate
	FROM [dbo].[DatabaseIndexUsage] AS dbix
	INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
	INNER JOIN dbo.SQLInstance AS ins ON ins.SQLInstanceID = dbix.SQLInstanceId
	INNER JOIN dbo.MyServer AS ser ON ser.MyServerId = ins.MyServerId
	INNER JOIN dbo.InstanceDatabase AS insDb ON insDb.SQLInstanceId = ins.SQLInstanceID AND insDb.DatabaseId = db.DatabaseId
	LEFT JOIN [dbo].[DatabaseIndexUsage] 
		FOR SYSTEM_TIME  BETWEEN @startDate AND @endDate
		AS dbix_Hist ON dbix.DatabaseIndexUsageId = dbix_Hist.DatabaseIndexUsageId
	WHERE
		ins.IsMonitored = 1
		AND insDb.IsActive = 1
		AND dbix.isUnique IN (0, @BringUniqueKey)
		--AND databaseName = @DatabaseName
		--AND Servername LIKE ('pay-v-sql1%')
		--AND dbix.tableName like ''
		--AND dbix.IndexName like ''
	--ORDER BY IndexName desc, sysstart asc
) AS idx
GROUP BY
	SchemaName
	, TableName
	, IndexName
	, [IsUnique]
ORDER BY 
	LastIndexSeek DESC