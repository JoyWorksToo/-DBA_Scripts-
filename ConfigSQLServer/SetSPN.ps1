
######Variaveis para setar##########

[String[][]]$Server = @("PREFIX-v-sql1-1p01","PREFIX-v-sql1-2p01")
[String]$Ag = "PREFIX-ag-sql1-p"
[String]$fqdn = "ad.stone.com.br"
[String]$Instance = "SQL2019"
[String]$TcpHostPort = "31433"
[String]$TcpAgPort = "31435"
[String]$ServiceAccName = "ADSTONE\PREFIX-svc-sqlengine"

##########################################

$ListSPN = @()
foreach ($i in $Server){
	$ListSPN += "SETSPN -A MSSQLSvc/$($i).$($fqdn):$($Instance) $($ServiceAccName)"
	$ListSPN += "SETSPN -A MSSQLSvc/$($i).$($fqdn):$($TcpHostPort) $($ServiceAccName)"
	$ListSPN += "SETSPN -A MSSQLSvc/$($i).$($fqdn) $($ServiceAccName)"
	$ListSPN += "SETSPN -A MSSQLSvc/$($i):$($Instance) $($ServiceAccName)"
	$ListSPN += "SETSPN -A MSSQLSvc/$($i):$($TcpHostPort) $($ServiceAccName)"
	$ListSPN += "SETSPN -A MSSQLSvc/$($i) $($ServiceAccName)"
}
$ListSPN += "SETSPN -A MSSQLSvc/$($Ag) $($ServiceAccName)"
$ListSPN += "SETSPN -A MSSQLSvc/$($Ag).$($fqdn) $($ServiceAccName)"
$ListSPN += "SETSPN -A MSSQLSvc/$($Ag).$($fqdn):$($TcpAgPort) $($ServiceAccName)"

$listSPN


##Server + fqdn
SETSPN -A MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br:SQL2019 ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br:31433 ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br ADSTONE\PREFIX-svc-sqlengine
##Server
SETSPN -A MSSQLSvc/PREFIX-v-sql1-1p01:SQL2019 ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-v-sql1-1p01:31433 ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-v-sql1-1p01 ADSTONE\PREFIX-svc-sqlengine
##AG
SETSPN -A MSSQLSvc/PREFIX-ag-sql1-p ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-ag-sql1-p.ad.stone.com.br ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-ag-sql1-p.ad.stone.com.br:31435 ADSTONE\PREFIX-svc-sqlengine
SETSPN -A MSSQLSvc/PREFIX-ag-sql1-p.ad.stone.com.br:SQL2019 ADSTONE\PREFIX-svc-sqlengine


##Server + fqdn
MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br:SQL2019 
MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br:31433 
MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br 
##Server
MSSQLSvc/PREFIX-v-sql1-1p01:SQL2019 
MSSQLSvc/PREFIX-v-sql1-1p01:31433 
MSSQLSvc/PREFIX-v-sql1-1p01 
##AG
MSSQLSvc/PREFIX-ag-sql1-p 
MSSQLSvc/PREFIX-ag-sql1-p.ad.stone.com.br 
MSSQLSvc/PREFIX-ag-sql1-p.ad.stone.com.br:31435  


Todos eles com:
	-ServerName + instanceName
	-ServerName + Port
	-ServerName
	
	-ServerName + fqdn + instanceName
	-ServerName + fqdn + Port
	-ServerName + fqdn
	
	-AGName + fqdn + instanceName
	-AGName + fqdn + Port
	-AGName + fqdn
	
	
###########################################
	
MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br:SQL2019
MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br:31433
MSSQLSvc/PREFIX-v-sql1-1p01.ad.stone.com.br
MSSQLSvc/PREFIX-v-sql1-1p01:SQL2019 <<< Esse teria?
MSSQLSvc/PREFIX-v-sql1-1p01:31433
MSSQLSvc/PREFIX-v-sql1-1p01



setspn -l buy4sc\SQLB4DB02Agent
setspn -l ADSTONE\fin-svc-sqlengine

        MSSQLSvc/fin-v-sql1-2p01.ad.stone.com.br:SQL2019
        MSSQLSvc/fin-v-sql1-2p01.ad.stone.com.br
        MSSQLSvc/fin-v-sql1-2p01.ad.stone.com.br:31433
        MSSQLSvc/fin-v-sql1-2p01:31433
        MSSQLSvc/fin-v-sql1-2p01
        MSSQLSvc/fin-v-sql1-1p01.ad.stone.com.br:SQL2019
        MSSQLSvc/fin-v-sql1-1p01.ad.stone.com.br
        MSSQLSvc/fin-v-sql1-1p01.ad.stone.com.br:31433
        MSSQLSvc/fin-v-sql1-1p01:31433
        MSSQLSvc/fin-v-sql1-1p01
        MSSQLSvc/fin-ag-sql1-p:31435
        MSSQLSvc/fin-ag-sql1-p.ad.stone.com.br:31435
        MSSQLSvc/fin-ag-sql1-p.ad.stone.com.br
		
		
		
MSSQLSvc/bo-v-sql1-2p03.buy4sc.local:31433
MSSQLSvc/bo-v-sql1-2p03.buy4sc.local:SQL2016
MSSQLSvc/bo-v-sql1-2p03.buy4sc.local
MSSQLSvc/bo-v-sql1-2p03:31433
MSSQLSvc/bo-v-sql1-2p03
MSSQLSvc/bo-v-sql1-1p03.buy4sc.local
MSSQLSvc/bo-v-sql1-1p03:31433
MSSQLSvc/bo-v-sql1-1p03


SETSPN -A MSSQLSvc/<AGName><FQDN> <Domain\SQLEngineUser>
SETSPN -A MSSQLSvc/<AGName><FQDN>:<AGPort> <Domain\SQLEngineUser>
SETSPN -A MSSQLSvc/<AGName>:<AGPort> <Domain\SQLEngineUser>

SETSPN -A MSSQLSvc/<VMName> <Domain\SQLEngineUser>
SETSPN -A MSSQLSvc/<VMName>:<InstancePort> <Domain\SQLEngineUser>
SETSPN -A MSSQLSvc/<VMName><FQDN>:<InstancePort> <Domain\SQLEngineUser>
SETSPN -A MSSQLSvc/<VMName><FQDN> <Domain\SQLEngineUser>
SETSPN -A MSSQLSvc/<VMName><FQDN>:<Instance> <Domain\SQLEngineUser>

SETSPN -d MSSQLSvc/<AGName><FQDN> <Domain\SQLEngineUser> ##Deleta o SPN
SETSPN -l <Domain\SQLEngineUser> ##Lista os SPN da conta
Exemplo:


SETSPN -A MSSQLSvc/test-ag-sql1-p.myad.com.br DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-ag-sql1-p.myad.com.br:1435 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-ag-sql1-p:1435 DOMAIN\test-svc-sqlengine

SETSPN -A MSSQLSvc/test-v-sql1-1p01 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-1p01:1433 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-1p01.myad.com.br:1433 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-1p01.myad.com.br DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-1p01.myad.com.br:SQL2019 DOMAIN\test-svc-sqlengine

SETSPN -A MSSQLSvc/test-v-sql1-2p01 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-2p01:1433 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-2p01.myad.com.br:1433 DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-2p01.myad.com.br DOMAIN\test-svc-sqlengine
SETSPN -A MSSQLSvc/test-v-sql1-2p01.myad.com.br:SQL2019 DOMAIN\test-svc-sqlengine
