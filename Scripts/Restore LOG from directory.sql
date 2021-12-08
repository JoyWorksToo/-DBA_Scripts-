
/*********************************/
/*******RESTORE LOG ALL DBS*******/
/*********************************/
--Não é para colocar o nome do banco no final do path!
DECLARE @BackupDirectory SYSNAME = '\\P\LOG\'

  IF OBJECT_ID('tempdb..#DirTree') IS NOT NULL
    DROP TABLE #DirTree

  CREATE TABLE #DirTree (
    Id int identity(1,1),
    SubDirectory nvarchar(255),
    Depth smallint,
    FileFlag bit,
    ParentDirectoryID int
   )

   INSERT INTO #DirTree (SubDirectory, Depth, FileFlag)
   EXEC master..xp_dirtree @BackupDirectory, 10, 1

   UPDATE #DirTree
   SET ParentDirectoryID = (
    SELECT MAX(Id) FROM #DirTree d2
    WHERE Depth = d.Depth - 1 AND d2.Id < d.Id
   )
   FROM #DirTree d

  DECLARE 
    @ID INT,
    @BackupFile VARCHAR(MAX),
    @Depth TINYINT,
    @FileFlag BIT,
    @ParentDirectoryID INT,
    @wkSubParentDirectoryID INT,
    @wkSubDirectory VARCHAR(MAX),
	@databaseName VARCHAR(MAX)

  DECLARE @BackupFiles TABLE
  (
    FileNamePath VARCHAR(MAX),
    TransLogFlag BIT,
    BackupFile VARCHAR(MAX),    
    DatabaseName VARCHAR(MAX)
  )

  DECLARE FileCursor CURSOR LOCAL FORWARD_ONLY FOR
  SELECT * FROM #DirTree WHERE FileFlag = 1

  OPEN FileCursor
  FETCH NEXT FROM FileCursor INTO 
    @ID,
    @BackupFile,
    @Depth,
    @FileFlag,
    @ParentDirectoryID  

  SET @wkSubParentDirectoryID = @ParentDirectoryID

  WHILE @@FETCH_STATUS = 0
  BEGIN
    --loop to generate path in reverse, starting with backup file then prefixing subfolders in a loop
    WHILE @wkSubParentDirectoryID IS NOT NULL
    BEGIN
      SELECT @wkSubDirectory = SubDirectory, @wkSubParentDirectoryID = ParentDirectoryID 
      FROM #DirTree 
      WHERE ID = @wkSubParentDirectoryID

      SELECT @BackupFile = @wkSubDirectory + '\' + @BackupFile
    END

    --no more subfolders in loop so now prefix the root backup folder
    SELECT @BackupFile = @BackupDirectory + @BackupFile
	SELECT @databaseName = SubDirectory FROM #DirTree WHERE id = @ParentDirectoryID
    --put backupfile into a table and then later work out which ones are log and full backups  
    INSERT INTO @BackupFiles (FileNamePath, DatabaseName) VALUES(@BackupFile, @databaseName)

    FETCH NEXT FROM FileCursor INTO 
      @ID,
      @BackupFile,
      @Depth,
      @FileFlag,
      @ParentDirectoryID 

    SET @wkSubParentDirectoryID = @ParentDirectoryID      
  END

  CLOSE FileCursor
  DEALLOCATE FileCursor

;WITH LastRestores AS
(
SELECT
    DatabaseName = [d].[name] ,
    [d].[create_date] ,
    [d].[compatibility_level] ,
    [d].[collation_name] ,
	[bf].physical_device_name AS RestoredFrom,
    r.*,

    RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
LEFT OUTER JOIN msdb.dbo.backupset bs ON r.backup_set_id = bs.backup_set_id
LEFT OUTER JOIN msdb.dbo.backupmediafamily bf ON bf.media_set_id = bs.media_set_id 
WHERE
	d.database_id > 4
)
SELECT 
	LR.DatabaseName
	--, RestoredFrom
	--, BF.FileNamePath
	, 'RESTORE LOG ['+ LR.DatabaseName + '] FROM DISK = ''' + BF.FileNamePath + ''' WITH STATS = 5, NORECOVERY'
FROM [LastRestores] as LR
INNER JOIN @BackupFiles as BF
	ON LR.DatabaseName = BF.DatabaseName
	AND LR.RestoredFrom < BF.FileNamePath
WHERE 
	[RowNum] = 1
ORDER BY
	FileNamePath ASC


------

;WITH LastRestores AS
(
SELECT
	@@SERVERNAME AS ServerName,
    DatabaseName = [d].[name] ,
    [d].[create_date] ,
    [d].[compatibility_level] ,
    [d].[collation_name] ,
	bs.backup_finish_date ,
	[bf].physical_device_name AS RestoredFrom,
    
    RowNum = ROW_NUMBER() OVER (PARTITION BY d.Name ORDER BY r.[restore_date] DESC)
FROM master.sys.databases d
LEFT OUTER JOIN msdb.dbo.[restorehistory] r ON r.[destination_database_name] = d.Name
LEFT OUTER JOIN msdb.dbo.backupset bs ON r.backup_set_id = bs.backup_set_id
LEFT OUTER JOIN msdb.dbo.backupmediafamily bf ON bf.media_set_id = bs.media_set_id 
WHERE
	d.database_id > 4
) select *
from LastRestores where RowNum = 1
order by
	backup_finish_date desc
