<#
Complete - System date and time
Complete - Hostname
Complete - Users and groups
Complete - Logged on users
Complete - Running processes
Complete - Services and their states
Complete - Network information
Complete - Listening network sockets
Complete - System confguration information
Complete - Mapped drives
Complete - Plug and play devices
Complete - Shared resources
Complete - Scheduled tasks
#>

# Script start, List the computername, current user, and the date the script was run.
Write-Output "************************************************************************************"
Write-Output ""
Write-Output "System Info for $($env:COMPUTERNAME)."
Write-Output ""
Write-Output "The logged on user is $($env:USERNAME)."
Write-Output ""
Write-Output "Script was run on $(get-date)."
Write-Output ""
Write-Output "************************************************************************************"

# User and Group enumeration
Write-Output "Users currently logged into this machine."
(Get-WmiObject Win32_LoggedOnUser).antecedent 
Write-Output ""
Write-Output "************************************************************************************"

Write-Output "Users account on the machine"
(Get-LocalUser).name
Write-Output ""
Write-Output "************************************************************************************"

Write-Output "Local groups on the machines"
(Get-LocalGroup).name
Write-Output ""
Write-Output "************************************************************************************"

# Start System Enumeration

# Running Services
Write-Output "Current runing services and status"
get-service | Select-Object name,status | sort-object name
Write-Output ""
Write-Output "************************************************************************************"

# Running Processes
Write-Output "Current running proceses and count"
Get-Process | Group-Object name | Select-Object count,name | sort-object name | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

# System Information
Write-Output "System Information"
get-computerinfo 
Write-Output ""
Write-Output "************************************************************************************"

#plug and Play
Write-Output "Plug and Play Devices"
Get-PnpDevice | Group-Object Friendlyname | Select-Object count,name | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

#Shared Resources
Write-Output "List of Shared folders"
get-smbshare | Select-Object name,path | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

#Schedualed tasks
Write-Output "List of schedualed tasks" 
Get-ScheduledTask | Select-Object Taskname,State | sort-object TaskName
Write-Output ""
Write-Output "************************************************************************************"

# Obtain Network information

# Machine IP Address
Write-Output "System IP Address"
Get-NetIPAddress | Select-Object IPAddress | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

# Listening network sockets
Write-output "Listening and Established Ports"
Get-NetTCPConnection | Where-Object {($_.State -like "Established*") -or ($_.State -like "Listen")} | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

# Network Adapter Information
Write-Output "Network Adapter Information"
Get-NetAdapter | Select-Object Name,InterfaceDescription,MacAddress | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

# Local Computer Routing Information
Write-Output "Network Routing Information"
Get-NetRoute | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

# Local Neighbors
Write-Output "Local Neighbor Information"
Get-NetNeighbor | Format-Table -AutoSize
Write-Output ""
Write-Output "************************************************************************************"

# Network Mapped Drives
Write-Output "List of Mapped Drives"
Get-WmiObject -Class Win32_MappedLogicalDisk | Select-Object name,ProviderName
Write-Output ""
Write-Output "************************************************************************************"



