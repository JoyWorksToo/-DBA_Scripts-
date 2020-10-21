
SELECT 
	  sysfilegroups.groupname AS 'FileGroup'
	, sysfiles.name AS 'File Name'

	, convert(decimal(12,2),round(sysfiles.size/128.,2)) as file_size_MB
	, convert(decimal(12,2),round(fileproperty(sysfiles.name,'SpaceUsed')/128.,2)) as space_used_MB
	, convert(decimal(12,2),round((sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed'))/128.,2)) as free_space_MB

	, convert(decimal(12,2),round(sysfiles.size/(128.*1024),2)) as file_size_GB
	, convert(decimal(12,2),round(fileproperty(sysfiles.name,'SpaceUsed')/(128.*1024.),2)) as space_used_GB
	, convert(decimal(12,2),round((sysfiles.size-fileproperty(sysfiles.name,'SpaceUsed'))/(128.*1024.),2)) as free_space_GB

	, CONVERT(DECIMAL(10,2),((sysfiles.SIZE/128.0 - CAST(FILEPROPERTY(sysfiles.NAME, 'SPACEUSED') AS INT)/128.0)/(sysfiles.SIZE/128.0))*100) AS [FreeSpace_%] 
	, sysfiles.filename AS 'File Path' 
	, SUBSTRING(sysfiles.filename,0,25) as dd
FROM sys.sysfilegroups 
LEFT OUTER JOIN sys.sysfiles 
	ON sysfiles.groupid = sysfilegroups.groupid 
--WHERE sysfilegroups.groupname like 'MovementV2_%'
ORDER BY free_space_GB desc
