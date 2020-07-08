

SELECT *, 'RESTORE DATABASE [' + database_name + '] FROM DISK = ''' + physical_device_name + ''' WITH NORECOVERY, STATS = 5;'
FROM (
	SELECT 
		a.database_name
		, a.backup_finish_date
		, b.physical_device_name
		, CASE a.[type] -- Let's decode the three main types of backup here
			 WHEN 'D' THEN 'Full'
			 WHEN 'I' THEN 'Differential'
			 WHEN 'L' THEN 'Transaction Log'
			 ELSE a.[type]
			END as BackupType
		, ROW_NUMBER() OVER(PARTITION BY a.database_name ORDER BY a.backup_finish_date DESC) AS RowNo
	FROM msdb.dbo.backupset a 
	INNER JOIN msdb.dbo.backupmediafamily b
		ON a.media_set_id = b.media_set_id
	WHERE
		a.type = 'D'
) AS x
WHERE x.RowNo = 1
	AND database_name not in ('master', 'model', 'msdb')
GO

SELECT *, 'RESTORE DATABASE [' + database_name + '] FROM DISK = ''' + physical_device_name + ''' WITH NORECOVERY, STATS = 5;'
FROM (
	SELECT 
		a.database_name
		, a.backup_finish_date
		, b.physical_device_name
		, CASE a.[type] -- Let's decode the three main types of backup here
			 WHEN 'D' THEN 'Full'
			 WHEN 'I' THEN 'Differential'
			 WHEN 'L' THEN 'Transaction Log'
			 ELSE a.[type]
			END as BackupType
		, ROW_NUMBER() OVER(PARTITION BY a.database_name ORDER BY a.backup_finish_date DESC) AS RowNo
	FROM msdb.dbo.backupset a 
	INNER JOIN msdb.dbo.backupmediafamily b
		ON a.media_set_id = b.media_set_id
	WHERE
		a.type = 'I'
) AS x
WHERE x.RowNo = 1
	AND database_name not in ('master', 'model', 'msdb')
GO


SELECT 
	a.database_name
	, a.backup_finish_date
	, b.physical_device_name
	, CASE a.[type] -- Let's decode the three main types of backup here
			WHEN 'D' THEN 'Full'
			WHEN 'I' THEN 'Differential'
			WHEN 'L' THEN 'Transaction Log'
			ELSE a.[type]
		END as BackupType
	, 'RESTORE LOG [' + database_name + '] FROM DISK = ''' + physical_device_name + ''' WITH NORECOVERY, STATS = 5;'
FROM msdb.dbo.backupset a 
INNER JOIN msdb.dbo.backupmediafamily b
	ON a.media_set_id = b.media_set_id
WHERE
	a.type = 'L'
	AND a.backup_finish_date >= DATEADD(DD, -1, GETDATE())
ORDER BY
	database_name ASC,
	backup_finish_date ASC
