--VERIFICAR TAMANHO DE ARQUIVO E LOG

-----------------------
----- TempDB Size -----
-----------------------

USE tempdb
SELECT
        [FileSizeMB] =
                convert(numeric(10,2),round(a.size/128.,2)),
        [UsedSpaceMB] =
                convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)) ,
        [UnusedSpaceMB] =
                convert(numeric(10,2),round((a.size-fileproperty( a.name,'SpaceUsed'))/128.,2)) ,
		[Percent Used] = 
				convert(numeric(10,2),round(fileproperty( a.name,'SpaceUsed')/128.,2)) * 100 / convert(numeric(10,2),round(a.size/128.,2)),
        [DBFileName] = a.name
from
 	sys.sysfiles a


----------------------------------------
----- Queries consumindo a TempDB ------
----------------------------------------

USE tempdb
SELECT
	t1.session_id,
	t1.request_id,
	t3.hostname,
	t3.loginame,
	t3.program_name,
	db_name (t3.dbid) AS dbname,
	t1.task_alloc  * (8.0/1024.0) AS Alocado_MB, --qtd de paginas
	t1.task_dealloc  * (8.0/1024.0) AS Desalocado_MB, --qtd de paginas
	(SELECT 
		SUBSTRING(text, t2.statement_start_offset/2 + 1,
		  (CASE WHEN statement_end_offset = -1
			  THEN LEN(CONVERT(nvarchar(max),text)) * 2
				   ELSE statement_end_offset
			  END - t2.statement_start_offset)/2)
	 FROM sys.dm_exec_sql_text(t2.sql_handle)
	 ) AS query_text,
	(SELECT 
		query_plan 
	 FROM sys.dm_exec_query_plan(t2.plan_handle)
	) as query_plan
FROM
	(
		SELECT session_id, request_id,
		SUM(internal_objects_alloc_page_count +   user_objects_alloc_page_count) AS task_alloc,
		SUM(internal_objects_dealloc_page_count + user_objects_dealloc_page_count) AS task_dealloc
			   FROM sys.dm_db_task_space_usage
			   GROUP BY session_id, request_id
	) AS t1,
	sys.dm_exec_requests AS t2,
	sys.sysprocesses AS t3
WHERE
	t3.loginame <> ''
	AND t1.session_id = t2.session_id
	AND (t1.request_id = t2.request_id) 
	AND t1.session_id = t3.spid
	AND t1.session_id > 50	
ORDER BY 
	t1.task_alloc DESC
	
-------------
-- OU ESSA --
-------------

USE tempdb
;WITH task_space_usage AS (
    -- SUM alloc/delloc pages
    SELECT session_id,
           request_id,
           SUM(internal_objects_alloc_page_count) AS alloc_pages,
           SUM(internal_objects_dealloc_page_count) AS dealloc_pages
    FROM sys.dm_db_task_space_usage WITH (NOLOCK)
    WHERE session_id <> @@SPID
    GROUP BY session_id, request_id
)
SELECT TSU.session_id,
       TSU.alloc_pages * 1.0 / 128 AS [internal object MB space],
	   TSU.alloc_pages * 1.0 / (128*1024.0) AS [internal object GB space],
       TSU.dealloc_pages * 1.0 / 128 AS [internal object dealloc MB space],
       EST.text,
       -- Extract statement from sql text
       ISNULL(
           NULLIF(
               SUBSTRING(
                   EST.text, 
                   ERQ.statement_start_offset / 2, 
                   CASE WHEN ERQ.statement_end_offset < ERQ.statement_start_offset THEN 0 ELSE( ERQ.statement_end_offset - ERQ.statement_start_offset ) / 2 END
               ), ''
           ), EST.text
       ) AS [statement text],
       EQP.query_plan
FROM task_space_usage AS TSU
INNER JOIN sys.dm_exec_requests ERQ WITH (NOLOCK)
    ON  TSU.session_id = ERQ.session_id
    AND TSU.request_id = ERQ.request_id
OUTER APPLY sys.dm_exec_sql_text(ERQ.sql_handle) AS EST
OUTER APPLY sys.dm_exec_query_plan(ERQ.plan_handle) AS EQP
WHERE EST.text IS NOT NULL OR EQP.query_plan IS NOT NULL
ORDER BY 3 DESC, 5 DESC



--- TAMANHO DE CADA TABLE DA TEMPDB


SELECT TBL.name AS ObjName 
      ,STAT.row_count AS StatRowCount 
      ,STAT.used_page_count * 8 AS UsedSizeKB 
      ,STAT.reserved_page_count * 8 AS RevervedSizeKB 
FROM tempdb.sys.partitions AS PART 
     INNER JOIN tempdb.sys.dm_db_partition_stats AS STAT 
         ON PART.partition_id = STAT.partition_id 
            AND PART.partition_number = STAT.partition_number 
     INNER JOIN tempdb.sys.tables AS TBL 
         ON STAT.object_id = TBL.object_id 
ORDER BY TBL.name;