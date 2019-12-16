
select s.name,l.name, s.job_id,
'EXEC msdb.dbo.sp_update_job @job_id=N''' + CAST(s.job_id AS VARCHAR(50)) + ''', 
  @owner_login_name=N''BUY4SC\SQLInstanceUser''
  GO' as abc
 from  msdb..sysjobs s 
 left join master.sys.syslogins l on s.owner_sid = l.sid
 WHERE l.name not like 'BUY4SC\SQLInstanceUser'