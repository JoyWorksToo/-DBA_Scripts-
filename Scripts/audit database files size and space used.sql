DECLARE @command varchar(8000) 

SELECT @command = 'IF ''?'' NOT IN(''master'', ''model'', ''msdb'', ''tempdb'') BEGIN USE ? 
INSERT INTO master.dbo.FileSizeDBs (DatabaseName, FileName, FileSizeInPage, FileSpaceUsedInPage)
   SELECT 
	DB_NAME() AS DatabaseName
	, [name]
	, size AS FileSizeInPage
	, fileproperty([name],''SpaceUsed'') AS FileSpaceUsedInPage
FROM sys.database_files
WHERE
	type_desc <> ''LOG''
END
' 

EXEC sp_MSforeachdb @command 