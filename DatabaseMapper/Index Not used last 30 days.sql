

DECLARE @endDate DATE = GETDATE() + 1
DECLARE @startDate DATE = DATEADD(DD, -30, @endDate)

SELECT *
FROM (
	SELECT 
		SchemaName
		, TableName
		, IndexName
		, SUM([IndexSeeks]) AS [IndexSeeks]
		, SUM([IndexScans]) AS [IndexScans]
		, SUM([IndexLookUps]) AS [IndexLookUps]
		, MAX([LastIndexSeek]) AS [LastIndexSeek]
		, MAX([LastIndexScan]) AS [LastIndexScan]
		, MAX([LastIndexLookUp]) AS [LastIndexLookUp]
		, MAX([LastIndexUpdate]) AS [LastIndexUpdate]
		, MAX([IndexSizeGB]) AS [IndexSizeGB]
	FROM (
		SELECT 
			db.databaseName
			, ser.Servername + '\' + ins.InstanceName  AS Instance
			, dbix.[SchemaName]
			, dbix.[TableName]
			, dbix.[IndexName]
			, dbix.[IndexType]
			, ISNULL(dbix.[IndexSeeks]	, 0) AS [IndexSeeks]
			, ISNULL(dbix.[IndexScans]	, 0) AS [IndexScans]
			, ISNULL(dbix.[IndexLookUps], 0) AS [IndexLookUps]
			, dbix.[LastIndexSeek]
			, dbix.[LastIndexScan]
			, dbix.[LastIndexLookUp]
			, dbix.[LastIndexUpdate]
			, dbix.[IndexSizeGB]
			, dbix.[SysStart]
		FROM [dbo].[DatabaseIndexUsage] 
			FOR SYSTEM_TIME BETWEEN @startDate AND @endDate
			AS dbix
		INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
		INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = dbix.SQLInstanceId
		INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
		WHERE
			databaseName = 'Buy4_accounting'
			--AND TableName = 'AMR_MOVEMENT'
			--AND IndexName IN ('IX_ID_PRODUCT_MemberId') --, 'IX_ID_PRODUCT_MemberId')
			--AND Servername in ('CHI1B4DB02P01', 'DC1B4DB02P02', 'DC2B4DB02P01')
			--and tableName = 'SettledOperation'
			--AND IndexName = 'IX_SCOPE_ID_TRANSACTION_STATUS_OUTGOING_STATUS_ExpectedBrandPaymentDate_MemberId_Filtered'
			AND ins.IsMonitored = 1
			--and IsUnique <> 1
			and dbix.[SchemaName] = 'dimp'
		--ORDER BY IndexName desc, sysstart asc
		--ORDER BY
		--	Instance asc,
		--	SysStart desc
		
	) AS x
	--where
	--	IndexSeeks = 0
	--	AND IndexScans = 0
	GROUP BY
		SchemaName
		, TableName
		, IndexName
) AS Y
--where
--	IndexSeeks = 0
--	AND IndexScans = 0
ORDER BY
	LastIndexSeek desc
