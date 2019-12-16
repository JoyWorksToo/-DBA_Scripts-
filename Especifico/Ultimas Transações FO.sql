
DECLARE @StartDate DATETIME = DATEADD(MINUTE, -10, GETDATE())
, @EndDate DATETIME = GETDATE()

DECLARE @Top INT = DATEDIFF(SECOND, @StartDate, @endDate)

IF OBJECT_ID('tempdb..#Transactions') IS NOT NULL DROP TABLE #Transactions

SELECT
	DATEADD(millisecond, -DATEPART(millisecond, TRANSACTION_DATE), TRANSACTION_DATE) as TRANSACTION_DATE
	--, id_response_code AS [id_response_code]
	, COUNT(*) AS [counting]
INTO #Transactions
FROM buy4_aas..au_open_transaction (nolock) 
WHERE
 1=1
	AND TRANSACTION_DATE >= @StartDate
	AND TRANSACTION_DATE <= @EndDate
	AND id_response_code = '00'
	AND MTI_CODE in ('100', '200') 
	AND SUBSTRING(PROCESSING_CODE, 1, 2) = '00'
GROUP BY DATEADD(millisecond, -DATEPART(millisecond, TRANSACTION_DATE), TRANSACTION_DATE), id_response_code
ORDER BY 1 DESC
OPTION(RECOMPILE)

IF OBJECT_ID('tempdb..#Calendar') IS NOT NULL DROP TABLE #Calendar

CREATE TABLE #Calendar(d DATETIME PRIMARY KEY);

INSERT #Calendar(d) 
SELECT TOP (@Top+1)
	DATEADD(SECOND, ROW_NUMBER() OVER (ORDER BY number)-1, DATEADD(millisecond, -DATEPART(millisecond, @StartDate), @StartDate))
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;

SELECT 
	c.d AS TRANSACTION_DATE
	, COUNTING AS NumTransactions
FROM #Calendar c
LEFT JOIN #Transactions cte
	ON  c.d = cte.TRANSACTION_DATE 
ORDER BY 
	c.d DESC

--RETORNA TODOS OS SEGUNDOS QUE NÃO TIVERAM TRANSAÇÕES CASO EXISTA.
SELECT 
	c.d AS TRANSACTION_DATE
	, COUNTING AS NumTransactions
FROM #Calendar c
LEFT JOIN #Transactions cte
	ON  c.d = cte.TRANSACTION_DATE 
WHERE
	counting IS NULL
ORDER BY 
	c.d DESC
