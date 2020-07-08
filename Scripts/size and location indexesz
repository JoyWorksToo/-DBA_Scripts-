USE Buy4_bo
GO
--especifico para backoffice com arquivos em datadisk diferentes. Eu pego o tamanho total de cada objeto e digo aonde ele tá
SELECT *
FROM (
	SELECT 
		SCH.name AS SchemaName
		, OBJ.name AS ObjectName
		, ISNULL(IDX.name, 'HEAP_TABLE_' + OBJ.name) AS IndexName
		, IDX.index_id AS IndexId
		, PA.partition_number AS PartitionNumber
		, REPLACE (AU.used_pages * 8.,'.',',') AS [UsedSize(KB)]
		, REPLACE (AU.used_pages / 128.,'.',',') AS [UsedSize(MB)]
		, REPLACE (AU.used_pages / (128.*1024.),'.',',') AS [UsedSize(GB)]
		, REPLACE( CASE WHEN PA.[data_compression_desc] <> 'PAGE' THEN
			  CASE WHEN (AU.used_pages / (128.*1024.)) < 1000 
				THEN AU.used_pages * 8. * 0.3 
				ELSE AU.used_pages * 8. END
		  ELSE AU.used_pages * 8. 
		  END,'.',',') AS [ApproximateCompression(KB)]
		--, au.*
		, DS.name AS DataSpaceName
		--, f.physical_name
		--, SUBSTRING(f.physical_name, 14, 10) AS DataDisk
		--, AU.type_desc AS AllocationDesc
		--, IDX.type_desc AS IndexType
		, CASE WHEN PA.[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE PA.[data_compression_desc] END AS [DataCompression]
		, STUFF((
			SELECT DISTINCT
				'/ ' + SUBSTRING(F_INNER.physical_name, 14, 10)
			FROM sys.database_files F_INNER
			WHERE AU.data_space_id = F_INNER.data_space_id
			FOR XML PATH('')), 1, 1, '') AS DataDisksList
		
	FROM sys.data_spaces AS DS
	INNER JOIN sys.allocation_units AS AU
		ON DS.data_space_id = AU.data_space_id
	INNER JOIN sys.partitions AS PA
		ON (AU.type IN (1, 3) AND AU.container_id = PA.hobt_id)
		OR (AU.type = 2 AND AU.container_id = PA.partition_id)
	JOIN sys.database_files f
		on AU.data_space_id = f.data_space_id
	INNER JOIN sys.objects AS OBJ
		ON PA.object_id = OBJ.object_id
	INNER JOIN sys.schemas AS SCH
		ON OBJ.schema_id = SCH.schema_id
	LEFT JOIN sys.indexes AS IDX
		ON PA.object_id = IDX.object_id
		AND PA.index_id = IDX.index_id
	WHERE
		OBJ.type NOT IN ('IT', 'S')
		AND au.type_desc = 'IN_ROW_DATA'
		--AND OBJ.name  like 'ATX_CONFIRMED_TRANSACTION'
		--AND PA.data_compression_desc = 'NONE'
		--AND (AU.used_pages / 128) > 0
	--ORDER BY AU.total_pages desc -- Order by size
) AS Grouped
GROUP BY
	SchemaName
	, ObjectName
	, IndexName
	, IndexId
	, PartitionNumber
	, [UsedSize(KB)]
	, [UsedSize(MB)]
	, [UsedSize(GB)]
	, [ApproximateCompression(KB)]
	, DataSpaceName
	, DataCompression
	, DataDisksList
ORDER BY 
	ObjectName ASC
	, IndexId ASC
	, PartitionNumber ASC



SELECT 
	SCHEMA_NAME(t.schema_id) AS SchemaName
	, [t].[name] AS TablaName
	, ISNULL([i].[name], 'HEAP_TABLE_' + [t].[name]) AS IndexName
	, i.index_id
	, [p].[partition_number]
	, (sz.[used_page_count]) * 8. AS [Index size (KB)]
	, ((sz.[used_page_count]) * 8.)/1024. AS [Index size (MB)]
	, ((sz.[used_page_count]) * 8.)/(1024.*1024.) AS [Index size (GB)]
	, CASE WHEN [p].[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE [p].[data_compression_desc] END AS [DataCompression]
	, *
FROM [sys].[partitions] AS [p]
INNER JOIN [sys].[tables] AS [t] 
	ON [t].[object_id] = [p].[object_id]
INNER JOIN [sys].[indexes] AS i 
	ON p.index_id = i.index_id 
	AND t.object_id = i.object_id
INNER JOIN [sys].[dm_db_partition_stats] AS sz
	ON sz.[object_id] = i.[object_id] 
	AND sz.[index_id] = i.[index_id]
	AND sz.partition_id = p.partition_id
--WHERE
	--OBJECT_NAME(i.OBJECT_ID)  = 'ATX_CONFIRMED_TRANSACTION' AND
	--OBJECT_NAME(i.OBJECT_ID)  = 'AMR_MOVEMENT' --AND
	--OBJECT_NAME(i.OBJECT_ID) NOT IN ('AMR_MOVEMENT','ATX_CONFIRMED_TRANSACTION') AND
	--[p].[data_compression_desc] = 'NONE'
ORDER BY 
	--[Index size (KB)] DESC
	TablaName ASC
	, i.index_id ASC
	, p.partition_number asc

USE Receivables
SELECT 
	SCH.name AS SchemaName
	, OBJ.name AS ObjectName
	, ISNULL(IDX.name, 'HEAP_TABLE_' + OBJ.name) AS IndexName
	, IDX.index_id AS IndexId
	, PA.partition_number AS PartitionNumber
	, AU.used_pages * 8. AS [UsedSize(KB)]
	, AU.used_pages / 128. AS [UsedSize(MB)]
	, AU.used_pages / (128.*1024.) AS [UsedSize(GB)]
	, CASE WHEN (AU.used_pages / (128.*1024.)) < 1000 THEN AU.used_pages * 8. * 0.3 ELSE AU.used_pages * 8. END AS [ApproximateCompression(KB)]
	, DS.name AS DataSpaceName
	, f.physical_name
	, SUBSTRING(f.physical_name, 14, 10) AS DataDisk
	, AU.type_desc AS AllocationDesc
	, IDX.type_desc AS IndexType
	, CASE WHEN PA.[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE PA.[data_compression_desc] END AS [DataCompression]
FROM sys.data_spaces AS DS
INNER JOIN sys.allocation_units AS AU
	ON DS.data_space_id = AU.data_space_id
INNER JOIN sys.partitions AS PA
	ON (AU.type IN (1, 3) AND AU.container_id = PA.hobt_id)
	OR (AU.type = 2 AND AU.container_id = PA.partition_id)
JOIN sys.database_files f
	on AU.data_space_id = f.data_space_id
INNER JOIN sys.objects AS OBJ
	ON PA.object_id = OBJ.object_id
INNER JOIN sys.schemas AS SCH
	ON OBJ.schema_id = SCH.schema_id
LEFT JOIN sys.indexes AS IDX
	ON PA.object_id = IDX.object_id
	AND PA.index_id = IDX.index_id
WHERE
	OBJ.type NOT IN ('IT', 'S')
	AND au.type_desc = 'IN_ROW_DATA'
	--AND OBJ.name  like 'ATX_CONFIRMED_TRANSACTION'
	--AND PA.data_compression_desc = 'NONE'
	--AND (AU.used_pages / 128) > 0
ORDER BY 
	ObjectName asc
	, IndexId asc
	, PartitionNumber asc


SELECT 
	SCHEMA_NAME(t.schema_id) AS SchemaName
	, [t].[name] AS TablaName
	, ISNULL([i].[name], 'HEAP_TABLE_' + [t].[name]) AS IndexName
	, i.index_id
	, [p].[partition_number]
	, (sz.[used_page_count]) * 8. AS [Index size (KB)]
	, ((sz.[used_page_count]) * 8.)/1024. AS [Index size (MB)]
	, ((sz.[used_page_count]) * 8.)/(1024.*1024.) AS [Index size (GB)]
	, CASE WHEN [p].[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE [p].[data_compression_desc] END AS [DataCompression]
	, *
FROM [sys].[partitions] AS [p]
INNER JOIN [sys].[tables] AS [t] 
	ON [t].[object_id] = [p].[object_id]
INNER JOIN [sys].[indexes] AS i 
	ON p.index_id = i.index_id 
	AND t.object_id = i.object_id
INNER JOIN [sys].[dm_db_partition_stats] AS sz
	ON sz.[object_id] = i.[object_id] 
	AND sz.[index_id] = i.[index_id]
	AND sz.partition_id = p.partition_id
--WHERE
	--OBJECT_NAME(i.OBJECT_ID)  = 'ATX_CONFIRMED_TRANSACTION' AND
	--OBJECT_NAME(i.OBJECT_ID)  = 'AMR_MOVEMENT' --AND
	--OBJECT_NAME(i.OBJECT_ID) NOT IN ('AMR_MOVEMENT','ATX_CONFIRMED_TRANSACTION') AND
	--[p].[data_compression_desc] = 'NONE'
ORDER BY 
	--[Index size (KB)] DESC
	TablaName ASC
	, i.index_id ASC
	, p.partition_number asc
	
	

USE ClearingElo
GO

SELECT *
FROM (
	SELECT 
		SCH.name AS SchemaName
		, OBJ.name AS ObjectName
		, ISNULL(IDX.name, 'HEAP_TABLE_' + OBJ.name) AS IndexName
		, IDX.index_id AS IndexId
		, PA.partition_number AS PartitionNumber
		, REPLACE (AU.total_pages * 8.,'.',',') AS [UsedSize(KB)]
		, REPLACE (AU.total_pages / 128.,'.',',') AS [UsedSize(MB)]
		, REPLACE (AU.total_pages / (128.*1024.),'.',',') AS [UsedSize(GB)]
		, REPLACE( CASE WHEN PA.[data_compression_desc] <> 'PAGE' THEN
			  CASE WHEN (AU.used_pages / (128.*1024.)) < 1000 
				THEN AU.used_pages * 8. * 0.3 
				ELSE AU.used_pages * 8. END
		  ELSE AU.used_pages * 8. 
		  END,'.',',') AS [ApproximateCompression(KB)]
		--, au.*
		, DS.name AS DataSpaceName
		--, f.physical_name
		--, SUBSTRING(f.physical_name, 14, 10) AS DataDisk
		--, AU.type_desc AS AllocationDesc
		--, IDX.type_desc AS IndexType
		, CASE WHEN PA.[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE PA.[data_compression_desc] END AS [DataCompression]
		, STUFF((
			SELECT DISTINCT
				'/ ' + SUBSTRING(F_INNER.physical_name, 14, 10)
			FROM sys.database_files F_INNER
			WHERE AU.data_space_id = F_INNER.data_space_id
			FOR XML PATH('')), 1, 1, '') AS DataDisksList
		
	FROM sys.data_spaces AS DS
	INNER JOIN sys.allocation_units AS AU
		ON DS.data_space_id = AU.data_space_id
	INNER JOIN sys.partitions AS PA
		ON (AU.type IN (1, 3) AND AU.container_id = PA.hobt_id)
		OR (AU.type = 2 AND AU.container_id = PA.partition_id)
	JOIN sys.database_files f
		on AU.data_space_id = f.data_space_id
	INNER JOIN sys.objects AS OBJ
		ON PA.object_id = OBJ.object_id
	INNER JOIN sys.schemas AS SCH
		ON OBJ.schema_id = SCH.schema_id
	LEFT JOIN sys.indexes AS IDX
		ON PA.object_id = IDX.object_id
		AND PA.index_id = IDX.index_id
	WHERE
		OBJ.type NOT IN ('IT', 'S')
		--AND au.type_desc = 'IN_ROW_DATA'
		--AND OBJ.name  like 'ATX_CONFIRMED_TRANSACTION'
		--AND PA.data_compression_desc = 'NONE'
		--AND (AU.used_pages / 128) > 0
	--ORDER BY AU.total_pages desc -- Order by size
) AS Grouped
GROUP BY
	SchemaName
	, ObjectName
	, IndexName
	, IndexId
	, PartitionNumber
	, [UsedSize(KB)]
	, [UsedSize(MB)]
	, [UsedSize(GB)]
	, [ApproximateCompression(KB)]
	, DataSpaceName
	, DataCompression
	, DataDisksList
ORDER BY 
	ObjectName ASC
	, IndexId ASC
	, PartitionNumber ASC


--SELECT
--	SUM([UsedSize(KB)]) as Kb
--	, SUM([UsedSize(MB)]) as Mb
--	, SUM([UsedSize(GB)]) as Gb
--	, SUM([UsedTotalSize(KB)]) as [UsedTotalSize(KB)]
--	, SUM([UsedTotalSize(KB)]/1024) as [UsedTotalSize(MB)]
--FROM (
--	SELECT *
--FROM (
--	SELECT 
--		SCH.name AS SchemaName
--		, OBJ.name AS ObjectName
--		, ISNULL(IDX.name, 'HEAP_TABLE_' + OBJ.name) AS IndexName
--		, IDX.index_id AS IndexId
--		, PA.partition_number AS PartitionNumber
--		, (AU.total_pages * 8.) AS [UsedSize(KB)]
--		, (AU.total_pages / 128.) AS [UsedSize(MB)]
--		, (AU.total_pages / (128.*1024.)) AS [UsedSize(GB)]
--		, au.total_pages * 8. AS [UsedTotalSize(KB)]
--		, REPLACE( CASE WHEN PA.[data_compression_desc] <> 'PAGE' THEN
--			  CASE WHEN (AU.used_pages / (128.*1024.)) < 1000 
--				THEN AU.used_pages * 8. * 0.3 
--				ELSE AU.used_pages * 8. END
--		  ELSE AU.used_pages * 8. 
--		  END,'.',',') AS [ApproximateCompression(KB)]
--		--, au.*
--		, DS.name AS DataSpaceName
--		--, f.physical_name
--		--, SUBSTRING(f.physical_name, 14, 10) AS DataDisk
--		--, AU.type_desc AS AllocationDesc
--		--, IDX.type_desc AS IndexType
--		, CASE WHEN PA.[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE PA.[data_compression_desc] END AS [DataCompression]
--		, STUFF((
--			SELECT DISTINCT
--				'/ ' + SUBSTRING(F_INNER.physical_name, 14, 10)
--			FROM sys.database_files F_INNER
--			WHERE AU.data_space_id = F_INNER.data_space_id
--			FOR XML PATH('')), 1, 1, '') AS DataDisksList
		
--	FROM sys.data_spaces AS DS
--	INNER JOIN sys.allocation_units AS AU
--		ON DS.data_space_id = AU.data_space_id
--	INNER JOIN sys.partitions AS PA
--		ON (AU.type IN (1, 3) AND AU.container_id = PA.hobt_id)
--		OR (AU.type = 2 AND AU.container_id = PA.partition_id)
--	JOIN sys.database_files f
--		on AU.data_space_id = f.data_space_id
--	INNER JOIN sys.objects AS OBJ
--		ON PA.object_id = OBJ.object_id
--	INNER JOIN sys.schemas AS SCH
--		ON OBJ.schema_id = SCH.schema_id
--	LEFT JOIN sys.indexes AS IDX
--		ON PA.object_id = IDX.object_id
--		AND PA.index_id = IDX.index_id
--	WHERE
--		OBJ.type NOT IN ('IT', 'S')
--		AND au.type_desc = 'IN_ROW_DATA'
--		--AND OBJ.name  like 'ATX_CONFIRMED_TRANSACTION'
--		--AND PA.data_compression_desc = 'NONE'
--		--AND (AU.used_pages / 128) > 0
--	--ORDER BY AU.total_pages desc -- Order by size
--) AS Grouped
--GROUP BY
--	SchemaName
--	, ObjectName
--	, IndexName
--	, IndexId
--	, PartitionNumber
--	, [UsedSize(KB)]
--	, [UsedSize(MB)]
--	, [UsedSize(GB)]
--	, [UsedTotalSize(KB)]
--	, [ApproximateCompression(KB)]
--	, DataSpaceName
--	, DataCompression
--	, DataDisksList
----ORDER BY 
----	ObjectName ASC
----	, IndexId ASC
----	, PartitionNumber ASC
--) as x

