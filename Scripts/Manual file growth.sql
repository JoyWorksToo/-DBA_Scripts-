USE DBName
GO

IF (SELECT sys.fn_hadr_is_primary_replica ( 'DBName' ) ) = 1
BEGIN

	DROP TABLE IF EXISTS #LastDataCollected
		SELECT DB_NAME() AS DatabaseName
			, [name] AS FileName
			,  (CAST(size  AS BIGINT) * 8) / (1024.) AS SizeMB
			,  (CAST(fileproperty([name],'SpaceUsed')  AS BIGINT) * 8) / (1024.) AS UsedSpaceMB
			, growth/128. AS GrowthMB
			, is_percent_growth
			, GETDATE() AS GetTime
		INTO #LastDataCollected
		FROM sys.database_files
		WHERE
			type_desc <> 'LOG'


	DROP TABLE IF EXISTS #DiffSizeByDay
		SELECT 
			DatabaseName
			, FileName
			, SizeMB - LEAD(SizeMB, 1, null) OVER(PARTITION BY FileName ORDER BY GetTime DESC) AS DIFF_Size
			, UsedSpaceMB - LEAD(UsedSpaceMB, 1, null) OVER(PARTITION BY FileName ORDER BY GetTime DESC) AS DIFF_FileUsedSpaceMB
			, GetTime
		INTO #DiffSizeByDay
		FROM (
			SELECT 
				DatabaseName
				, fs.FileName
				, (CAST(MAX(FileSizeInPage) AS BIGINT) * 8) / (1024.) AS SizeMB
				, (CAST(MAX(FileSpaceUsedInPage) AS BIGINT) * 8) / (1024.) AS UsedSpaceMB
				, CAST(GetTime AS DATE) AS GetTime
			FROM master.dbo.FileSizeDBs AS fs
			INNER JOIN (
				SELECT FileName, count(*) AS CT
				FROM master.dbo.FileSizeDBs
				WHERE GetTime >= DATEADD(DD, -15, GETDATE())
				GROUP BY DatabaseName, FileName
			) AS OnlyFilesWithMoreThan7Days
			ON fs.FileName = OnlyFilesWithMoreThan7Days.FileName
			WHERE
				GetTime >= DATEADD(DD, -15, GETDATE())
				AND DatabaseName =  DB_NAME()
				AND OnlyFilesWithMoreThan7Days.CT >= 7
			GROUP BY 
				DatabaseName, fs.FileName, CAST(GetTime AS DATE) 
		) AS x



	DROP TABLE IF EXISTS #ZScore 
		SELECT 
			DatabaseName
			, FileName
			, COUNT(*) as CNT
			, AVG(DIFF_Size) AS AVG_DIFF_SIZE
			, STDEV(DIFF_Size) AS STDEV_DIFF_SIZE
			, AVG(DIFF_FileUsedSpaceMB) AS AVG_DIFF_FileUsedSpaceMB
			, STDEV(DIFF_FileUsedSpaceMB) AS STDEV_DIFF_FileUsedSpaceMB
		INTO #ZScore
		FROM #DiffSizeByDay
		WHERE
			DIFF_Size IS NOT NULL
		GROUP BY 
			DatabaseName, FileName
		HAVING SUM(DIFF_Size) > 0



	DROP TABLE IF EXISTS #SizeNormalized
		SELECT
			F.DatabaseName
			, F.FileName
			, F.DIFF_Size
			, F.DIFF_FileUsedSpaceMB
			, CASE WHEN Z.STDEV_DIFF_SIZE = 0 THEN 0 ELSE (ABS((F.DIFF_Size - Z.AVG_DIFF_SIZE ) / Z.STDEV_DIFF_SIZE)) END AS DIFF_NORMALIZED
			, CASE WHEN Z.STDEV_DIFF_FileUsedSpaceMB = 0 THEN 0 ELSE (ABS((F.DIFF_FileUsedSpaceMB - Z.AVG_DIFF_FileUsedSpaceMB ) / Z.STDEV_DIFF_FileUsedSpaceMB)) END AS DIFF_FileUsedSpaceMB_NORMALIZED
			, GetTime 
		INTO #SizeNormalized
		FROM #DiffSizeByDay AS F
		JOIN #ZScore AS Z
			ON Z.FileName = F.FileName
		ORDER BY
			F.DatabaseName ASC, F.FileName ASC, GetTime DESC



	DROP TABLE IF EXISTS #diff_size
		SELECT 
			DatabaseName, FileName, AVG(DIFF_Size) AS AVG_DIFF_Size_MB
		INTO #diff_size
		FROM #SizeNormalized
		WHERE
			DIFF_NORMALIZED < 2
			AND DIFF_Size IS NOT NULL
		GROUP BY 
			DatabaseName, FileName
		HAVING 
			AVG(DIFF_Size) > 0
		ORDER BY 
			DatabaseName ASC, FileName ASC

	DROP TABLE IF EXISTS #diff_UsedSize
		SELECT 
			DatabaseName, FileName, AVG(DIFF_FileUsedSpaceMB) AS AVG_DIFF_FileUsedSpaceMB
		INTO #diff_UsedSize
		FROM #SizeNormalized
		WHERE
			DIFF_FileUsedSpaceMB_NORMALIZED < 2
			AND DIFF_FileUsedSpaceMB IS NOT NULL
		GROUP BY 
			DatabaseName, FileName
		HAVING 
			AVG(DIFF_FileUsedSpaceMB) > 0
		ORDER BY 
			DatabaseName, FileName ASC

	DROP TABLE IF EXISTS #FilesToGrowth
		SELECT 'ALTER DATABASE [' + DatabaseName + '] MODIFY FILE ( NAME = N''' + [FileName] + ''', SIZE = ' + CAST((SizeToGrowthMB + SizeMB) AS VARCHAR(128)) + 'MB );' AS CMD
		INTO #FilesToGrowth
		FROM (
			SELECT
				Actual.DatabaseName
				, Actual.FileName
				, Actual.GetTime
				, Actual.SizeMB
				, Actual.UsedSpaceMB
				, Actual.SizeMB - Actual.UsedSpaceMB AS FreeSpaceMB
				, Used.AVG_DIFF_FileUsedSpaceMB
				, Actual.GrowthMB
				, CASE WHEN 2*(Actual.SizeMB - Actual.UsedSpaceMB) < Used.AVG_DIFF_FileUsedSpaceMB THEN 1 ELSE 0 END AS ToGrowth
				, CASE WHEN Actual.is_percent_growth <> 1 THEN CEILING(Used.AVG_DIFF_FileUsedSpaceMB / Actual.GrowthMB) * Actual.GrowthMB
					ELSE CEILING(Used.AVG_DIFF_FileUsedSpaceMB / 64) * 64
				END AS SizeToGrowthMB
			FROM #LastDataCollected AS Actual
			INNER JOIN #diff_UsedSize AS Used
				ON Actual.FileName = Used.FileName
			WHERE
				2*(Actual.SizeMB - Actual.UsedSpaceMB) < Used.AVG_DIFF_FileUsedSpaceMB
		) AS x

	DECLARE @execCommand varchar(8000)

	DECLARE GrowthFilesCursor CURSOR FOR
		
		SELECT CMD
		FROM #FilesToGrowth

	OPEN GrowthFilesCursor
	FETCH NEXT FROM GrowthFilesCursor INTO  @execCommand
	WHILE @@FETCH_STATUS = 0 BEGIN
		
		EXECUTE (@execCommand )
		--PRINT @execCommand 
	FETCH NEXT FROM GrowthFilesCursor INTO  @execCommand
	END

	CLOSE GrowthFilesCursor
	DEALLOCATE GrowthFilesCursor

END

