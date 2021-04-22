
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
