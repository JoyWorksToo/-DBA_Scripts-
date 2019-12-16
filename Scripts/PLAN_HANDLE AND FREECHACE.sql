--
----------------------------------------------------------
------------- FIND PLAN_HANDLE WITH TEXT -----------------
----------------------------------------------------------

SELECT 
	plan_handle
	, st.text  
FROM sys.dm_exec_cached_plans   
CROSS APPLY sys.dm_exec_sql_text(plan_handle) AS st  
WHERE text LIKE N'%TEXT%';  
GO 


------------------ NÃO SEI SE FUNCIONA
SELECT 
	plan_handle
	, cp.objtype AS ObjectType
	, OBJECT_NAME(st.objectid,st.dbid) AS ObjectName
	, cp.usecounts AS ExecutionCount
	, st.TEXT AS QueryText
	, qp.query_plan AS QueryPlan

FROM sys.dm_exec_cached_plans AS cp
CROSS APPLY sys.dm_exec_query_plan(cp.plan_handle) AS qp
CROSS APPLY sys.dm_exec_sql_text(cp.plan_handle) AS st

WHERE text LIKE N'%TEXT%';  
GO 

----------------------------------------------------------

select * from sys.dm_exec_requests

select * from sys.dm_exec_sql_text(0x02000000E0D338129A64A54970C73A0A8250063B895621420000000000000000000000000000000000000000)

----------------------------------------------------------
------------ SHOW EXECUTION PLAN OF THE QUERY ------------
----------------------------------------------------------

select *
from sys.dm_exec_query_plan(0x06000600A3E3A120A03C6FC12E00000001000000000000000000000000000000000000000000000000000000) AS qp



----------------------------------------------------------
----------------------- FREE CASHE -----------------------
----------------------------------------------------------

DBCC FREEPROCCACHE (0x06000600A3E3A120A03C6FC12E00000001000000000000000000000000000000000000000000000000000000);  
GO  






SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED 

DECLARE @dbname SYSNAME 
SET @dbname = QUOTENAME(DB_NAME()); 

WITH XMLNAMESPACES 
   (DEFAULT 'http://schemas.microsoft.com/sqlserver/2004/07/showplan') 
SELECT 
   stmt.value('(@StatementText)[1]', 'varchar(max)'), 
   t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)'), 
   t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)'), 
   t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)'), 
   ic.DATA_TYPE AS ConvertFrom, 
   ic.CHARACTER_MAXIMUM_LENGTH AS ConvertFromLength, 
   t.value('(@DataType)[1]', 'varchar(128)') AS ConvertTo, 
   t.value('(@Length)[1]', 'int') AS ConvertToLength, 
   query_plan 
FROM sys.dm_exec_cached_plans AS cp 
CROSS APPLY sys.dm_exec_query_plan(plan_handle) AS qp 
CROSS APPLY query_plan.nodes('/ShowPlanXML/BatchSequence/Batch/Statements/StmtSimple') AS batch(stmt) 
CROSS APPLY stmt.nodes('.//Convert[@Implicit="1"]') AS n(t) 
JOIN INFORMATION_SCHEMA.COLUMNS AS ic 
   ON QUOTENAME(ic.TABLE_SCHEMA) = t.value('(ScalarOperator/Identifier/ColumnReference/@Schema)[1]', 'varchar(128)') 
   AND QUOTENAME(ic.TABLE_NAME) = t.value('(ScalarOperator/Identifier/ColumnReference/@Table)[1]', 'varchar(128)') 
   AND ic.COLUMN_NAME = t.value('(ScalarOperator/Identifier/ColumnReference/@Column)[1]', 'varchar(128)') 
WHERE t.exist('ScalarOperator/Identifier/ColumnReference[@Database=sql:variable("@dbname")][@Schema!="[sys]"]') = 1
