SELECT 
	db.databaseName
	, ser.Servername + '\' + ins.InstanceName  AS Instance
	,dbix.[SchemaName]
	,dbix.[TableName]
	,dbix.[IndexName]
	,dbix.[IndexType]
	,dbix.[IndexSeeks]
	,dbix.[IndexScans]
	,dbix.[IndexLookUps]
	,dbix.[LastIndexSeek]
	,dbix.[LastIndexScan]
	,dbix.[LastIndexLookUp]
	,dbix.[LastIndexUpdate]
	,dbix.[IndexSizeGB]
	,dbix.[SysStart]
FROM [dbo].[DatabaseIndexUsage] 
	FOR SYSTEM_TIME  BETWEEN '2018-09-01 23:00:00.0000000' AND '2018-10-01 23:01:00.0000000'  
	AS dbix
INNER JOIN dbo.MyDatabases AS db ON db.DatabaseId = dbix.DatabaseId
INNER JOIN SQLInstance AS ins ON ins.SQLInstanceID = dbix.SQLInstanceId
INNER JOIN MyServer AS ser ON ser.MyServerId = ins.MyServerId
WHERE
	databaseName = 'buy4_bo'
	AND Servername in ('CHI1B4DB02P01', 'DC1B4DB02P02', 'DC2B4DB02P01')
	and tableName = 'atx_confirmed_transaction'
	AND IndexName = 'IX_SCOPE_ID_TRANSACTION_STATUS_OUTGOING_STATUS_ExpectedBrandPaymentDate_MemberId_Filtered'
ORDER BY IndexName desc, sysstart asc