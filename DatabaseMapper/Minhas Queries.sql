--LAST BACKUPS INFOS

--Pega só de quem é PRIMARIA
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
--INNER JOIN ServerInstanceAG AS serAg
--	ON serAg.SQLInstanceId = ins.SQLInstanceID
INNER JOIN HighAvailabilityGroup AS ag
	ON ag.AGId = insDb.AGId
WHERE
	ins.IsMonitored = 1
	AND insDb.IsPrimary = 1
GROUP BY
	dbs.DatabaseName
	, Servername + CASE WHEN ins.InstanceName <> 'NULL' THEN '\' + ins.InstanceName ELSE '' END 
	, ag.AGName


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


--DATABASE SIZE, LOG AND LOG USED
SELECT 
	  dbs.DatabaseName
	, insdb.DataSizeGB
	, insdb.LogSizeGB
	, insdb.[LogSpaceUsedPercent]
	, insdb.SysStart
FROM InstanceDatabase AS insdb
INNER JOIN MyDatabases AS dbs ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN SQLInstance AS sqlins ON insdb.SQLInstanceId = sqlins.SQLInstanceID
INNER JOIN MyServer AS ser ON ser.MyServerId = sqlins.MyServerId
WHERE 
	insdb.IsPrimary = 1
	AND sqlins.IsMonitored = 1
	AND insdb.IsActive = 1
	

--QUEUE SIZE
SELECT 
	  dbs.databaseName
	, ser.Servername
	, insdb.LogQueueSizeKB
	, insdb.LogSendrateKBperSec
	, insdb.SecsToLogSend
	, insdb.RedoQueueSizeKB
	, insdb.RedoRateKBperSec
	, insdb.SecsToRedoEnd
FROM InstanceDatabase AS insdb
INNER JOIN MyDatabases AS dbs ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = insdb.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
WHERE 
	insdb.IsPrimary = 0
	AND insdb.IsActive = 1
	AND ins.IsMonitored = 1
	--AND (insdb.SecsToLogSend + insdb.SecsToRedoEnd)  > 0
ORDER BY 
	(SecsToLogSend + SecsToRedoEnd) DESC


--SERVER INFO
SELECT 
	  ser.Servername + '\' + InstanceName 
	, ser.LogicalCores
	, ins.CoresInUser
	, ser.PhysicalCores
	, ser.MemoryGB
	, ins.MaxMemoryGB
	, ins.MinMemoryGB
	, ser.[SystemManufacturer]
	, ser.[SystemModel]
	, ins.InstanceVersion
	, PV.[Production]
	, PV.[Management]
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins ON ser.MyServerId = ins.MyServerId
INNER JOIN (
	SELECT MyServerId, IPType, Ip
	FROM ServerIPs AS serIp 
	INNER JOIN IPs ON IPs.IPsId = serIp.IPsId) AS X
	PIVOT (MAX(Ip) FOR IpType IN ([Production], [Management])) PV ON PV.MyServerId = ser.MyServerId
WHERE
	ins.IsMonitored = 1
	
--ServerInfo 2.0

--SERVER INFO
-- maximo de 2 AGs por instancia
SELECT 
	  --ser.Servername + '\' + InstanceName AS ServerName
	  ser.Servername 
	--, AGs.ListenerDNS
	, ListListener.Listener_1 AS ListenerName_1
	, ListListener.Listener_2 AS ListenerName_2
	, DC.DatacenterAbreviation AS DataCenter
	, VLAN.VLANName
	, PV.[Production]
	, PV.[Management]
	, CASE WHEN ins.IsOnline = 1 THEN 'ONLINE' ELSE 'OFFLINE' END AS IsOnline
	, WFC.ClusterName
	, ser.LogicalCores 
	, ser.PhysicalCores 
	, ser.LogicalCores / ser.PhysicalCores AS [HyperthreadRatio]
	, ins.CoresInUser
	, ser.MemoryGB
	, ins.MaxMemoryGB
	, ins.MinMemoryGB
	, ser.NumControllers
	, ser.ControllerMB
	, VolumeTotalSpaceGB
	, VolumeTotalSpaceGB - VolumeFreeSpaceGB AS VolumeUsedSpaceGB
	, ser.[SystemManufacturer]
	, ser.[SystemModel]
	, ins.InstanceVersion
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins ON ser.MyServerId = ins.MyServerId
LEFT JOIN (
	SELECT MyServerId, IPType, Ip
	FROM ServerIPs AS serIp 
	INNER JOIN IPs ON IPs.IPsId = serIp.IPsId) AS X
	PIVOT (MAX(Ip) FOR IpType IN ([Production], [Management])) PV ON PV.MyServerId = ser.MyServerId
