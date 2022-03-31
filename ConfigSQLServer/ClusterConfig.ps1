
##HostRecordTTLClusterTo300
If ((Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" }).name) | Get-ClusterParameter HostRecordTTL | Select-Object Value).value -eq 300) {            
	Write-Verbose "HostRecordTTL from Cluster is 300"
} Else {            
	Write-Verbose "HostRecordTTL from Cluster is not 300. Changing..."
	Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" }).name) | Set-ClusterParameter HostRecordTTL 300
} 

##CrossSubnetDelayTo3000
If ((Get-Cluster).CrossSubnetDelay -ne 3000) {            
	Write-Verbose "CrossSubnetDelay is not 3000. Changing..."
	(get-cluster).CrossSubnetDelay = 3000
} Else {            
	Write-Verbose "CrossSubnetDelay is 3000."	
}

##CrossSubnetThresholdTo5			
If ((Get-Cluster).CrossSubnetThreshold -ne 5) {            
	Write-Verbose "CrossSubnetThreshold is not 5. Changing..."
	(get-cluster).CrossSubnetThreshold = 5
} Else {            
	Write-Verbose "CrossSubnetThreshold is 5."
} 

##RegisterAllProvidersIPCluster
If ((Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" }).name) | Get-ClusterParameter RegisterAllProvidersIP | Select-Object Value).value -eq 1) {            
	Write-Verbose "RegisterAllProvidersIP from Cluster is 1"
} Else {            
	Write-Verbose "RegisterAllProvidersIP from Cluster is 0. Changing..."
	Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" }).name) | Set-ClusterParameter RegisterAllProvidersIP 1
	#After change RegisterAllProvidersIP, we must restart the cluster resource
	Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" } | Stop-ClusterResource
	Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" } | Start-ClusterResource
	Return $true            
} 

##Check all changes.
##HostRecordTTLClusterTo300
Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" }).name) | Get-ClusterParameter HostRecordTTL | Select-Object Value; "Value must be 300"

##CrossSubnetDelayTo3000
(Get-Cluster)| select CrossSubnetDelay ; 'Value must be 3000'

##CrossSubnetThresholdTo5
(get-cluster) | select CrossSubnetThreshold; 'Value must be 5'

##RegisterAllProvidersIPCluster
Get-ClusterResource ((Get-ClusterResource | Where-Object { $_.ResourceType -eq "Network Name" -and $_.OwnerGroup -eq "Cluster Group" }).name) | Get-ClusterParameter RegisterAllProvidersIP | Select-Object Value; "Value must be 1"

