use buy4_bo
SELECT SUM ([FREESPACE_MB]) --230932.92 -- 228747.29
FROM (
SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0))
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = 'By ' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + ' MB -' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '% -' ELSE '' END 
        + CASE max_size WHEN 0 THEN 'DISABLED' WHEN -1 THEN ' Unrestricted' 
            ELSE ' Restricted to ' + CAST(max_size/(128*1024) AS VARCHAR(10)) + ' GB' END 
        + CASE is_percent_growth WHEN 1 THEN ' [autogrowth by percent, BAD setting!]' ELSE '' END
FROM sys.database_files A 
LEFT JOIN sys.filegroups fg 
	ON A.data_space_id = fg.data_space_id 
WHERE 
	A.TYPE_DESC <> 'LOG'
	AND A.name like '%history%'
	AND A.name like '%atx%'
	and fg.name = 'dbo_ATX_CONFIRMED_TRANSACTION_History_Fg02'
	--AND A.name not like '%DATA%'
	--AND A.name not like '%NEXT%'
	--AND A.name like '%prev%'
	--AND A.name not like '%Index%'
	--AND A.name like '%OUTGOING%'
	and CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100) > 10
	--AND A.name like '%FG09%'
) AS X

SELECT 'DBCC SHRINKFILE (''' + [FILE_Name] + ''', ' + CAST(cast(([USEDSPACE_MB] *1.1) AS INT)as varchar(100) ) + ', TRUNCATEONLY) GO', *
FROM (

SELECT 
    [TYPE] = A.TYPE_DESC
    ,[FILE_Name] = A.name
    ,[FILEGROUP_NAME] = fg.name
    ,[File_Location] = A.PHYSICAL_NAME
    ,[FILESIZE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0)
    ,[USEDSPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - ((SIZE/128.0) - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0))
    ,[FREESPACE_MB] = CONVERT(DECIMAL(10,2),A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)
    ,[FREESPACE_%] = CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100)
    ,[AutoGrow] = 'By ' + CASE is_percent_growth WHEN 0 THEN CAST(growth/128 AS VARCHAR(10)) + ' MB -' 
        WHEN 1 THEN CAST(growth AS VARCHAR(10)) + '% -' ELSE '' END 
        + CASE max_size WHEN 0 THEN 'DISABLED' WHEN -1 THEN ' Unrestricted' 
            ELSE ' Restricted to ' + CAST(max_size/(128*1024) AS VARCHAR(10)) + ' GB' END 
        + CASE is_percent_growth WHEN 1 THEN ' [autogrowth by percent, BAD setting!]' ELSE '' END
FROM sys.database_files A 
LEFT JOIN sys.filegroups fg 
	ON A.data_space_id = fg.data_space_id 
WHERE 
	A.TYPE_DESC <> 'LOG'
	--AND A.name not like '%DATA%'
	--AND A.name not like '%NEXT%'
	--AND A.name like '%SETTLEMENT%'
	AND A.name like '%history%'
	AND A.name like '%ATX%'
	and fg.name = 'dbo_ATX_CONFIRMED_TRANSACTION_History_Fg02'
	--AND A.name like '%atx_tx%'
	--AND A.name like '%OUTGOING%'
	--AND A.name not like '%next%'
	--AND A.name like '%prev%'
	--AND A.name not like '%Index%'
	--AND A.name like '%BUY4_RECEIVABLES_ADVANCE%'
	and CONVERT(DECIMAL(10,2),((A.SIZE/128.0 - CAST(FILEPROPERTY(A.NAME, 'SPACEUSED') AS INT)/128.0)/(A.SIZE/128.0))*100) > 10
	--and a.name = 'dbo_AMR_MOVEMENT_History_Fg09_F04'
	--AND A.name like '%FG09%'
	) AS X 
order by 
	[FREESPACE_MB] DESC
