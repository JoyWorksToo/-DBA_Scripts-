DECLARE @BackupDirectory SYSNAME = 'K:\BackupDB\BOLHA\LOG\'

DECLARE @DBName VARCHAR(128)
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
    @wkSubDirectory VARCHAR(MAX)

  DECLARE @BackupFiles TABLE
  (
    FileNamePath VARCHAR(MAX),
    TransLogFlag BIT,
    BackupFile VARCHAR(MAX),    
    DatabaseName VARCHAR(MAX)
  )

  DECLARE FileCursor CURSOR LOCAL FORWARD_ONLY FOR
  SELECT *,CASE WHEN SubDirectory LIKE '%_backup%' THEN LEFT(SubDirectory, CHARINDEX('_backup', SubDirectory)-1) ELSE NULL END AS DBName FROM #DirTree WHERE FileFlag = 1

  OPEN FileCursor
  FETCH NEXT FROM FileCursor INTO 
    @ID,
    @BackupFile,
    @Depth,
    @FileFlag,
    @ParentDirectoryID,
	@DBName

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

    --put backupfile into a table and then later work out which ones are log and full backups  
    INSERT INTO @BackupFiles (FileNamePath, DatabaseName) VALUES(@BackupFile, @DBName)

    FETCH NEXT FROM FileCursor INTO 
      @ID,
      @BackupFile,
      @Depth,
      @FileFlag,
      @ParentDirectoryID,
	  @DBName

    SET @wkSubParentDirectoryID = @ParentDirectoryID      
  END

  CLOSE FileCursor
  DEALLOCATE FileCursor


  --esse rapaz formoso é pra fazer restore full
  --SELECT 'RESTORE DATABASE [' + DatabaseName + '] FROM DISK = ''' + MAX(FileNamePath) + ''' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10'
  --FROM @BackupFiles
  --GROUP BY DatabaseName

    --Esse garotão aqui é pra restaurar o log. Rapaz bonito, rapaz bem feito, rapaz formoso.
  SELECT DatabaseName, 'RESTORE LOG ['+ DatabaseName + '] FROM DISK = ''' + FileNamePath + ''' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10'
  FROM @BackupFiles
  where FileNamePath NOT LIKE '%feito%'
  ORDER BY DatabaseName asc, FileNamePath ASC
  
  
  
  
  
  
  
Get-ChildItem -Path M:\DataDisks\DataDisk01\MSSQL13.SQL2016\MSSQL\Data -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName
Get-ChildItem -Path M:\DataDisks\DataDisk01\MSSQL13.B4DW01\MSSQL\DATA -Recurse -Directory -Force -ErrorAction SilentlyContinue | Select-Object FullName

DECLARE @BackupDirectory SYSNAME = 'K:\BackupDB\BOLHA\LOG\Buy4_bo\'
DECLARE @DBName VARCHAR(128)
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
    @wkSubDirectory VARCHAR(MAX)

  DECLARE @BackupFiles TABLE
  (
    FileNamePath VARCHAR(MAX),
    TransLogFlag BIT,
    BackupFile VARCHAR(MAX),    
    DatabaseName VARCHAR(MAX)
  )

  DECLARE FileCursor CURSOR LOCAL FORWARD_ONLY FOR
  SELECT *,CASE WHEN SubDirectory LIKE '%_backup%' THEN LEFT(SubDirectory, CHARINDEX('_backup', SubDirectory)-1) ELSE NULL END AS DBName FROM #DirTree WHERE FileFlag = 1

  OPEN FileCursor
  FETCH NEXT FROM FileCursor INTO 
    @ID,
    @BackupFile,
    @Depth,
    @FileFlag,
    @ParentDirectoryID,
	@DBName

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

    --put backupfile into a table and then later work out which ones are log and full backups  
    INSERT INTO @BackupFiles (FileNamePath, DatabaseName) VALUES(@BackupFile, @DBName)

    FETCH NEXT FROM FileCursor INTO 
      @ID,
      @BackupFile,
      @Depth,
      @FileFlag,
      @ParentDirectoryID,
	  @DBName

    SET @wkSubParentDirectoryID = @ParentDirectoryID      
  END

  CLOSE FileCursor
  DEALLOCATE FileCursor


  --esse rapaz formoso é pra fazer restore full
  --SELECT 'RESTORE DATABASE [' + DatabaseName + '] FROM DISK = ''' + MAX(FileNamePath) + ''' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10'
  --FROM @BackupFiles
  --GROUP BY DatabaseName

    --Esse garotão aqui é pra restaurar o log. Rapaz bonito, rapaz bem feito, rapaz formoso.
  SELECT DatabaseName, 'RESTORE LOG ['+ DatabaseName + '] FROM DISK = ''' + FileNamePath + ''' WITH  FILE = 1,  NORECOVERY,  NOUNLOAD,  STATS = 10'
  FROM @BackupFiles
  ORDER BY DatabaseName asc, FileNamePath ASC