##FailureConditionLevel
If ((Get-ClusterResource  | Get-ClusterParameter | where name -like FailureConditionLevel).Value -ne 1) {
	Write-Verbose "FailureConditionLevel is not 1"
	Write-Verbose "Setting FailureConditionLevel to 1"            
	Get-ClusterResource ((Get-ClusterResource  | Get-ClusterParameter | where name -like FailureConditionLevel).ClusterObject.Name) | Set-ClusterParameter FailureConditionLevel 1
} Else {            
	Write-Verbose "FailureConditionLevel is 1"
}   

##HostRecordTTLforAG
If ((Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group" }).name) | Get-ClusterParameter HostRecordTTL | Select-Object Value).value -eq 5) {
	Write-Verbose "HostRecordTTL from AG is 5"
	Return $true            
} Else {            
	Write-Verbose "HostRecordTTL from AG is not 5"
	Write-Verbose "Setting HostRecordTTL from AG to 5"            
	Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group" }).name) | Set-ClusterParameter HostRecordTTL 5 
}

##PreventAutoFailback
If ((Get-ClusterResource | Where-Object {$_.ResourceType -eq "SQL Server Availability Group"}).OwnerGroup.AutoFailbackType -ne 0)
{
	Write-Verbose "Prevent auto Failback is not 0"
	Write-Verbose "Setting Prevent auto Failback to 0"            
	(Get-ClusterResource | Where-Object {$_.ResourceType -eq "SQL Server Availability Group"}).OwnerGroup.AutoFailbackType = 0
} Else {            
	Write-Verbose "Prevent auto Failback is 0. Nothing to do..."
	Return $true
} 

##RegisterAllProvidersIPAG
If ((Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group" }).name) | Get-ClusterParameter RegisterAllProvidersIP | Select-Object Value).value -eq 1) {            
	Write-Verbose "RegisterAllProvidersIP from AG is 1"
} Else {            
	Write-Verbose "RegisterAllProvidersIP from AG is 0"
	Write-Verbose "Setting RegisterAllProvidersIP from AG to 1"
	Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group" }).name) | Set-ClusterParameter RegisterAllProvidersIP 1
}       


##Checking all Values
Get-ClusterResource  | Get-ClusterParameter | where name -like FailureConditionLevel | select Name, Value; "Value must be 1"

Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group" }).name) | Get-ClusterParameter HostRecordTTL | Select-Object Name, Value; "Value must be 5"

(Get-ClusterResource | Where-Object {$_.ResourceType -eq "SQL Server Availability Group"}).OwnerGroup | Select-Object AutoFailbackType; "Value must be 0"

Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -ne "Cluster Group" }).name) | Get-ClusterParameter RegisterAllProvidersIP | Select Name, Value; "Value must be 1"
