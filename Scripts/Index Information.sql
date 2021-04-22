
/*******************************************************************************************/
/*******************************************************************************************/
/*********************************  Index Size  ********************************************/
/*******************************************************************************************/
/*******************************************************************************************/

SELECT
	OBJECT_SCHEMA_NAME(i.OBJECT_ID) AS SchemaName,
	OBJECT_NAME(i.OBJECT_ID) AS TableName,
	i.name AS IndexName,
	i.index_id AS IndexID,
	SUM(a.used_pages)*8./(1024*1024) AS 'Indexsize(GB)',
	SUM(a.used_pages)*8./(1024*1024*1024) AS 'Indexsize(TB)'
FROM sys.indexes AS i
JOIN sys.partitions AS p 
	ON p.OBJECT_ID = i.OBJECT_ID AND p.index_id = i.index_id
JOIN sys.allocation_units AS a 
	ON a.container_id = p.partition_id
GROUP BY 
	i.OBJECT_ID
	, i.index_id
	, i.name
ORDER BY 
	'Indexsize(GB)' desc



/*******************************************************************************************/
/*******************************************************************************************/
/*********************************  Index Size  ********************************************/
/********************************** by partition *******************************************/
/********************************** and compression Type ***********************************/
/*******************************************************************************************/
/*******************************************************************************************/

--Tamanho do índice por partição e se é compressed
	-- SchemaName
	-- TableName
	-- IndexName
	-- Data Compression