LEFT JOIN IPs ON PV.Production = IPs.Ip
LEFT JOIN VLAN ON IPs.VLANId = VLAN.VLANId
LEFT JOIN Datacenter AS DC ON VLAN.DatacenterId = DC.DatacenterId
LEFT JOIN (
	SELECT MyServerId, SUM(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB, SUM(VolumeFreeSpaceGB) AS VolumeFreeSpaceGB
	FROM ServerVolume
	GROUP BY 
		MyServerId
) AS serVol ON serVol.MyServerId = ser.MyServerId
LEFT JOIN (
	SELECT ListListener.SQLInstanceId, ListListener.[1] AS Listener_1, ListListener.[2] AS Listener_2
	FROM (
		SELECT 
			ListenerDNS, SQLInstanceId
			, ROW_NUMBER() OVER(PARTITION BY SQLInstanceId ORDER BY ListenerDNS ASC) as rowNo
		FROM HighAvailabilityGroup AS AG
		JOIN AGIPs ON AGIPs.AGId = AG.AGId
		JOIN InstanceDatabase AS insDB ON insDB.AGId = AG.AGId
		WHERE ag.isActive = 1
		GROUP BY 
			ListenerDNS
			, SQLInstanceId
	) AS X
	PIVOT (MAX(ListenerDNS) FOR RowNo IN ([1], [2])) ListListener
)AS ListListener ON ins.SQLInstanceId = ListListener .SQLInstanceId
LEFT JOIN WindowsFailoverCluster AS WFC ON WFC.WFCId = ser.WFCId
ORDER BY WFC.ClusterName DESC



/*

--AG AND DATABASES AND SERVERS
SELECT DISTINCT
	  ags.AGName
	, dbs.DatabaseName
	, AGIPs.ListenerDNS + ',' + CAST(AGIPs.Port AS VARCHAR(128)) AS AGConnection 
	, ser.Servername + '\' + ins.InstanceName  + ',' +  CAST(insIP.Port AS VARCHAR(128)) as InstanceConnection
	, IPs.Ip + ',' +  CAST(insIP.Port AS VARCHAR(128)) as InstanceConnectionByIPs
FROM HighAvailabilityGroup AS ags
JOIN MyDatabases AS dbs ON dbs.AGId = ags.AGId
JOIN ServerInstanceAG AS serAG ON serAG.AGId = ags.AGId
JOIN SQLInstance AS ins ON ins.SQLInstanceID = serAG.SQLInstanceID
JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
JOIN dbo.InstanceIP AS insIP ON insIP.SQLInstanceID = ins.SQLInstanceID
JOIN AGIPs ON AGIPs.AGId = ags.AGId
JOIN IPs ON IPs.IPsId = insIP.IPsId

--DATABASES AND AGs
SELECT DISTINCT
	  ags.AGName
	, dbs.DatabaseName
	, AGIPs.ListenerDNS + ',' + CAST(AGIPs.Port AS VARCHAR(128)) AS AGConnection 
FROM HighAvailabilityGroup AS ags
JOIN MyDatabases AS dbs ON dbs.AGId = ags.AGId
JOIN ServerInstanceAG AS serAG ON serAG.AGId = ags.AGId
--JOIN SQLInstance AS ins ON ins.SQLInstanceID = serAG.SQLInstanceID
--JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
JOIN dbo.InstanceIP AS insIP ON insIP.SQLInstanceID = serAG.SQLInstanceID
JOIN AGIPs ON AGIPs.AGId = ags.AGId
JOIN IPs ON IPs.IPsId = insIP.IPsId
ORDER BY 
	  ags.AGName ASC
	, dbs.DatabaseName ASC

*/

SELECT DISTINCT
	  ISNULL(ags.AGName, ser.ServerName) AS DatabaseLocal
	, ISNULL(AGIPs.ListenerDNS + ',' + CAST(AGIPs.Port AS VARCHAR(128)), ser.Servername + '\' + ins.InstanceName  + ',' +  CAST(insIP.Port AS VARCHAR(128))) AS ConnectionString
	, dbs.DatabaseName
	, CASE WHEN ags.AGName IS NULL THEN 0 ELSE 1 END AS 'IsAgDatabase'
FROM MyDatabases AS dbs 
JOIN dbo.InstanceDatabase AS insDB ON insDB.DatabaseId = dbs.DatabaseId
JOIN SQLInstance AS ins ON ins.SQLInstanceID = insDB.SQLInstanceID
JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
JOIN dbo.InstanceIP AS insIP ON insIP.SQLInstanceID = ins.SQLInstanceID
JOIN IPs ON IPs.IPsId = insIP.IPsId
LEFT JOIN HighAvailabilityGroup AS ags ON dbs.AGId = ags.AGId
LEFT JOIN AGIPs ON AGIPs.AGId = ags.AGId
ORDER BY 
	   IsAgDatabase DESC
	,  DatabaseLocal ASC
	, dbs.DatabaseName ASC

--WHERE ags.AGId IS NULL

--JOIN HighAvailabilityGroup AS ags ON dbs.AGId = ags.AGId
--JOIN ServerInstanceAG AS serAG ON serAG.AGId = ags.AGId
--JOIN SQLInstance AS ins ON ins.SQLInstanceID = serAG.SQLInstanceID
--JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
--JOIN dbo.InstanceIP AS insIP ON insIP.SQLInstanceID = serAG.SQLInstanceID
--JOIN AGIPs ON AGIPs.AGId = ags.AGId
--JOIN IPs ON IPs.IPsId = insIP.IPsId
--ORDER BY 
--	  ags.AGName ASC
--	, dbs.DatabaseName ASC

--AG INFO
SELECT  
	  ag.AGName
	, ser.Servername
	, serag.AvailabilityMode
	, serag.failoverMode
	, serag.BackupPriority
	, serag.AGSynchronizationState
	, serag.AGSynchronizationHealth
	, serag.AGConnectedState
	, ag.AutomatedBackupPreference
	, ag.FailureConditionLevel
	, ag.HealthCheckTimeout
	, serag.IsPrimary
	, serag.PrimaryRoleAllowConnections
	, serag.SecondaryRoleAllowConnections
FROM ServerInstanceAG AS serag
INNER JOIN HighAvailabilityGroup AS ag ON ag.AGId = serag.AGId
INNER JOIN SQLInstance AS ins ON serag.SQLInstanceId = ins.SQLInstanceID
INNER JOIN MyServer AS ser ON ins.MyServerId = ser.MyServerId
ORDER BY
	ag.AGName


-- DATABASES INFO
SELECT 
	dbs.databaseName
	, Servername + '\' + InstanceName  AS Instance
	, insdb.DataSizeGB
	, insdb.LogSizeGB
	, insdb.CompatibilityLevel
	, insdb.RecoveryModel
	, insdb.SnapshotIsolation
	, insdb.ReadCommitedSnapshot
	, insdb.IsPrimary
	, insdb.SysStart
FROM InstanceDatabase AS insdb
INNER JOIN MyDatabases AS dbs ON insdb.DatabaseId = dbs.DatabaseId
INNER JOIN SQLInstance AS sqlins ON sqlins.SQLInstanceID = insdb.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = sqlins.MyServerId
WHERE 
	insdb.IsPrimary = 1 
	AND sqlins.IsMonitored = 1
	AND insdb.IsActive = 1
ORDER BY 
	dbs.DatabaseName ASC

-- database Files INFO
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
	

--SERVER SPACE INFO
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


--ALL INDEXES INFO
SELECT 
	db.databaseName
	, ser.Servername + '\' + ins.InstanceName  AS Instance
	,dbix.[SchemaName]
	,dbix.[TableName]
	,dbix.[IndexId]
	,dbix.[IndexName]
	,dbix.[IndexType]
	,dbix.[IndexKeys]
	,dbix.[IndexIncludes]
	,dbix.[IsUnique]
	,dbix.[IndexFillFactor]
	,dbix.[IsPadded]
	,dbix.[HasFilter]
	,dbix.[IndexFilter]
	,dbix.[IndexSeeks]
	,dbix.[IndexScans]
	,dbix.[IndexLookUps]
	,dbix.[LastIndexSeek]
	,dbix.[LastIndexScan]
	,dbix.[LastIndexLookUp]
	,dbix.[LastIndexUpdate]
	,dbix.[IndexSizeGB]
	,dbix.[SysStart]
FROM [dbo].[DatabaseIndexUsage] AS dbix
INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = dbix.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
 


 -- INDEXES NOT USED LAST 5 DAYS INFOS 
SELECT *
FROM (
	SELECT 
		  db.databaseName
		, dbix.[SchemaName]
		, dbix.[TableName]
		, dbix.[IndexId]
		, dbix.[IndexName]
		, ISNULL(MAX(LastIndexSeek), '19891030') AS LastIndexSeek
		, ISNULL(MAX(LastIndexScan), '19891030') AS LastIndexScan
	FROM [dbo].[DatabaseIndexUsage] AS dbix
	INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
	INNER JOIN SQLInstance AS sqlins ON sqlins.SQLInstanceID = dbix.SQLInstanceId
	INNER JOIN MyServer AS ser ON ser.MyServerId = sqlins.MyServerId
	WHERE 
		[IndexType] <> 'Clustered'
	GROUP BY
		  dbix.[SchemaName]
		, dbix.[TableName]
		, dbix.[IndexId]
		, dbix.[IndexName]
		, db.databaseName
) AS ixUsage
WHERE 
	    (CAST(LastIndexSeek AS DATE) < CAST(GETDATE()-5 AS DATE)) 
	AND (CAST(LastIndexScan AS DATE) < CAST(GETDATE()-5 AS DATE))
ORDER BY 
	LastIndexSeek DESC

--find index not used last month
SELECT [SchemaName]
		,[TableName]
		,[IndexName]
		, MAX([IndexSizeGB]) as [IndexSizeGB], COUNT(*) AS CT
FROM (
	SELECT 
		 ser.Servername + '\' + ins.InstanceName  AS Instance
		,[SchemaName]
		,[TableName]
		,[IndexName]
		, SUM(ISNULL([IndexSeeks], 0) + ISNULL([IndexScans], 0))AS QNT
		, MAX([IndexSizeGB]) As [IndexSizeGB]
		FROM [dbo].[DatabaseIndexUsage] 
			FOR SYSTEM_TIME  BETWEEN '2018-10-01 23:00:00.0000000' AND '2018-10-22 23:01:00.0000000'  
			AS dbix
		INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
		INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = dbix.SQLInstanceId
		INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
		WHERE
			databaseName = 'buy4_bo'
			AND Servername in ('CHI1B4DB02P01', 'DC1B4DB02P02', 'DC2B4DB02P01')
			AND dbix.IsUnique <> 1
	GROUP BY ser.Servername + '\' + ins.InstanceName  
		,[SchemaName]
		,[TableName]
		,[IndexName]
	HAVING SUM(ISNULL([IndexSeeks], 0) + ISNULL([IndexScans], 0)) = 0
) AS X
GROUP BY [SchemaName]
		,[TableName]
		,[IndexName]
HAVING COUNT([IndexName]) = 3
ORDER BY [IndexSizeGB] desc


/*
SELECT 
databaseName
, Servername + '\' + InstanceName  AS Instance
, dbix.*
FROM [dbo].[DatabaseIndexUsage] AS dbix
INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
INNER JOIN SQLInstance AS sqlins ON sqlins.SQLInstanceID = dbix.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = sqlins.MyServerId
WHERE  TableName = 'AMR_MOVEMENT'
AND 
IndexName = 

*/


--SERVER INFO
SELECT 
	  --ser.Servername + '\' + InstanceName AS ServerName
	  ser.Servername 
	--, AGs.ListenerDNS
	, ListListener.Listener_1 AS ListenerName_1
	, ListListener.Listener_2 AS ListenerName_2
	, DC.DatacenterAbreviation AS DataCenter
	, VLAN.VLANName
	, PV.[Production]
	, PV.[Management]
	, WFC.ClusterName
	, ser.LogicalCores 
	, ser.PhysicalCores 
	, ser.LogicalCores / ser.PhysicalCores AS [HyperthreadRatio]
	, ins.CoresInUser
	, ser.MemoryGB
	, ins.MaxMemoryGB
	, ins.MinMemoryGB
	, ser.NumControllers
	, ser.ControllerMB
	, VolumeTotalSpaceGB
	, VolumeTotalSpaceGB - VolumeFreeSpaceGB AS VolumeUsedSpaceGB
	, ser.[SystemManufacturer]
	, ser.[SystemModel]
	, ins.InstanceVersion
FROM MyServer AS ser
INNER JOIN SQLInstance AS ins ON ser.MyServerId = ins.MyServerId
LEFT JOIN (
	SELECT MyServerId, IPType, Ip
	FROM ServerIPs AS serIp 
	INNER JOIN IPs ON IPs.IPsId = serIp.IPsId) AS X
	PIVOT (MAX(Ip) FOR IpType IN ([Production], [Management])) PV ON PV.MyServerId = ser.MyServerId
LEFT JOIN IPs ON PV.Production = IPs.Ip
LEFT JOIN VLAN ON IPs.VLANId = VLAN.VLANId
LEFT JOIN Datacenter AS DC ON VLAN.DatacenterId = DC.DatacenterId
LEFT JOIN (
	SELECT MyServerId, SUM(VolumeTotalSpaceGB) AS VolumeTotalSpaceGB, SUM(VolumeFreeSpaceGB) AS VolumeFreeSpaceGB
	FROM ServerVolume
	GROUP BY 
		MyServerId
) AS serVol ON serVol.MyServerId = ser.MyServerId
LEFT JOIN (
	SELECT ListListener.SQLInstanceId, ListListener.[1] AS Listener_1, ListListener.[2] AS Listener_2
	FROM (
		SELECT 
			ListenerDNS, SQLInstanceId
			, ROW_NUMBER() OVER(PARTITION BY SQLInstanceId ORDER BY ListenerDNS ASC) as rowNo
		FROM HighAvailabilityGroup AS AG
		JOIN AGIPs ON AGIPs.AGId = AG.AGId
		JOIN InstanceDatabase AS insDB ON insDB.AGId = AG.AGId
		GROUP BY 
			ListenerDNS
			, SQLInstanceId
	) AS X
	PIVOT (MAX(ListenerDNS) FOR RowNo IN ([1], [2])) ListListener
)AS ListListener ON ins.SQLInstanceId = ListListener .SQLInstanceId
LEFT JOIN WindowsFailoverCluster AS WFC ON WFC.WFCId = ser.WFCId
ORDER BY WFC.ClusterName DESC


DECLARE @lastMonth DATE = (DATEADD(DD, -30, GETDATE()))
--SELECT SUM (DIFFSIZEMB)
--FROM (
SELECT 
	  dbs.DatabaseName
	, ser.Servername + '\' + ins.InstanceName  AS Instance
	, serVol.[VolumeDrive]
	, insVol.[FileName]
	, insVol.[FileTotalSpaceMB]
	, Hist.FileTotalSpaceMB AS FileTotalSpaceMBHist
	, insVol.[FileTotalSpaceMB] - Hist.FileTotalSpaceMB AS DiffSizeMB
FROM [dbo].[InstanceDatabaseVolume] AS insVol
CROSS APPLY (
	SELECT *
	FROM [dbo].InstanceDatabaseVolume
	FOR SYSTEM_TIME AS OF @lastMonth
	AS volHist
	WHERE 
		insVol.InstanceDatabaseVolumeId = volHist.InstanceDatabaseVolumeId
		AND insVol.FileTotalSpaceMB <> volHist.FileTotalSpaceMB
) AS Hist
INNER JOIN [dbo].[InstanceDatabase] AS insdb ON insdb.SQLInstanceId = insVol.SQLInstanceId AND insdb.DatabaseId = insVol.DatabaseId
INNER JOIN [dbo].[ServerVolume] AS serVol ON insVol.ServerVolumeId = serVol.ServerVolumeId
INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = insVol.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
INNER JOIN MyDatabases AS dbs ON dbs.DatabaseId = insVol.DatabaseId
WHERE
	(insdb.IsPrimary = 1 OR insdb.IsPrimary IS NULL)
	AND dbs.DatabaseName = 'Buy4_bo'
	AND insVol.Type = 'Rows'
	--AND VolumeDrive = 'M:\DataDisks\DataDisk01\'
ORDER BY
	dbs.DatabaseName ASC
	, DiffSizeMB DESC
--) AS X

--proc estimate growth
exec[dbo].[proc_DatabaseGrowth] @DatabaseName = 'Buy4_bo', @SampleDays = 60, @BringFiles = 0

--file growth period
SELECT 
		dbs.DatabaseName
	, serVol.[VolumeDrive]
	, insDbVol.[FileName]
	, MAX(insDbVol.[FileTotalSpaceMB]) AS [FileTotalSpaceMB_MAX]
	, MIN(insDbVol.[FileTotalSpaceMB]) AS [FileTotalSpaceMB_MIN]
	, MAX(insDbVol.[FileTotalSpaceMB]) - MIN(insDbVol.[FileTotalSpaceMB]) AS FileGrowth
	, MIN(insDbVol.sysStart) AS StartDate
	, MAX(insDbVol.sysStart) AS EndDate
FROM [dbo].[InstanceDatabaseVolume_HISTORY] AS insDbVol
INNER JOIN [dbo].[InstanceDatabase] AS insdb ON insdb.SQLInstanceId = insDbVol.SQLInstanceId AND insdb.DatabaseId = insDbVol.DatabaseId
INNER JOIN [dbo].[ServerVolume] AS serVol ON insDbVol.ServerVolumeId = serVol.ServerVolumeId
INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = insDbVol.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
INNER JOIN MyDatabases AS dbs ON dbs.DatabaseId = insDbVol.DatabaseId
WHERE
	(insdb.IsPrimary = 1 OR insdb.IsPrimary IS NULL)
	AND insDbVol.Type = 'Rows'
	--AND dbs.DatabaseName = @DatabaseName
	AND insDbVol.SysStart >= dateadd(DAY, -3, getdate())
	AND serVol.[VolumeDrive] = 'M:\DataDisks\DataDisk01\'
	AND ser.Servername = 'CHI1B4DB02P01'
GROUP BY
	  dbs.DatabaseName
	, serVol.[VolumeDrive]
	, insDbVol.[FileName]
HAVING
	MAX(insDbVol.[FileTotalSpaceMB]) - MIN(insDbVol.[FileTotalSpaceMB]) > 0
	
	
--Pegar o tamanho dos arquivos e onde ele ta localizado
--20.638
SELECT
	a.[FileName]
	, FileLocation.FileLocation
	, FileTotalSpaceMB
	, [Date]
FROM (
	SELECT
		insDbVol.[FileName]
		, MAX(insDbVol.FileTotalSpaceMB) AS FileTotalSpaceMB
		, CAST(insDbVol.SysStart AS DATE) AS [Date]
	FROM dbo.InstanceDatabaseVolume 
		FOR SYSTEM_TIME FROM '20180101' TO '20191231' --coloquei uma data no futuro pra pegar o atual tmb 
		AS insDbVol
	INNER JOIN [dbo].[InstanceDatabase] AS insdb
		 ON insdb.SQLInstanceId = insDbVol.SQLInstanceId 
		 AND insdb.DatabaseId = insDbVol.DatabaseId
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDbVol.SQLInstanceId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDbVol.DatabaseId
	WHERE
		dbs.DatabaseName = 'Buy4_bo'
		AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
	GROUP BY
		insDbVol.[FileName]
		, CAST(insDbVol.SysStart AS DATE)
) AS a
INNER JOIN (
--esse select aqui é pra pegar o ultimo fileLocation porque ao inves de atualizar quando a gente faz movimentação de arquivo, ele insere uma linha nova.
SELECT *
FROM (
	SELECT
		insDbVol.[FileName]
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
		dbs.DatabaseName = 'Buy4_bo'
		AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
	GROUP BY
		insDbVol.[FileName], insDbVol.SysStart, insDbVol.FileLocation
	) AS x
	WHERE x.RowNo = 1
) AS FileLocation
	ON FileLocation.[FileName] = a.[FileName]

	
	
	
	
	
	

--Pegar o tamanho dos arquivos e onde ele ta localizado
drop table if exists #FileSizes
SELECT
	a.[FileName]
	, FileLocation.FileLocation
	, SUBSTRING(FileLocation.FileLocation, 14, 10) AS DataDisk
	, FileTotalSpaceMB
	, FileUsedSpaceMB
	, [Date]
INTO #FileSizes
FROM (
	SELECT
		insDbVol.[FileName]
		, MAX(insDbVol.FileTotalSpaceMB) AS FileTotalSpaceMB
		, MAX(insDbVol.FileTotalSpaceMB - insDbVol.FileFreeSpaceMB) AS FileUsedSpaceMB
		, CAST(insDbVol.SysStart AS DATE) AS [Date]
	FROM dbo.InstanceDatabaseVolume 
		FOR SYSTEM_TIME FROM '20180101' TO '20191231' --coloquei uma data no futuro pra pegar o atual tmb 
		AS insDbVol
	INNER JOIN [dbo].[InstanceDatabase] AS insdb
		 ON insdb.SQLInstanceId = insDbVol.SQLInstanceId 
		 AND insdb.DatabaseId = insDbVol.DatabaseId
	INNER JOIN SQLInstance AS ins ON 
		ins.SQLInstanceID = insDbVol.SQLInstanceId
	INNER JOIN MyDatabases AS dbs 
		ON dbs.DatabaseId = insDbVol.DatabaseId
	WHERE
		dbs.DatabaseName = 'Buy4_bo'
		AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
	GROUP BY
		insDbVol.[FileName]
		, CAST(insDbVol.SysStart AS DATE)
) AS a
INNER JOIN (
--esse select aqui é pra pegar o ultimo fileLocation porque ao inves de atualizar quando a gente faz movimentação de arquivo, ele insere uma linha nova.
SELECT *
FROM (
	SELECT
		insDbVol.[FileName]
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
		dbs.DatabaseName = 'Buy4_bo'
		AND insdb.IsPrimary = 1
		AND insDbVol.[Type] NOT LIKE 'LOG'
		AND ins.IsMonitored = 1
	GROUP BY
		insDbVol.[FileName], insDbVol.SysStart, insDbVol.FileLocation
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
	FileName
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



--Space By File
SELECT 
	[FileName]
	, [DataDisk]
	, ISNULL(AVG(DIFFFileTotalSpaceMB), 0) AS GrowthFileTotalSpaceMBPerDay
	, ISNULL(AVG(DIFFFileUsedSpaceMB) , 0) AS GrowthFileUsedSpaceMBPerDay
	--, ISNULL(REPLACE(AVG(DIFFFileTotalSpaceMB), '.', ','), '0,0') AS GrowthFileTotalSpaceMBPerDay --Ficar bonito na planilha
	--, ISNULL(REPLACE(AVG(DIFFFileUsedSpaceMB), '.', ','), '0,0') AS GrowthFileUsedSpaceMBPerDay	--Ficar bonito na planilha
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
			Date > '20190401'
		GROUP BY
			[FileName]
			, [DataDisk]
			, [Date]
	)AS X
) AS x
--WHERE
--	DIFFDataSizeMB > 0
GROUP BY
	[FileName]
	, [DataDisk]
HAVING
	AVG(DIFFFileUsedSpaceMB) > 0
ORDER BY
	GrowthFileUsedSpaceMBPerDay DESC