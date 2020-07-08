USE msdb
GO

;WITH XMLNAMESPACES ('www.microsoft.com/SqlServer/Dts' AS DTS
, 'www.microsoft.com/sqlserver/dts/tasks/sqltask'AS SQLTask)
, ssis AS (
    SELECT name
        , CAST(CAST(packagedata AS varbinary(MAX)) AS XML) AS package, id
    FROM [msdb].[dbo].[sysssispackages]
    WHERE name like '%Backup%'
   )
, jobs AS (
	SELECT
		[sJOB].[name] AS [JobName] ,
		CASE [sJOB].[enabled]
		  WHEN 1 THEN 'Yes'
		  WHEN 0 THEN 'No'
		END AS [IsEnabled] ,
		--[sJOB].[date_created] AS [JobCreatedOn] ,
		--[sJOB].[date_modified] AS [JobLastModifiedOn] ,
		--[sDBP].[name] AS [JobOwner] ,
		[sCAT].[name] AS [JobCategory] ,
		--[sJOB].[description] AS [JobDescription] ,
		CASE
			WHEN [sSCH].[schedule_uid] IS NULL THEN 'No'
			ELSE 'Yes'
		  END AS [IsScheduled],
		[sSCH].[name] AS [JobScheduleName],
		CASE 
			WHEN [sSCH].[freq_type] = 64 THEN 'Start automatically when SQL Server Agent starts'
			WHEN [sSCH].[freq_type] = 128 THEN 'Start whenever the CPUs become idle'
			WHEN [sSCH].[freq_type] IN (4,8,16,32) THEN 'Recurring'
			WHEN [sSCH].[freq_type] = 1 THEN 'One Time'
		END [ScheduleType], 
		CASE [sSCH].[freq_type]
			WHEN 1 THEN 'One Time'
			WHEN 4 THEN 'Daily'
			WHEN 8 THEN 'Weekly'
			WHEN 16 THEN 'Monthly'
			WHEN 32 THEN 'Monthly - Relative to Frequency Interval'
			WHEN 64 THEN 'Start automatically when SQL Server Agent starts'
			WHEN 128 THEN 'Start whenever the CPUs become idle'
	  END [Occurrence], 
	  CASE [sSCH].[freq_type]
			WHEN 4 THEN 'Occurs every ' + CAST([freq_interval] AS VARCHAR(3)) + ' day(s)'
			WHEN 8 THEN 'Occurs every ' + CAST([freq_recurrence_factor] AS VARCHAR(3)) + ' week(s) on '
					+ CASE WHEN [sSCH].[freq_interval] & 1 = 1 THEN 'Sunday' ELSE '' END
					+ CASE WHEN [sSCH].[freq_interval] & 2 = 2 THEN ', Monday' ELSE '' END
					+ CASE WHEN [sSCH].[freq_interval] & 4 = 4 THEN ', Tuesday' ELSE '' END
					+ CASE WHEN [sSCH].[freq_interval] & 8 = 8 THEN ', Wednesday' ELSE '' END
					+ CASE WHEN [sSCH].[freq_interval] & 16 = 16 THEN ', Thursday' ELSE '' END
					+ CASE WHEN [sSCH].[freq_interval] & 32 = 32 THEN ', Friday' ELSE '' END
					+ CASE WHEN [sSCH].[freq_interval] & 64 = 64 THEN ', Saturday' ELSE '' END
			WHEN 16 THEN 'Occurs on Day ' + CAST([freq_interval] AS VARCHAR(3)) + ' of every ' + CAST([sSCH].[freq_recurrence_factor] AS VARCHAR(3)) + ' month(s)'
			WHEN 32 THEN 'Occurs on '
					 + CASE [sSCH].[freq_relative_interval]
						WHEN 1 THEN 'First'
						WHEN 2 THEN 'Second'
						WHEN 4 THEN 'Third'
						WHEN 8 THEN 'Fourth'
						WHEN 16 THEN 'Last'
					   END
					 + ' ' 
					 + CASE [sSCH].[freq_interval]
						WHEN 1 THEN 'Sunday'
						WHEN 2 THEN 'Monday'
						WHEN 3 THEN 'Tuesday'
						WHEN 4 THEN 'Wednesday'
						WHEN 5 THEN 'Thursday'
						WHEN 6 THEN 'Friday'
						WHEN 7 THEN 'Saturday'
						WHEN 8 THEN 'Day'
						WHEN 9 THEN 'Weekday'
						WHEN 10 THEN 'Weekend day'
					   END
					 + ' of every ' + CAST([sSCH].[freq_recurrence_factor] AS VARCHAR(3)) + ' month(s)'
		END AS [Recurrence], 
		CASE [sSCH].[freq_subday_type]
			WHEN 1 THEN 'Occurs once at ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
			WHEN 2 THEN 'Occurs every ' + CAST([sSCH].[freq_subday_interval] AS VARCHAR(3)) + ' Second(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')+ ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_end_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
			WHEN 4 THEN 'Occurs every ' + CAST([sSCH].[freq_subday_interval] AS VARCHAR(3)) + ' Minute(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')+ ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_end_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
			WHEN 8 THEN 'Occurs every ' + CAST([sSCH].[freq_subday_interval] AS VARCHAR(3)) + ' Hour(s) between ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_start_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')+ ' & ' + STUFF(STUFF(RIGHT('000000' + CAST([sSCH].[active_end_time] AS VARCHAR(6)), 6), 3, 0, ':'), 6, 0, ':')
		END [Frequency]
		--STUFF(STUFF(CAST([sSCH].[active_start_date] AS VARCHAR(8)), 5, 0, '-'), 8, 0, '-') AS [ScheduleUsageStartDate], 
		--STUFF(STUFF(CAST([sSCH].[active_end_date] AS VARCHAR(8)), 5, 0, '-'), 8, 0, '-') AS [ScheduleUsageEndDate], 
		--[sSCH].[date_created] AS [ScheduleCreatedOn], 
		--[sSCH].[date_modified] AS [ScheduleLastModifiedOn],
		--CASE [sJOB].[delete_level]
		--    WHEN 0 THEN 'Never'
		--    WHEN 1 THEN 'On Success'
		--    WHEN 2 THEN 'On Failure'
		--    WHEN 3 THEN 'On Completion'
		--END AS [JobDeletionCriterion]
		, s.id
	FROM
		msdb.dbo.sysmaintplan_plans AS s
		LEFT JOIN msdb.dbo.sysmaintplan_subplans AS sp ON sp.plan_id = s.id
		LEFT JOIN msdb.dbo.sysjobs AS [sJOB] ON [sJOB].job_id = sp.job_id
		LEFT JOIN [msdb].[dbo].[syscategories] AS [sCAT] ON [sJOB].[category_id] = [sCAT].[category_id]
		LEFT JOIN [msdb].[sys].[database_principals] AS [sDBP] ON [sJOB].[owner_sid] = [sDBP].[sid]
		LEFT JOIN [msdb].[dbo].[sysjobschedules] AS [sJOBSCH] ON [sJOB].[job_id] = [sJOBSCH].[job_id]
		LEFT JOIN [msdb].[dbo].[sysschedules] AS [sSCH] ON [sJOBSCH].[schedule_id] = [sSCH].[schedule_id]
	--ORDER BY
	--    [JobName]
)
SELECT 
	s.name AS MaintenancePlanName
	, c.value('@SQLTask:DatabaseName', 'NVARCHAR(128)') AS DatabaseName
	, c.value('../@SQLTask:BackupDestinationAutoFolderPath', 'NVARCHAR(500)') AS Dest
	, j.JobName
	, j.IsEnabled
	, j.JobCategory
	, j.IsScheduled
	, j.JobScheduleName
	, j.ScheduleType
	, j.Occurrence
	, j.Recurrence
	, j.Frequency
FROM ssis s
JOIN jobs j 
	ON s.id = j.id
CROSS APPLY package.nodes('//DTS:ObjectData/SQLTask:SqlTaskData/SQLTask:SelectedDatabases') t(c)