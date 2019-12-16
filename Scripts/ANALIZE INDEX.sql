

----------------------------------------------------------
------------------------- INDEX --------------------------
----------------------------------------------------------

sp_helpindex 'BUY4_RECEIVABLES_ADVANCE'


----------------------------------------------------------
---------------------- FRAGMENTAÇÃO ----------------------
---------------------- POR TABELA ------------------------
----------------------------------------------------------

SELECT dbschemas.[name] as 'Schema', 
dbtables.[name] as 'Table', 
dbindexes.[name] as 'Index',
indexstats.avg_fragmentation_in_percent,
indexstats.page_count
FROM sys.dm_db_index_physical_stats (DB_ID('Buy4_bo'), OBJECT_ID('BUY4_RECEIVABLES_ADVANCE'), NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
-- AND dbindexes.is_primary_key = 0 -- não é PK
ORDER BY indexstats.avg_fragmentation_in_percent desc


----------------------------------------------------------
------------------ INDEX USAGE AND SIZE ------------------
----------------------------------------------------------

USE Buy4_bo
SELECT
    DB_NAME(database_id) As Banco
	, OBJECT_NAME(I.object_id) As Tabela
	, I.Name As Indice
    , U.User_Seeks As Pesquisas
	, U.User_Scans As Varreduras
	, U.User_Lookups As LookUps
    , U.Last_User_Seek As UltimaPesquisa
	, U.Last_User_Scan As UltimaVarredura
    , U.Last_User_LookUp As UltimoLookUp
	, U.Last_User_Update As UltimaAtualizacao
	,8 * (a.used_pages) AS 'Indexsize(KB)'
FROM
    sys.indexes As I
	JOIN sys.partitions AS p ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
	JOIN sys.allocation_units AS a ON a.container_id = p.partition_id
    LEFT OUTER JOIN sys.dm_db_index_usage_stats As U
		ON I.object_id = U.object_id AND I.index_id = U.index_id
WHERE 
	I.object_id = OBJECT_ID('dbo.BUY4_RECEIVABLES_ADVANCE') --colocar SCHEMA também
	AND DB_NAME(database_id) = 'buy4_bo' --database
order by 4 desc ,5 desc

----------------------------------------------------------
----------------- STATISTICS LAST UPDATED ----------------
----------------------------------------------------------

 SELECT
OBJECT_NAME([sp].[object_id]) AS "Table",
[sp].[stats_id] AS "Statistic ID",
[s].[name] AS "Statistic",
[sp].[last_updated] AS "Last Updated",
[sp].[rows],
[sp].[rows_sampled],
[sp].[unfiltered_rows],
[sp].[modification_counter] AS "Modifications"
,'UPDATE STATISTICS ' + OBJECT_NAME([sp].[object_id]) + ' ' + [s].[name]
,'DBCC SHOW_STATISTICS ( ' + OBJECT_NAME([sp].[object_id]) + ', ' + [s].[name] +')'
FROM [sys].[stats] AS [s]
OUTER APPLY sys.dm_db_stats_properties ([s].[object_id],[s].[stats_id]) AS [sp]
WHERE 
OBJECT_NAME([sp].[object_id]) = 'atx_confirmed_transaction'
-- and [sp].[last_updated] >= GETDATE()-7
ORDER BY [sp].[last_updated] ASC


----------------------------------------------------------
--------------------- DISABLED INDEX ---------------------
----------------------------------------------------------

select
    sys.objects.name,
    sys.indexes.name
from sys.indexes
    inner join sys.objects on sys.objects.object_id = sys.indexes.object_id
where sys.indexes.is_disabled = 1
order by
    sys.objects.name,
    sys.indexes.name

	
	
----------------------------------------------------------
---------------------- FRAGMENTAÇÃO ----------------------
---------------------- POR TABELA ------------------------
--------------------- COM REORGANIZE ---------------------
----------------------------------------------------------	
	
	
SELECT dbschemas.[name] as 'Schema', 
dbtables.[name] as 'Table', 
dbindexes.[name] as 'Index',
indexstats.avg_fragmentation_in_percent,
indexstats.page_count,

'ALTER INDEX ' + dbindexes.[name] + ' ON ' + dbschemas.[name] + '.' + dbtables.[name] + ' REORGANIZE'

FROM sys.dm_db_index_physical_stats (DB_ID('Buy4_bo'), OBJECT_ID('BUY4_RECEIVABLES_ADVANCE'), NULL, NULL, NULL) AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE indexstats.database_id = DB_ID()
 AND dbindexes.is_primary_key = 0 -- não é PK
ORDER BY indexstats.avg_fragmentation_in_percent desc




----------------------------------------------------------------------------------
---------------------- IDEX KEYS, INCLUDES, FILTERS, ETC... ----------------------
-------------------------------- SIZE AND USAGE ----------------------------------
----------------------------------------------------------------------------------

--Se quiser todas as colunas, apenas deixar como null
DECLARE @TableName VARCHAR(128) = NULL
--DECLARE @TableName VARCHAR(128) = 'Settlement'

;WITH Columnsqry AS
    (SELECT 
		name
		, ic.object_id
		, ic.index_id
		, is_included_column
		, ic.key_ordinal
    FROM sys.index_columns IC
	JOIN sys.columns c
		ON ic.object_id=c.object_id 
		AND ic.column_id = c.column_id 
	), 
    IndexQry AS
    (SELECT 
		I.object_id
		, I.index_id
		, (
			SELECT STUFF((SELECT ',' + name AS [text()] 
			FROM Columnsqry q
            WHERE 
				q.object_id = I.object_id
				AND q.index_id = i.index_id 
				AND q.is_included_column = 0
				AND q.key_ordinal > 0 --Key_ordinal = 0 = Not a key column
            ORDER BY q.key_ordinal
            FOR XML PATH('')),1,1,'')) AS Keys
		, (
			SELECT STUFF((SELECT ',' + name AS [text()] FROM Columnsqry q
            WHERE 
				q.object_id = I.object_id
				AND q.index_id = i.index_id 
				AND q.is_included_column=1
            FOR XML PATH('')),1,1,'')) AS Included 
    FROM Columnsqry q
	JOIN sys.indexes I
		ON q.object_id = I.object_id 
		AND q.index_id = I.index_id 
	JOIN sys.objects o
		ON o.object_id = I.object_id 
    WHERE
		O.type not in ('S','IT')
    GROUP BY
		I.object_id
		, I.index_id
	)
SELECT 
	  isnull(DB_NAME(database_id), DB_NAME(db_id())) AS [DatabaseName]
	, o.name AS TableName
	, I.name AS [IndexName]
	, iq.Index_id
	, I.type_desc AS IndexType
	, ds.name as GroupName
	, Keys
	, Included
	, is_unique
	, fill_factor
	, is_padded
	, has_filter
	, filter_definition
	, U.User_Seeks As Seeks
	, U.User_Scans As Scans
	, U.User_Lookups As LookUps
    , U.Last_User_Seek As LastSeek
	, U.Last_User_Scan As LastScan
    , U.Last_User_LookUp As LastLookUp
	, U.Last_User_Update As LastUpdate
	, ixSize.[Indexsize(GB)]
	, ixSize.[Indexsize(MB)]
FROM IndexQry IQ
JOIN sys.objects AS o
		ON IQ.object_id = o.object_id 
JOIN sys.indexes AS I
		ON IQ.object_id = I.object_id 
		AND IQ.Index_id = I.index_id
JOIN sys.data_spaces ds
		ON i.data_space_id = ds.data_space_id
LEFT OUTER JOIN sys.dm_db_index_usage_stats AS U
		ON I.object_id = U.object_id 
		AND I.index_id = U.index_id
		AND (u.database_id = db_id()) --Necessario para pegar so os indexes do banco atual.
JOIN(
	SELECT
		i.OBJECT_ID,
		i.name AS IndexName,
		i.index_id AS IndexID,
		CAST(8 * SUM(a.used_pages)/(1024*1024.0) AS DECIMAL(8,2)) AS 'Indexsize(GB)',
		CAST(8 * SUM(a.used_pages)/(1024.0) AS DECIMAL(18,2)) AS 'Indexsize(MB)'
	FROM sys.indexes AS i
	JOIN sys.partitions AS p 
		ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
	JOIN sys.allocation_units AS a 
		ON a.container_id = p.partition_id
	GROUP BY 
		i.OBJECT_ID,i.index_id,i.name
) AS ixSize 
		ON ixSize.IndexID = IQ.Index_id
		AND ixSize.OBJECT_ID = IQ.object_id
WHERE
	(@TableName  = O.name OR @TableName IS NULL)
ORDER BY
	TableName ASC
	, iq.index_id ASC