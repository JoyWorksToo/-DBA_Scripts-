--Pegar uma GIUD para o teste
SELECT top 10 MyGuid
FROM dbo.PartitionedByDateId
WHERE
	MyDate >= '20191201'
	
--set statistics io on

--indice desalinhado, ou seja, tem apenas uma b-tree, por isso apenas um scan count.
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID_Unaligned])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'

--Pega todas as partições, por isso temos 13 scan count.
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'

/*
Statistics:
Indice desalinhado:
	Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Indice alinhado:
	Table 'PartitionedByDateId'. Scan count 13, logical reads 24, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

Mas porque ele fez 13 SCAN COUNT e 24 LOGICAL READS?
Temos no total de 13 partições, se não passarmos uma data, que é a chave do particionamento, ele precisa procurar em cada partição o valor procurado, vamos fazer na mão isso:
*/

--Pega apenas 4 partições, por isso temos 4 scan count.
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate < '2019-04-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2019-04-01'
	AND MyDate <  '2019-07-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2019-07-01'
	AND MyDate <  '2019-09-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2019-09-01'
	AND MyDate <  '2020-01-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2020-01-01'
	AND MyDate <  '2020-04-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2020-04-01'
	AND MyDate <  '2020-07-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2020-07-01'
	AND MyDate <  '2020-09-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2020-09-01'
	AND MyDate <  '2021-01-01'

--
SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2021-01-01'
	AND MyDate <  '2021-04-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2021-04-01'
	AND MyDate <  '2021-07-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2021-07-01'
	AND MyDate <  '2021-09-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2021-09-01'
	AND MyDate <  '2022-01-01'

SELECT MyGuid
FROM dbo.PartitionedByDateId WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '94272C5F-DB15-4428-BC26-29E33721305B'
	AND MyDate >= '2022-01-01'

--Pega todas as partições, por isso temos 13 scan count.
SELECT MyGuid
FROM dbo.PartitionedByIdDate WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'

--Pega apenas 4 partições, por isso temos 4 scan count.
SELECT MyGuid
FROM dbo.PartitionedByIdDate WITH(INDEX=[IX_GUID])
WHERE
	MyGuid = '9D16E738-F678-4AAB-835C-6755C05A9D07'
	AND MyDate >= '20200101'
	AND MyDate <= '20201230'

/*
Aqui é o output das estatísticas, em ordem:
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 3, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.
Table 'PartitionedByDateId'. Scan count 1, logical reads 0, physical reads 0, page server reads 0, read-ahead reads 0, page server read-ahead reads 0, lob logical reads 0, lob physical reads 0, lob page server reads 0, lob read-ahead reads 0, lob page server read-ahead reads 0.

Se somarmos o SCAN COUNT o valor é 13, se somarmos o logical read, o valor é 24.
É exatamente o mesmo valor quando é usado o índice alinhado, mas sem passar uma data.
*/

