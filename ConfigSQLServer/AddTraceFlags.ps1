
##Add all traceFlags
[String[][]]$TraceFlags = @("-T1118","-T1117")
$Path = "HKLM:\SOFTWARE\Microsoft\Microsoft SQL Server\MSSQL15.SQL2019\MSSQLServer\Parameters\" 
$getSQLArg = Get-Item $Path
$count = ($getSQLArg).ValueCount 
$CreateTf = $True

foreach ($tf in $TraceFlags) {
	foreach ($arg in $getSQLArg.Property)
	{
		if ($getSQLArg.GetValue($arg) -eq $tf)
		{
			write-host "found $tf ..."
			$CreateTf = $False
		}
	}
	if ($CreateTf)
	{
		$sqlarg = "SQLArg" + $count
		write-host "Creating $sqlarg to $tf"
		Set-ItemProperty $path -name $sqlarg -value "$tf"
		$count = $count + 1
	}
	$CreateTf = $True	
}