SELECT 
	SCHEMA_NAME(t.schema_id) AS SchemaName
	, [t].[name] AS TablaName
	, ISNULL([i].[name], 'HEAP_TABLE_' + [t].[name]) AS IndexName
	, i.index_id
	, [p].[partition_number]
	, tp.total_partition_number
	--, (sz.[used_page_count]) * 8. AS [Index size (KB)]
	
	, FORMAT((((sz.[used_page_count]) * 8.)/1024.), '##.##') AS [Index size (MB)]
	, FORMAT(((sz.[used_page_count]) * 8.)/(1024.*1024.), '.##') AS [Index size (GB)]
	--, ((sz.[used_page_count]) * 8.)/1024. AS [Index size (MB)]
	--, ((sz.[used_page_count]) * 8.)/(1024.*1024.) AS [Index size (GB)]
	
	, CASE WHEN [p].[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE [p].[data_compression_desc] END AS [DataCompression]
	
	, FORMAT(p.[rows],'#,#') AS PartitionRows
	--, p.[rows] AS PartitionRows

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
LEFT JOIN (
	--pegar o numero total de particoes existentes
	SELECT 
		t.schema_id
		, [t].[name] AS TablaName
		, i.index_id
		, MAX([p].[partition_number]) as [total_partition_number]
	FROM [sys].[partitions] AS [p]
	INNER JOIN [sys].[tables] AS [t] 
		ON [t].[object_id] = [p].[object_id]
	INNER JOIN [sys].[indexes] AS i 
		ON p.index_id = i.index_id 
		AND t.object_id = i.object_id
	GROUP BY
		t.schema_id
		, [t].[name] 
		, i.index_id
	) AS tp
	ON tp.schema_id = t.schema_id
	AND tp.TablaName = t.[name]
	AND tp.index_id = i.index_id
--WHERE
--	[i].[name] = 'PK_MTRANSACTION'
ORDER BY 
	sz.[used_page_count] DESC
	, [t].[name] ASC
	, i.index_id ASC
	, p.partition_number asc
	
	
/*******************************************************************************************/
/*******************************************************************************************/
/*********************************  Index Size  ********************************************/
/********************************** by partition *******************************************/
/********************************** and FileGroup ******************************************/
/********************************** and PhysicalFile ***************************************/
/********************************** with FileSIze ******************************************/
/*******************************************************************************************/
/*******************************************************************************************/

SELECT 
		  DS.name AS DataSpaceName
		, SCH.name AS SchemaName
		, OBJ.name AS TableName
		, ISNULL(IDX.name, 'HEAP_TABLE_' + OBJ.name) AS IndexName
		, IDX.index_id AS IndexId
		, PA.partition_number AS PartitionNumber
		, REPLACE (AU.used_pages / 128.,'.',',') AS [IndexSize(MB)]
		, REPLACE (AU.used_pages / (128.*1024.),'.',',') AS [IndexSize(GB)]
		, CASE WHEN PA.[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE PA.[data_compression_desc] END AS [DataCompression]
		
		/*
		, REPLACE( CASE WHEN PA.[data_compression_desc] <> 'PAGE' THEN
			  CASE WHEN (AU.used_pages / (128.*1024.)) < 1000 
				THEN AU.used_pages * 8. * 0.3 
				ELSE AU.used_pages * 8. END
		  ELSE AU.used_pages * 8. 
		  END,'.',',') AS [ApproximateCompression(KB)]
		*/
		--, f.physical_name
		, f.name AS FileLogicalName
		, SUBSTRING(f.physical_name, 14, 10) AS DataDisk
		, (cast(f.size as bigint) * 8) / (1024.*1024.) AS [FILESize(GB)]
		
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
	INNER JOIN sys.indexes AS IDX
		ON PA.object_id = IDX.object_id
		AND PA.index_id = IDX.index_id
	WHERE
		OBJ.type NOT IN ('IT', 'S')
		AND au.type_desc = 'IN_ROW_DATA'
		--AND OBJ.name = 'amr_movement'
		--and idx.name = 'IX_AMR_MOVEMENT'

	
/*******************************************************************************************/
/*******************************************************************************************/
/*********************************  Index Size  ********************************************/
/********************************** by partition *******************************************/
/********************************** and FileGroup ******************************************/
/********************************** and PhysicalFile ***************************************/
/********************************** with FileSIze ******************************************/
/*********************************** agrupado por DataDisk *********************************/
/*******************************************************************************************/
/*******************************************************************************************/


SELECT *
FROM (
	SELECT 
			  DS.name AS FileGroupName
			, SCH.name AS SchemaName
			, OBJ.name AS TableName
			, ISNULL(IDX.name, 'HEAP_TABLE_' + OBJ.name) AS IndexName
			, IDX.index_id AS IndexId
			, PA.partition_number AS PartitionNumber
			, REPLACE (AU.used_pages / 128.,'.',',') AS [IndexSize(MB)]
			, REPLACE (AU.used_pages / (128.*1024.),'.',',') AS [IndexSize(GB)]
			, CASE WHEN PA.[data_compression_desc] = 'PAGE' THEN 'PAGE_COMPRESSION' ELSE PA.[data_compression_desc] END AS [DataCompression]
		
			/*
			, REPLACE( CASE WHEN PA.[data_compression_desc] <> 'PAGE' THEN
				  CASE WHEN (AU.used_pages / (128.*1024.)) < 1000 
					THEN AU.used_pages * 8. * 0.3 
					ELSE AU.used_pages * 8. END
			  ELSE AU.used_pages * 8. 
			  END,'.',',') AS [ApproximateCompression(KB)]
			*/
			--, f.physical_name
			, f.name AS FileLogicalName
			--, SUBSTRING(f.physical_name, 14, 10) AS DataDisk
			, (cast(f.size as bigint) * 8) / (1024.*1024.) AS [FILESize(GB)]
		
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
		INNER JOIN sys.indexes AS IDX
			ON PA.object_id = IDX.object_id
			AND PA.index_id = IDX.index_id
		WHERE
			OBJ.type NOT IN ('IT', 'S')
			AND au.type_desc = 'IN_ROW_DATA'
			--AND OBJ.name = 'amr_movement'
			--and idx.name = 'IX_AMR_MOVEMENT'
) AS Grouped
GROUP BY
	SchemaName
	, TableName
	, IndexName
	, IndexId
	, PartitionNumber
	, [IndexSize(MB)]
	, [IndexSize(GB)]
	, FileGroupName
	, DataCompression
	, DataDisksList
	, FileLogicalName, [FILESize(GB)]
ORDER BY 
	TableName ASC
	, IndexId ASC
	, PartitionNumber ASC
	