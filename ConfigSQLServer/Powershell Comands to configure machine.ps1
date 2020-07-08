
$ErrorActionPreference = "Stop"

If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator"))
{   
	$arguments = "& '" + $myinvocation.mycommand.definition + "'"
	Start-Process powershell -Verb runAs -ArgumentList $arguments
	Break
}

try
{
    ##Disable Firewall
    IF ('True' -in (Get-NetFirewallProfile -All).Enabled){
	    Write-Output "Disabling Firewalls";
	    netsh advfirewall set allprofiles state off
    } ELSE {
	    Write-Output "All Firewalls are disabled";
    }

    ##EnableDEP
    Write-Output "Enabling DEP";
    bcdedit.exe /set "{current}" nx OptIn

    ##TimeToDisplayListOfSO
    Write-Output "Time To Displays List of SO set to 5 secs";
    bcdedit.exe /timeout 5

    ##SmallMemoryDump
    IF (Test-Path -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl") {
	    IF (((Get-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl").CrashDumpEnabled) -ne 3) {
		    Write-Output "Setting CrashDumpEnabled to 3";
		    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\CrashControl" -Name "CrashDumpEnabled" -Value 3;
	    } ELSE {
		    Write-Output "CrashDumpEnabled is OK";
	    }
    }
    ##Enable Netbios
    $InstanceId = (Get-NetAdapter -Name "*" | select -Property "InstanceID").InstanceId
    IF ((Get-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$InstanceId" -Name NetbiosOptions).NetbiosOptions -ne 1){
	    Write-Output "Setting Enable Netbios";
	    Set-ItemProperty -Path "HKLM:SYSTEM\CurrentControlSet\Services\NetBT\Parameters\Interfaces\Tcpip_$InstanceId" NetbiosOptions -Type DWORD -Value 1 -Force
    } ELSE {
	    "NetBios is already Enabled"
    }
  
    ##Install Windows Feature
    import-module servermanager
    $FeatureInstalled = (Get-WindowsFeature -Name Telnet-Client,File-Services,Failover-Clustering,RSAT-Clustering-AutomationServer,RSAT-Clustering-PowerShell,RSAT-Clustering-CmdInterface,RSAT-AD-PowerShell | where Installed).name
    $InstallFeature = (Get-WindowsFeature -Name Telnet-Client,File-Services,Failover-Clustering,RSAT-Clustering-AutomationServer,RSAT-Clustering-PowerShell,RSAT-Clustering-CmdInterface,RSAT-AD-PowerShell | where InstallState -ne Installed).name

    IF ($FeatureInstalled.count -gt 0) {Write-Output "Windows Features already installed: $($FeatureInstalled -join ", ")"}
    IF ($InstallFeature.count -gt 0) {
	    Write-Output "Will Install features: $($InstallFeature -join ", ")"
	    Foreach ($feature IN $InstallFeature) {
		    Write-Output "Installing Feature $feature ..."
		    Install-WindowsFeature -Name $Feature
	    }
    }

    ##Disable IPV6
    ##Get-NetAdapterBinding
    $NetAdapterName = (Get-NetAdapterBinding | where {$_.ComponentID -eq 'ms_tcpip6'}).name ##Pega os nomes de NetAdapterBinding para dar disable no IPV6
    IF ((Get-NetAdapterBinding -ComponentID "ms_tcpip6").Enabled -eq "True") {
	    Write-Output "Disabling IPV6 on NetAdapterBinding";
	    Disable-NetAdapterBinding -Name $NetAdapterName -ComponentID ms_tcpip6
    } ELSE {
	    Write-Output "IPV6 is disabled on NetAdapterBinding";
    }

    IF (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\') {
	    IF ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\').DisabledComponents -ne [int]'0xffffffff') { 
		    Write-Output "IPV6 is disabled";
	    } ELSE {
		    Write-Output "Disabling IPV6 on REGEDIT";
		    SET-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\' -Name  'DisabledComponents' -Value '0xffffffff'
	    }
    } ELSE {
	    New-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip6\Parameters\' -Name  'DisabledComponents' -Value '0xffffffff' -PropertyType 'DWord'
    }


    ##LargeScaleWorkaloads
    IF (Test-Path 'HKLM:\SYSTEM\CurrentControlSet\services\pvscsi\Parameters\Device'){
	    IF ((Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\services\pvscsi\Parameters\Device').DriverParameter -ne 'RequestRingPages=32,MaxQueueDepth=254'){
		    Write-Output "DriverParameter for LargeScaleWorkaloads wrong, altering";
		    Set-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\services\pvscsi\Parameters\Device' -Name  'DriverParameter' -Value 'RequestRingPages=32,MaxQueueDepth=254';
	    } ELSE {
		    Write-Output "DriverParameter for LargeScaleWorkaloads is OK";
	    }
    } ELSE {
	    Write-Output "Creating LargeScaleWorkaloads";
	    New-Item 'HKLM:\SYSTEM\CurrentControlSet\services\pvscsi\Parameters\Device'
	    New-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\services\pvscsi\Parameters\Device' -Name  'DriverParameter' -Value 'RequestRingPages=32,MaxQueueDepth=254' -PropertyType "String"
    }

    $MSDTCNeedsRestart = $False
    ##DTCAllowOnlySecureRpcCalls
    if ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC').AllowOnlySecureRpcCalls -ne '00000000') {
       Write-output 'Changing MSDTC AllowOnlySecureRpcCalls to 00000000'
       Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC' -Name 'AllowOnlySecureRpcCalls' -Value '00000000' 
       $MSDTCNeedsRestart = $True
    } ELSE {
       Write-Output 'MSDTC AllowOnlySecureRpcCalls Is OK'
    }

    ##DTCTurnOffRpcSecurity
    if ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC').TurnOffRpcSecurity -ne '00000001') {
       Write-output 'Changing MSDTC TurnOffRpcSecurity to 00000001'
       Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC' -Name 'TurnOffRpcSecurity' -Value '00000001' 
       $MSDTCNeedsRestart = $True
    } ELSE {
       Write-Output 'MSDTC TurnOffRpcSecurity Is OK'
    }

    ##DTCNetworkDtcAccess
    if ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC\Security').NetworkDtcAccess -ne '00000001') {
       Write-output 'Changing MSDTC NetworkDtcAccess to 00000001'
       Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC\Security' -Name 'NetworkDtcAccess' -Value '00000001' 
       $MSDTCNeedsRestart = $True
    } ELSE {
       Write-Output 'MSDTC NetworkDtcAccess Is OK'
    }

    ##DTCXaTransactions
    if ((Get-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC\Security').XaTransactions -ne '00000001') {
       Write-output 'Changing MSDTC XaTransactions to 00000001'
       Set-ItemProperty 'HKLM:\SOFTWARE\Microsoft\MSDTC\Security' -Name 'XaTransactions' -Value '00000001' 
       $MSDTCNeedsRestart = $True
    } ELSE {
       Write-Output 'MSDTC XaTransactions Is OK'
    }

    IF ($MSDTCNeedsRestart -eq $True) {
	    Write-output 'MSDTC changed, needs restart'
        Write-output 'Restarting MSDTC ...'
	    Get-Service MSDTC | Restart-Service
        Write-output 'MSDTC Restarted'
    } ELSE {
	    Write-output 'All configs for MSDTC are ok'
    }

    Read-Host -Prompt "Press Enter to exit"
}
catch
{
    Write-Error $_.Exception.ToString()
    Read-Host -Prompt "The above error occurred. Press Enter to exit."
}