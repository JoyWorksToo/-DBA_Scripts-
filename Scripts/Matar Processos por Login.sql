
--------------------------------------------------
--------------------------------------------------
-----         No exemplo abaixo          ---------
----- , o script mata todos os processos ---------
-----    do Login PortalClientAppUser    ---------
--------------------------------------------------
--------------------------------------------------

DECLARE @SPID INT
DECLARE @SQLTEXT VARCHAR(200)
declare killconc cursor 
for 
select CAST (spid AS INTEGER) from sys.sysprocesses
where loginame = 'PortalClientAppUser'
OPEN killconc
FETCH NEXT FROM KILLCONC INTO @SPID
	WHILE @@FETCH_STATUS = 0
	BEGIN
		SET @SQLTEXT = 'KILL ' + CAST(@SPID AS VARCHAR(5))
		IF EXISTS(SELECT * FROM sys.sysprocesses WHERE SPID = @SPID)
		EXEC (@SQLTEXT)
		FETCH NEXT FROM KILLCONC INTO @SPID
	END
CLOSE KILLCONC;
DEALLOCATE KILLCONC;

DBCC FREEPROCCACHE