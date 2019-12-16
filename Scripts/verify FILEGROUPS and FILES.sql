
-------------------------------------
-- Object size for each File of FG --
-------------------------------------

SELECT 
	DS.name AS 'FileGroup' 
	--, AU.type_desc AS AllocationDesc 
	--, OBJ.type_desc AS ObjectType  
	, SCH.name AS SchemaName 
	, OBJ.name AS ObjectName 
	, IDX.type_desc AS IndexType 
	, IDX.name AS IndexName 
	, AU.total_pages / 128 AS TotalSizeMB 
	, AU.used_pages / 128 AS UsedSizeMB 
	, AU.data_pages / 128 AS DataSizeMB 

FROM sys.data_spaces AS DS 
INNER JOIN sys.allocation_units AS AU 
    ON DS.data_space_id = AU.data_space_id 
INNER JOIN sys.partitions AS PA 
	ON (AU.type IN (1, 3)  AND AU.container_id = PA.hobt_id) OR (AU.type = 2 AND AU.container_id = PA.partition_id) 
INNER JOIN sys.objects AS OBJ 
    ON PA.object_id = OBJ.object_id 
INNER JOIN sys.schemas AS SCH 
    ON OBJ.schema_id = SCH.schema_id 
LEFT JOIN sys.indexes AS IDX 
    ON PA.object_id = IDX.object_id AND PA.index_id = IDX.index_id 
WHERE 
	OBJ.type NOT IN ('IT', 'S')
	AND OBJ.name NOT LIKE 'sysdiagrams'
ORDER BY 
	DS.name 
	, SCH.name 
	, OBJ.name 
	, IDX.name

-----------------------------------------
-- FileGroup, file, size and File Path --
-----------------------------------------

SELECT 
    --DB_NAME() 
    --sysfilegroups.groupid AS 'FILEGROUP'
     sysfilegroups.groupname AS 'FileGroup'
	, sysfiles.name AS 'File Name'
    --, fileid 
    , convert(decimal(12,2),round(sysfiles.size/128.000,2)) as file_size_MB
    , convert(decimal(12,2),round(fileproperty(sysfiles.name,'SpaceUsed')/128.000,2)) as space_used_MB
    , convert(decimal(12,2),round((sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed'))/128.000,2)) as free_space_MB
    , sysfiles.filename AS 'File Path'
FROM sys.sysfilegroups 
LEFT OUTER JOIN sys.sysfiles 
    ON sysfiles.groupid = sysfilegroups.groupid
--WHERE sysfilegroups.groupname <> sysfiles.name 
ORDER BY 4 desc




------------------------------------
-- Achar indices fora do FG certo --
------------------------------------

SELECT 
	DS.name AS 'FileGroup' 
	--, AU.type_desc AS AllocationDesc 
	--, OBJ.type_desc AS ObjectType  
	, SCH.name AS SchemaName 
	, OBJ.name AS ObjectName 
	--, IDX.type_desc AS IndexType 
	, IDX.name AS IndexName 
	, AU.total_pages / 128 AS TotalSizeMB 
	, AU.used_pages / 128 AS UsedSizeMB 
	, AU.data_pages / 128 AS DataSizeMB 

FROM sys.data_spaces AS DS 
INNER JOIN sys.allocation_units AS AU 
    ON DS.data_space_id = AU.data_space_id 
INNER JOIN sys.partitions AS PA 
	ON (AU.type IN (1, 3)  AND AU.container_id = PA.hobt_id) OR (AU.type = 2 AND AU.container_id = PA.partition_id) 
INNER JOIN sys.objects AS OBJ 
    ON PA.object_id = OBJ.object_id 
INNER JOIN sys.schemas AS SCH 
    ON OBJ.schema_id = SCH.schema_id 
LEFT JOIN sys.indexes AS IDX 
    ON PA.object_id = IDX.object_id AND PA.index_id = IDX.index_id 
WHERE 
	OBJ.type NOT IN ('IT', 'S')
	AND OBJ.name NOT IN ('sysdiagrams', '__RefactorLog')

	------- Verificar se tem tabela fora de seu FG ou com FG com nome errado --------------
	--AND DS.name <> 'BackOffice_' + OBJ.name + '_dt'
	--AND DS.name <> 'BackOffice_' + OBJ.name + '_ix'
	--------------------- fim ---------------------

	------- ver se tem PK fora de _dt --
	--AND (IDX.type_desc = 'CLUSTERED' AND DS.name NOT LIKE '%_dt' AND DS.name NOT LIKE 'BackOffice_Data')
	--------------------- fim ---------------------

	------- ver se tem index fora de _ix --
	AND (
		(DS.name LIKE '%_dt' AND IDX.type_desc NOT LIKE 'CLUSTERED')
		OR (DS.name LIKE 'BACKOFFICE_DATA' AND IDX.type_desc NOT LIKE 'CLUSTERED'
		OR (DS.name LIKE 'BACKOFFICE_INDEX' AND IDX.type_desc NOT LIKE 'NONCLUSTERED'))
	)
	AND IDX.type_desc NOT LIKE 'CLUSTERED'
	--------------------- fim ---------------------

ORDER BY 
	5 desc,
	DS.name 
	, SCH.name 
	, OBJ.name 
	, IDX.name
