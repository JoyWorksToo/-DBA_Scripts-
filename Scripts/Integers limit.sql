use <Table>
go

--Pegar tabelas com mais de N Rows
DROP TABLE IF EXISTS #tbs
SELECT 
	SCHEMA_NAME(schema_id) AS [SchemaName],
	[Tables].name AS [TableName],
	SUM([Partitions].[rows]) AS [TotalRowCount]
INTO #tbs
FROM sys.tables AS [Tables]
JOIN sys.partitions AS [Partitions]
	ON [Tables].[object_id] = [Partitions].[object_id]
	AND [Partitions].index_id IN ( 0, 1 )
--WHERE [Tables].name = N'name of the table'
GROUP BY 
	SCHEMA_NAME(schema_id)
	, [Tables].name
HAVING
	SUM([Partitions].[rows]) > 5000000 --N rows
ORDER BY
	[TotalRowCount] DESC;


select * from #tbs order by 3 desc

SELECT
	SCHEMA_NAME(t.schema_id) AS SchemaName 
	, t.name
	, ic.name
	, ic.last_value
	, typ.name
	, c.precision
	, c.scale
	, CASE WHEN typ.name = 'INT' THEN
		2147483647 - CAST(ic.last_value AS INT)
	  WHEN typ.name = 'BIGINT' THEN
		9223372036854775807 - CAST(ic.last_value AS BIGINT)
	  WHEN typ.name IN ('numeric', 'decimal') THEN
		CAST(REPLICATE('9', c.precision - c.scale) AS DECIMAL(25,0)) - CAST(ic.last_value AS DECIMAL(25,0))
	  ELSE 0 END
	  AS NumbersLeft
	, CASE WHEN typ.name = 'INT' THEN
		CAST(ic.last_value AS BIGINT)*100 / 2147483647 
	  WHEN typ.name = 'BIGINT' THEN
		CAST(ic.last_value AS DECIMAL(18,0))*100 / 9223372036854775807 
	  WHEN typ.name IN ('numeric', 'decimal') THEN
		CAST(ic.last_value AS DECIMAL(30,0))*100 / CAST(REPLICATE('9', c.precision - c.scale) AS DECIMAL(25,0))
	  ELSE 0 END
	  AS PercentLeft
	--, 'SELECT MAX(' + ic.name + ') FROM ' + SCHEMA_NAME(t.schema_id) + '.' + t.name
FROM sys.identity_columns AS ic
INNER JOIN sys.columns AS c
	ON ic.object_id = c.object_id
	AND ic.column_id = c.column_id
INNER JOIN sys.tables t
	on ic.object_id = t.object_id
INNER JOIN sys.types AS typ
	ON ic.system_type_id = typ.system_type_id 
LEFT JOIN #tbs AS tbs
	ON tbs.SchemaName = SCHEMA_NAME(t.schema_id)
	AND tbs.TableName = t.name
WHERE
	last_value is not null
ORDER BY PercentLeft DESC
