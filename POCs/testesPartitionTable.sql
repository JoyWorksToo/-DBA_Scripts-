use master

/*
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_FgPrev;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg01;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg02;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg03;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg04;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg05;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg06;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg07;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg08;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg09;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg10;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg11;
GO
ALTER DATABASE [PartitionTableDemo] ADD FILEGROUP PartDate_Fg12;
GO

ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_FgPrev], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_FgPrev.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_FgPrev];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg01], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg01.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg01];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg02], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg02.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg02];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg03], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg03.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg03];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg04], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg04.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg04];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg05], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg05.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg05];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg06], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg06.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg06];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg07], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg07.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg07];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg08], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg08.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg08];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg09], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg09.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg09];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg10], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg10.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg10];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg11], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg11.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg11];
GO
ALTER DATABASE [PartitionTableDemo] ADD FILE (NAME = [PartDate_Fg12], FILENAME = 'D:\Databases\PartitionTableDemo\PartDate_Fg12.ndf', SIZE = 65536KB , FILEGROWTH = 65536KB ) TO FILEGROUP [PartDate_Fg12];
GO

CREATE PARTITION FUNCTION [PartitionedByDateId_PF](datetime) AS RANGE RIGHT
FOR VALUES (							N'2019-04-01T00:00:00.000', N'2019-07-01T00:00:00.000', N'2019-09-01T00:00:00.000', 
			N'2020-01-01T00:00:00.000', N'2020-04-01T00:00:00.000', N'2020-07-01T00:00:00.000', N'2020-09-01T00:00:00.000', 
            N'2021-01-01T00:00:00.000', N'2021-04-01T00:00:00.000', N'2021-07-01T00:00:00.000', N'2021-09-01T00:00:00.000', 
            N'2022-01-01T00:00:00.000')
GO

CREATE PARTITION SCHEME [PartitionedByDateId_PS] AS PARTITION [PartitionedByDateId_PF] TO (
	PartDate_FgPrev, PartDate_Fg01, PartDate_Fg02, PartDate_Fg03,
	PartDate_Fg04, PartDate_Fg05, PartDate_Fg06,
	PartDate_Fg07, PartDate_Fg08, PartDate_Fg09,
	PartDate_Fg10, PartDate_Fg11, PartDate_Fg12
)
GO
*/

/*
DROP TABLE IF EXISTS PartitionedByDateId 
DROP TABLE IF EXISTS PartitionedByIdDate 
DROP TABLE IF EXISTS ExternalReferenceTable 
*/

CREATE TABLE ExternalReferenceTable (
	Id INT NOT NULL,
	[MyGuid] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),

	CONSTRAINT [PK_ExternalReferenceTable] PRIMARY KEY CLUSTERED (Id)
)
GO

INSERT INTO ExternalReferenceTable (Id) VALUES (1), (2)
GO

CREATE TABLE PartitionedByDateId (
	[Id] BIGINT IDENTITY(1,1) NOT NULL,
	[MyDate] DATETIME NOT NULL,
	[RandomInt] INT NOT NULL,
	[RandomString] VARCHAR(128) NOT NULL,
	[MyGuid] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
	[ExternalId] INT NULL

	CONSTRAINT [PK_PartitionedByDateId] PRIMARY KEY CLUSTERED (MyDate, Id) ON [PartitionedByDateId_PS](MyDate)
	CONSTRAINT [FK_PartitionedByDateId_ExternalReferenceTable] FOREIGN KEY ([ExternalId]) REFERENCES ExternalReferenceTable (Id)
)

CREATE TABLE PartitionedByIdDate (
	[Id] BIGINT IDENTITY(1,1) NOT NULL,
	[MyDate] DATETIME NOT NULL,
	[RandomInt] INT NOT NULL,
	[RandomString] VARCHAR(128) NOT NULL,
	[MyGuid] UNIQUEIDENTIFIER NOT NULL DEFAULT NEWID(),
	[ExternalId] INT NULL

	CONSTRAINT [PK_PartitionedByIdDate] PRIMARY KEY CLUSTERED (Id, MyDate) ON [PartitionedByDateId_PS](MyDate)
	CONSTRAINT [FK_PartitionedByIdDate_ExternalReferenceTable] FOREIGN KEY ([ExternalId]) REFERENCES ExternalReferenceTable (Id)
)

