<#
A dirty little script I through together because I didn't have access to PowerShellv5 or newer.

WMIC Notes from Microsoft (https://docs.microsoft.com/en-us/windows/win32/wmisdk/wmic)
#>

# This section reads in a list of IPs and tests to see if they are reachable by ICMP
$ReplyResults = @()
foreach ($node in (get-content .\42-IP-List.txt)){
    $icmpresults = ping $node -n 1 
    try {
        $ReplyResults += ((($icmpresults | Select-String "reply" | Where-Object {$_ -notlike "*unreachable*"}).ToString()).Split(" ")[2]).TrimEnd(":")
    }
    catch {
        write-host "$node is not accessable"
    }  
} 

# This section take the variable from above and loop through it and run the various WMIC Commands and stores the out put in its own directory in the local path
foreach ($machine in $ReplyResults){

    $exists = Test-Path .\$machine

    if ($exists -eq $false){
    new-item -ItemType Directory -Name $machine
    }
    
    Write-host "$machine User List"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-User-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" useraccount list brief /format:table | Tee-Object -FilePath .\$machine\$machine-User-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Running Processes"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-Process-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" process list brief | Tee-Object -FilePath .\$machine\$machine-Process-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Services List"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-service-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" service list brief | Tee-Object -FilePath .\$machine\$machine-Service-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Installed Application"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-Application-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" product list brief | Tee-Object -FilePath .\$machine\$machine-Application-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Shares List"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-Share-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" share list brief | Tee-Object -FilePath .\$machine\$machine-Share-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Startup List"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-Startup-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" startup list brief | Tee-Object -FilePath .\$machine\$machine-Startup-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Volume List"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-Volume-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" volume list brief | Tee-Object -FilePath .\$machine\$machine-Volue-list.txt -Append
    Write-host "#########################################################################################"

    Write-host "$machine Volume List"
    Write-host "#########################################################################################"
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" os get csname | Tee-Object -FilePath .\$machine\$machine-Volume-list.txt -Append
    wmic /NODE:$machine /USER:"Demo.local\vagrant" /PASSWORD:"vagrant" Win32_InstalledWin32Program | Tee-Object -FilePath .\$machine\$machine-Volue-list.txt -Append
    Write-host "#########################################################################################"
    
}

##################################################
# Compare the Reports
##################################################

$ReportFile = Get-ChildItem -Recurse | Where-Object {($_.Extension -eq ".txt") -and ($_.name -like "*Application*")} | Get-Content 


$reports = .\192.168.42.230\192.168.42.230-Application-list.txt
$testReport = Get-Content $reports
foreach ($line in $testReport){write-host ($line -Split '\s\s+')[2]}


foreach ($line in $testReport){$splitLine = ($line -Split '\s\s+'); $output | Add-Member -NotePropertyValue $splitLine[0], $splitLine[1], $splitLine[2], $splitLine[3], $splitLine[4], $splitLine[5]}

##########################################################################################################################

$TestFile = Get-Content .\192.168.42.230\192.168.42.230-Application-list.txt

$L = 0

$ReportObject = [PSCustomObject]@{}

foreach ($line in $TestFile){

	$splitline = ($line -Split '\s\s+')

    if ($L -eq 2) {$hostname = $splitLine[0]}
    elseif ($L -eq 6) {}
    elseif (($line.Length -gt 0) -and ($line[$L] -ne 6)) {Add-Member -InputObject $ReportObject @{Hostname = $hostname; Caption = $splitLine[0]; IdentifyingNumber = $splitLine[1]; Name = $splitLine[2]; Vendor = $splitLine[3]; version = $splitLine[4]}}
    
    $L++    
	
}
