/*
Estimativa de tamanho e crescimento de todos os bancos
Para calcular a taxa de crescimento usamos a formula:
	TxCrescimento = (Presente - Passado) / Passado
Que no nosso caso foi:
	TxCrescimento = (Data - Data-1) / Data-1
para cada dia de 3 meses atrás até o presente momento.

Tendo a taxa de crescimento de cada dia, foi tirado a média dessa taxa, foi usado as função AVG do sql server para isso

Tendo a média da taxa de crescimento, foi usado a formula para calcular o crescimento no futuro:
	Presente = Passado(1+Taxa_de_crescimento) ^ n ; onde n é a quantidade de intervalo de tempo, no nosso caso é dia.

	Então foi usado o ultimo tamanho registrado e aplicado a formula para calcular o futuro.
*/

DROP TABLE IF EXISTS #BdSizes
SELECT
	DBS.DatabaseName
	, MAX(insdb.DataSizeGB) AS FileTotalSpaceGB
	, CAST(insdb.SysStart AS DATE) AS [Date]	
INTO #BdSizes
FROM [dbo].[InstanceDatabase] 
	FOR SYSTEM_TIME FROM '20180101' TO '20191231' --coloquei uma data no futuro pra pegar o atual tmb 
	AS insdb
INNER JOIN SQLInstance AS ins ON 
	ins.SQLInstanceID = insDb.SQLInstanceId
INNER JOIN MyDatabases AS dbs 
	ON dbs.DatabaseId = insDb.DatabaseId
WHERE
	1=1
	--AND dbs.DatabaseName = 'IncidentLogs'
	--AND insdb.IsPrimary = 1
	AND ins.IsMonitored = 1
GROUP BY
	dbs.DatabaseName
	, CAST(insDb.SysStart AS DATE)
order by date desc

--Preciso de uma tabela calendario para preencher os dias que o arquivo nao cresceu ou nao foi pego o valor no dia.
DROP TABLE IF EXISTS #Calendar
CREATE TABLE #Calendar(d DATE PRIMARY KEY);
INSERT #Calendar(d) 
SELECT TOP (900)
	DATEADD(DAY, ROW_NUMBER() OVER (ORDER BY number)-1, '20180101')
FROM [master].dbo.spt_values
WHERE 
	[type] = N'P' 
ORDER BY number;


--Faz o esquema de preencher os "vazios" das datas.
DROP TABLE IF EXISTS #BdSizesByDay
;WITH GetNextDate AS
(
	--select *, LEAD([Date]) OVER (PARTITION BY FileName ORDER BY [Date] ASC) AS NextDate
	SELECT *, ISNULL(LEAD([Date]) OVER (PARTITION BY DatabaseName ORDER BY [Date] ASC), CAST(GETDATE() AS DATE)) AS NextDate
	from #BdSizes
)
SELECT 
	DatabaseName
	, FileTotalSpaceGB
	, c.d AS [Date]
INTO #BdSizesByDay
FROM #Calendar c
INNER JOIN GetNextDate cte
	ON  c.d BETWEEN cte.[Date] 
	AND ISNULL(DATEADD(day,-1,cte.[NextDate]),cte.[Date]);

SELECT *
FROM #BdSizesByDay
order by date desc


--TotalFileSize
SELECT 
		SBD.DatabaseName
		, SBD.FileTotalSpaceGB
		, (SBD.FileTotalSpaceGB - LEAD(SBD.FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC)) AS DIFFDataSizeGB
		, (SBD.FileTotalSpaceGB-( LEAD(SBD.FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(SBD.FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC)) AS GrowthRatePercent
		, ((SBD.FileTotalSpaceGB - LEAD(SBD.FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / SBD.FileTotalSpaceGB AS GrowthTax
		, SBD.[Date]
	FROM #BdSizesByDay as SBD
	CROSS APPLY (
		SELECT TOP 1 FileTotalSpaceGB AS LastDbSize
		FROM #BdSizesByDay AS inside
		WHERE
			inside.DatabaseName = SBD.DatabaseName
		ORDER BY [Date] DESC
		) AS LastDbSize
	WHERE
		SBD.Date > dateadd(month, -3, getdate())


SELECT 
	DatabaseName
	, AVG(DIFFDataSizeGB) AS DatabaseGrowthPerDayGB
	, AVG(GrowthTax) AS GrowthTaxPerDay
	, AVG(GrowthRate) as GrowthRatePerDay
FROM (
	SELECT 
		DatabaseName
		, FileTotalSpaceGB
		, (FileTotalSpaceGB - LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC)) AS DIFFDataSizeGB
		, (FileTotalSpaceGB-( LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC)) * 100 AS GrowthRate
		, ((FileTotalSpaceGB - LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))*100) / FileTotalSpaceGB AS GrowthTax
		, [Date]
	FROM #BdSizesByDay
	WHERE
		Date > dateadd(month, -3, getdate())
) AS x
GROUP BY
	DatabaseName


SELECT
	X.DatabaseName
	, LastDbSize.LastDbSize
	, LastDate AS [Date]
	, GrowthRatePerDay
	, DatabaseGrowthPerDayGB
	, LastDbSize.LastDbSize*POWER((1+X.GrowthRatePerDay),30)  AS EstimatedDbSizeIn30Days
	, LastDbSize.LastDbSize*POWER((1+X.GrowthRatePerDay),60)  AS EstimatedDbSizeIn60Days
	, LastDbSize.LastDbSize*POWER((1+X.GrowthRatePerDay),90)  AS EstimatedDbSizeIn90Days
	, LastDbSize.LastDbSize*POWER((1+X.GrowthRatePerDay),120) AS EstimatedDbSizeIn120Days
FROM(
	SELECT 
		X_in.DatabaseName
		, AVG(X_in.DIFFDataSizeGB) AS DatabaseGrowthPerDayGB
		, AVG(X_in.GrowthTax) AS GrowthTaxPerDay
		, AVG(X_in.GrowthRate) as GrowthRatePerDay
	FROM (
		SELECT 
			DatabaseName
			, FileTotalSpaceGB
			, (FileTotalSpaceGB - LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC)) AS DIFFDataSizeGB
			, (FileTotalSpaceGB-( LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / (LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))  AS GrowthRate
			, ((FileTotalSpaceGB - LEAD(FileTotalSpaceGB, 1, NULL) OVER (PARTITION BY DatabaseName ORDER BY [Date] DESC))) / FileTotalSpaceGB AS GrowthTax
			, [Date]
		FROM #BdSizesByDay
		WHERE
			Date > dateadd(month, -3, getdate())
	) AS X_in
	GROUP BY
		DatabaseName
) AS X
CROSS APPLY (
	SELECT TOP 1 
		FileTotalSpaceGB AS LastDbSize
		, [Date] AS LastDate
	FROM #BdSizesByDay AS inside
	WHERE
		inside.DatabaseName = X.DatabaseName
	ORDER BY 
		[Date] DESC
	) AS LastDbSize	
ORDER BY
	LastDbSize.LastDbSize DESC

