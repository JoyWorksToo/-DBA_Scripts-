
/****/
/* Tamanho dos bancos */
/****/
SELECT [Database Name] = DB_NAME(database_id),
       [Type] = CASE WHEN Type_Desc = 'ROWS' THEN 'Data File(s)'
                     WHEN Type_Desc = 'LOG'  THEN 'Log File(s)'
                     ELSE Type_Desc END,
       [Size in GB] = CAST( ((SUM(CAST(Size AS BIGINT))* 8) / (1024*1024.0)) AS DECIMAL(18,2) )
FROM   sys.master_files
WHERE database_id > 4
GROUP BY      GROUPING SETS
              (
                     (DB_NAME(database_id), Type_Desc),
                     (DB_NAME(database_id))
              )
ORDER BY      DB_NAME(database_id), Type_Desc DESC
GO

/****/
/* Pega as infos dos discos */
/****/

SELECT DISTINCT 
	dovs.logical_volume_name AS LogicalName,
	dovs.volume_mount_point AS Drive,
	dovs.total_bytes/1048576.0/1024 AS DiskSize_GB,
	dovs.available_bytes/1048576.0/1024 AS DiskFreeSpace_GB,
	(dovs.total_bytes-dovs.available_bytes)/1048576.0/1024 AS DiskUsedSpace_GB
FROM sys.master_files mf
CROSS APPLY sys.dm_os_volume_stats(mf.database_id, mf.FILE_ID) dovs
--WHERE dovs.logical_volume_name like '%DataDisk%'
ORDER BY LogicalName ASC
GO
