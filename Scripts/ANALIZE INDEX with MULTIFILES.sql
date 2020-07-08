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
	
	