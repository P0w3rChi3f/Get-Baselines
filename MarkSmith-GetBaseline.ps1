$start=1
$end=110
$connectedhosts=@()
$sessions=@() #will be filled later with different sessions for the remotehost vm's
$hostfiles=@()

while ($start -le $end){
$result=(Test-Connection ""10.10.10.$start"" -count 1 -quiet)
if($result -and !($start -eq 20)){
$remotehost = ""10.10.10.$start"" #defining $remotehost variable with connected remote host from Test-Connection above
$connectedhosts += $remotehost #adds (contatenates) the connected host into the $connectedhosts a
Set-Item WSMan:\localhost\client\trustedhosts -value $remotehost -concatenate #populates trustedhosts with hosts that are connected ($remotehost)
$sessions += New-PSSession -computername $remotehost} #populates $sessions array with $remotehost sessions
$start++}

for($i=0; $i -lt $connectedhosts.length; $i++){
$trustedhost =$connectedhosts[$i]
$path = New-Item -Path ""c:\users\DCI student\Desktop\$trustedhost.txt""
Invoke-Command -computername $trustedhost -ScriptBlock{Get-Item -Path HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\} >> $path
Invoke-Command -computername $trustedhost -ScriptBlock{Get-Item -Path HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{netstat -anb} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{Get-Process} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{Get-Service} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{Get-ScheduledTask} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{Get-LocalUser -Verbose} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{(Get-ChildItem $env:TMP -Recurse -Force -ErrorAction SilentlyContinue).FullName} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{(Get-ChildItem $env:PROGRAMS -Recurse -Force -ErrorAction SilentlyContinue).FullName} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{(Get-ChildItem $env:USERPROFILE -Recurse -Force -ErrorAction SilentlyContinue).FullName} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{(Get-ChildItem $env:LOCALAPPDATA -Recurse -Force -ErrorAction SilentlyContinue).FullName} >> $path 
Invoke-Command -computername $trustedhost -ScriptBlock{(Get-ChildItem $env:APPDATA -Recurse -Force -ErrorAction SilentlyContinue).FullName} >> $path 

$hostfiles += $trustedhost
}

$iocarray=@(Get-Content 'C:\Users\DCI Student\Desktop\APTIOCs.txt')

foreach($hostfile in $hostfiles){
foreach($ioc in $iocarray){
if(Get-Content C:\Users\""DCI Student""\Desktop\$hostfile.txt | findstr -i $ioc){
Write-Host ""$ioc found on $hostfile""}
}
}"		"# If you do not want to store the password here, remove this and the next four lines
# If you are using credentialed login, delete the '#' character on the three lines below
#$passwd=ConvertTo-SecureString -String ""P@ssw0rd"" -AsPlainText -Force
#$creds=New-Object System.Management.Automation.PSCredential(""Administrator"",$passwd)
#$cred=Get-Credential $creds

# If you removed the lines above and are using credentialed login, delete the '#' character on the line below
#$cred = Get-Credential -UserName Administrator -Message ""test""

# Prepare a list to store the session objects that will be created later
$sessions=@()

# Get the Trusted Hosts value, to ensure duplicates are not needlessly added
$trusted = (Get-Item WSMan:\localhost\Client\TrustedHosts).Value

# In order to do an entire network scan, add a '#' character before $KnownHosts on the line below
$KnownHosts=@(20,56,83,107)

# In the DCI AWS environment, use the next line to perform a full network scan for live hosts by removing the first '#' character
#$KnownHosts = 2..99+101..254 # The .100 host on this network is a NAS that is blocking PSRemoting. The .1 host is the router

# In any other environment, create a range based on how you know the network to be architected
#$KnownHosts=

# Iterate the supplied list, test the resultant hosts for activity, add each live host to Trusted Hosts, and create a session for each live host
# If you are in an environment that requires credentialed login, delet the two '}' characters after '$ip' and uncomment the tail of the line below.
$KnownHosts | % { $ip=""10.10.10.$_""; if (Test-Connection -ComputerName $ip -Count 1 -Quiet) {if($ip -notin $trusted){Set-Item WSMan:\localhost\Client\TrustedHosts -Value $ip -Concatenate};$sessions+=New-PSSession -ComputerName $ip} }# -Credential $cred} }

# Get the list of filesystem IOCs and expand the environment variables
$files = Get-Content 'C:\Users\DCI Student\Desktop\files.txt' | % { if ($_.split('\')[0] -match ""%PROGRAMS%"") { $_ -replace'%PROGRAMS%','C:\Users\DCI Student\AppData\Roaming\Microsoft\Windows\Start Menu\Programs'  } elseif ($_.split('\')[0] -match ""%USERAPPDATA%"") { $_ -replace '%USERAPPDATA%','C:\Users\DCI Student\AppData\Roaming' } else { [System.Environment]::ExpandEnvironmentVariables(""$_"") } }

# Get the list of Current User registry IOCs, and extract the Run subkeys
$CUkeys = Get-Content 'C:\Users\DCI Student\Desktop\reg.txt' | % { if ($_ -match ""HKCU|CURRENT_USER"") { $_.split('""')[1]} }

# Get the list of Local Machine Registry IOCs, and extract the Run subkeys
$LMkeys = Get-Content 'C:\Users\DCI Student\Desktop\reg.txt' | % { if ($_ -match ""HKLM|LOCAL_MACHINE"") { $_.split('""')[1]} }

# Get the list of IP IOCs
$IPaddys = Get-Content 'C:\Users\DCI Student\Desktop\ips.txt'

# Iterate through each session and invoke the commands that get the goodies
foreach ($session in $sessions) 
{
  # Explicitly state the device connected to for this session
  Write-Output ""`n`n$($session.ComputerName)`n===========""

  # Send the list of commands to the host
  Invoke-Command -Session $session -ArgumentList $files,$CUkeys,$LMkeys,$IPaddys -ScriptBlock  {
    # Check for presence of filesystem IOCs
    Write-Host "" ["" -NoNewLine;
 Write-Host ""*"" -ForegroundColor Green -NoNewline;
 Write-Host ""] Checking filesystem."";
    foreach ($file in $args[0]) {Get-Item $file -Force -ErrorAction SilentlyContinue | ForEach-Object {Write-Output ""$($_.Name)    :    $($_.FullName)""}};

    # Check for Current User Run registry IOCs
    Write-Host ""`n ["" -NoNewLine;
 Write-Host ""*"" -ForegroundColor Green -NoNewline;
 Write-Host ""] Checking Current User registry run keys"";
 # Exclude all of the Powershell/Windows native properties and cast to object of type string
    $CUdump=[string](Get-ItemProperty ""HKCU:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run"" | Select-Object -ExcludeProperty ""PSChildName"",""PSDrive"",""PSParentPath"",""PSProvider"");
    # Create a regex pattern that will extract the path assigned to the key of interest, then check to see if any matches were made, and return them
    foreach ($CUkey in $args[1]) { $pattern='(?ms)(?:'+$CUkey+'=""?)(.+?)(?:""?; )'; $capture= [regex]::Match($CUdump,$pattern).Groups.Captures; if ($capture) {$capture[1].Value } }
    # foreach ($CUkey in $args[1]) {$CUdump | findstr $CUkey}
 
 # Check for Local Machine Run registry IOCs
    Write-Host ""`n ["" -NoNewLine;
 Write-Host ""*"" -ForegroundColor Green -NoNewline;
 Write-Host ""] Checking Local Machine registry run keys"";`
    $LMdump=[string](Get-ItemProperty ""HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Run\"" | Select-Object -ExcludeProperty ""PSChildName"",""PSDrive"",""PSParentPath"",""PSProvider"");
    foreach ($LMkey in $args[2]) { $lpattern='(?ms)(?:'+$LMkey+'=""?)(.+?)(?:""?; )'; $capture=[regex]::Match($LMdump,$lpattern).Groups.Captures; if ($capture) {$capture[1].Value } }
    # foreach ($LMkey in $args[2]) {$LMdump | findstr $LMkey}

    # Check for presence of network IOCs
 # NOTE: for the exercise this was intended to solve, the live connections are not persistent. Luck and timing will determine whether anything is returned for this section
    Write-Host ""`n ["" -NoNewLine;
 Write-Host ""*"" -ForegroundColor Green -NoNewline;
 Write-Host ""] Checking live connections"";
    $netConnections=Get-NetTCPConnection;
    foreach ($address in $args[3]) { $netConnections | Where-Object {$_.RemoteAddress.ToString() -match $address} | Format-Table RemoteAddress,RemotePort }
  }
  Remove-PSSession $session
}

Write-Host ""`n""