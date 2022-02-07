# $1PList = Get-Content .\IPS.txt 

$enabledConnections = @() 

$IPList = @()
1..254 | ForEach-Object {$icmpresults = ping -n 1 "10.10.10.$_" 
    try { $IPList += ((($icmpresults| Select-String "reply" | Where-Object {$_  -notlike "*unreachable*" }).ToString()).Split(" ")[2]).TrimEnd(":") }
    catch { write-host "$_ is not accessable" }
} # Close Foreach

SIPList | Out-File .\IPS.txt

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


$fileIOCs = get-content .\IOCs\Files.txt
$filePath = $env:TEMP, "$env:Programfiles\Startup", "$env:USERProfile\Local Settings", "$env:Appdata\Microsoft"
$IPIOCs = Get-Content .\IOCs\IPs.txt
$regIOCs = Get-Content .\IOC\reg.txt

# Get File IOCs (iexplore.exe, adobeupdater.exe, wuauclt.exe (On every Host)) 
$remoteFiles = Invoke-Command -ComputerName $enabledConnections -ScriptBlock {
    foreach ($path in $filePath) {
        foreach ($file in $fileIOCs) {
            Get-ChildItem -Path $path
        }
    }
}

foreach ($file in $remoteFiles){
    $found = $file -in $filesIOCs
    if ($found -eq $true) {
        $file | Select-Object Name, PScomputername, FullName
    }
}


# Get Registry IOCs
$regRunItems = Invoke-Command -ComputerName $enabledConnections -Command {
    Get-Item HKLM:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object PScomputername, Name, Property
    Get-Item HKCU:\Software\Microsoft\Windows\CurrentVersion\Run | Select-Object PScomputername, Name, Property
}
 $regRunItems

# Get net Connections
$RemoteConnections = Invoke-Command -ComputerName $enabledConnections -Command {
    get-netTCPConnection | Select-Object PScomputername, RemoteAddress
}

Foreach ($address in $RemoteConnections){
    $found = $address.RemoteAddress -in $IPIOCs
    if ($found -eq $true){
        $address | Select-Object PScomputername, RemoteAddress
    }
}