DECLARE @startDate DATE, @endDate DATE, @rowsPerDay INT

SET @startDate = '20190101'
SET @endDate = '20210101'
SET @rowsPerDay = 1000
DECLARE @rows INT

WHILE (@startDate < @endDate)

BEGIN 
	SET @rows = @rowsPerDay
	WHILE (1 <= @rows)
	BEGIN
		INSERT INTO PartitionedByDateId (MyDate, RandomInt, RandomString, ExternalId)
		SELECT @startDate, floor(rand() * 10), 'Random' + CAST(floor(rand() * 10) AS VARCHAR(128)), (@rows%2)+1
		INSERT INTO PartitionedByIdDate (MyDate, RandomInt, RandomString, ExternalId)
		SELECT @startDate, floor(rand() * 10), 'Random' + CAST(floor(rand() * 10) AS VARCHAR(128)), (@rows%2)+1
		
		SET @rows = @rows - 1
	END
	
	SET @startDate = DATEADD(DD, 1, @startDate)

END
GO

CREATE NONCLUSTERED INDEX [IX_GUID] ON [PartitionedByIdDate] (
	[MyGuid]
) ON [PartitionedByDateId_PS](MyDate)
GO
CREATE NONCLUSTERED INDEX [IX_GUID] ON [PartitionedByDateId] (
	[MyGuid]
) ON [PartitionedByDateId_PS](MyDate)

CREATE NONCLUSTERED INDEX [IX_GUID_Unaligned] ON [PartitionedByIdDate] (
	[MyGuid]
) ON [Primary]
GO
CREATE NONCLUSTERED INDEX [IX_GUID_Unaligned] ON [PartitionedByDateId] (
	[MyGuid]
) ON [Primary]

	
--Pega todas as partições, por isso temos 13 scan count.
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'

--Pega apenas 4 partições, por isso temos 4 scan count.
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'
	AND MyDate >= '20200101'
	AND MyDate <= '20201230'

--indice desalinhado, ou seja, tem apenas uma b-tree, por isso apenas um scan count.
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID_Unaligned])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'


--Pega todas as partições, por isso temos 13 scan count.
SELECT MyGuid
FROM dbo.PartitionedByIdDate WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'

--Pega apenas 4 partições, por isso temos 4 scan count.
SELECT MyGuid
FROM dbo.PartitionedByIdDate WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'
	AND MyDate >= '20200101'
	AND MyDate <= '20201230'

--indice desalinhado, ou seja, tem apenas uma b-tree, por isso apenas um scan count.
SELECT MyGuid
FROM dbo.PartitionedByIdDate WITH(INDEX=[IX_GUID_Unaligned])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'

	
SELECT 
	dbschemas.[name] as 'Schema', 
	dbtables.[name] as 'Table', 
	dbindexes.[name] as 'Index',
	partition_number,
	indexstats.avg_fragmentation_in_percent,
	indexstats.page_count,
	record_count
INTO #TMP
FROM sys.dm_db_index_physical_stats (DB_ID(), null, NULL, NULL, 'DETAILED') AS indexstats
INNER JOIN sys.tables dbtables on dbtables.[object_id] = indexstats.[object_id]
INNER JOIN sys.schemas dbschemas on dbtables.[schema_id] = dbschemas.[schema_id]
INNER JOIN sys.indexes AS dbindexes ON dbindexes.[object_id] = indexstats.[object_id]
AND indexstats.index_id = dbindexes.index_id
WHERE 
	indexstats.database_id = DB_ID()
	AND index_level = 0
	-- AND dbindexes.is_primary_key = 0 -- não é PK
	AND dbtables.name IN ('PartitionedByDateId', 'PartitionedByIdDate')
ORDER BY 
	dbtables.name asc
	, dbindexes.[name] asc
	, partition_number asc
	--, indexstats.avg_fragmentation_in_percent desc

SELECT *
FROM #TMP
ORDER BY
	[Table] asc,
	[Index] asc,
	partition_number asc
