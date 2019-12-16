SELECT j.name, js.step_id, SUBSTRING(js.command,Firstindex+44,length-55) as coisa
    FROM dbo.sysjobsteps js
	inner join dbo.sysjobs j ON	js.job_id = j.job_id  
	outer apply (select * from master.dbo.RegexFind ('\b @filename(?:\W+\w+){0,800}?\W+CONVERT\b', js.command,1,1)) CA (Match_ID,FirstIndex,[length],Value,Submatch_ID,SubmatchValue,Error)
	where left(j.name,6) = 'report'