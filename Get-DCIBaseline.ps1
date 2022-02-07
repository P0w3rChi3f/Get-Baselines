#set the environment up for winRM
Set-Location "~\desktop"
Enable-PSRemoting -SkipNetworkProfileCheck
Set-Item WSMan:\localhost\Client\TrustedHosts *

# $1PList = Get-Content .\IPS.txt 

#Build a list of responding machines
$IPList = @()
1..254 | ForEach-Object {$icmpresults = ping -n 1 "10.10.10.$_" 
    try { $IPList += ((($icmpresults| Select-String "reply" | Where-Object {$_  -notlike "*unreachable*" }).ToString()).Split(" ")[2]).TrimEnd(":") }
    catch { write-host "$_ is not accessable" }
} # Close Foreach

$IPList | Out-File .\IPS.txt

# Create a list of Machines with WinRM enabled
     #need to supress the error of no connection
$enabledConnections = @()
foreach ($IP in $IPList) {
    try {
        $winRM = Test-WSMan -ComputerName $IP
        if ($Null -ne $winRM) {$enabledConnections += $IP   
        } # Close IF
    } # Close Try
    Catch {
        if ($Error[0].ToString() -match "The client cannot connect to the destination")
        {Write-Host "$IP does not have WinRM enabled"}
    } # Close Catch
} # Close foreach

# Begin the process of finding IOCs
$fileIOCs = get-content .\IOCs\Files.txt
$filePath = $env:TEMP, "$env:Programfiles\Startup", "$env:USERProfile\Local Settings", "$env:Appdata\Microsoft"
$IPIOCs = Get-Content .\IOCs\IPs.txt
$regIOCs = Get-Content .\IOCs\reg.csv

# Get File IOCs (iexplore.exe, adobeupdater.exe, wuauclt.exe (On every Host)) 
     #need to suppress the errors

reg     $MalisiousFileFound = @()
$remoteFiles = Invoke-Command -ComputerName $enabledConnections -ScriptBlock {
    foreach ($path in $using:filePath) {
            Get-ChildItem -Path $path
    }
}

foreach ($file in $remoteFiles){
    $found = $file -in $fileIOCs
    if ($found -eq $true) {
        $file | Select-Object Name, PScomputername, FullName
        $MalisiousFileFound += $file
    }
}


# Get Registry IOCs
$MalisiousRegistryItemFound = @()

$regRunItems = Invoke-Command -ComputerName $enabledConnections -Command {
    Get-Item HKLM:\Software\Microsoft\Windows\CurrentVersion\Run
    Get-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Run
}
 
foreach ($item in $regRunItems.property){
    $found = $item -in $regIOCs.file
    if ($found -eq $true){
        $item
        $MalisiousRegistryItemFound += $item
    }
}

# Get net Connections
$malisiousRemoteConnection = @()

$RemoteConnections = Invoke-Command -ComputerName $enabledConnections -Command {
    get-netTCPConnection | Select-Object PScomputername, RemoteAddress
}

Foreach ($address in $RemoteConnections){
    $found = $address.RemoteAddress -in $IPIOCs
    if ($found -eq $true){
        $address | Select-Object PScomputername, RemoteAddress
        $malisiousRemoteConnection += $address
    }
}


Write-Host "##################################################################################"
Write-Host "##################################################################################"
Write-Host ""
Write-Host "The following malicious Files were found in the environment:"
$MalisiousFileFound | Select-Object Name, PSComputerName

Write-Host "##################################################################################"
Write-Host ""
Write-Host "The following malicious Registry Items were found in the environment:"
$MalisiousRegistryItemFound
Write-Host "##################################################################################"
Write-Host ""
Write-Host "The following malicious Remote Connections were found in the environment:"
$malisiousRemoteConnection | Select-Object RemoteAddress, PScomputername