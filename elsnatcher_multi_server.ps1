# v2.2 
#This script creates a directory as the machines hostname in the root of C:\ and pulls necessary event and IIS logs for typical engagements
#Run as admin, set-remoteexecutionpolicy unrestricted

Write-Host "
 _____ _                     _       _
| ____| |    ___ _ __   __ _| |_ ___| |__   ___ _ __
|  _| | |   / __| '_ \ / _' | __/ __| '_ \ / _ \ '__|  Event
| |___| |___\__ \ | | | (_| | || (__| | | |  __/ |     Log
|_____|_____|___/_| |_|\__,_|\__\___|_| |_|\___|_|     Snatcher
"

# Define the path to the file containing the names
Write-Host "`n"
Write-Host " This script pulls OS versions from multiple machines from a text file of hostnames"`n "Format the text document like below."
Write-Host " TEST-AD01"`n "TEST-AD02"`n "TEST-AD03" 
Write-Host "`n"
$filepath = Read-Host "Enter the path and filename of the list of hostnames. Example: 'C:\path\to\file.txt'" `n

# Ensure filepath is legit
if (-not (Test-Path -Path $filepath)) {
    Write-Error "The file path or name is incorrect, double check it"
    return
} else {
    Write-Host "Filepath is good.. " -ForegroundColor Green 
}

# Get admin credentials 
Write-Host "Enter the domain credentials to access the remote servers" -ForegroundColor Yellow

# powershell.exe -EncodedCommand $encoded script ##base64 some shit

$cred = Get-Credential

New-Item C:\elsnatcher -ItemType Directory | Out-Null
$servers = Get-Content -Path $filepath
Write-Host "Copying event logs ..."


foreach ($server in $servers) {

  New-Item C:\elsnatcher\$server -itemType Directory | Out-Null
  $d = 'C:\elsnatcher\$server'
  $path = '\\$server\C$\Windows\System32\winevt\logs'

  try {
    
    Copy-item -Path $path\Application.evtx -Destination $d -Credential $cred
    Copy-item -Path $path\Security.evtx -Destination $d -Credential $cred
    Copy-item -Path $path\System.evtx -Destination $d -Credential $cred
    Copy-item -Path $path\"Windows PowerShell.evtx" -Destination $d -Credential $cred
    Copy-item -Path $path\*Microsoft-Windows-PowerShell%4Admin.evtx -Destination $d -Credential $cred
    Copy-item -Path $path\*Microsoft-Windows-PowerShell%4Operational.evtx -Destination $d -Credential $cred
    Copy-item -Path $path\*Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx -Destination $d -Credential $cred
    Copy-item -Path $path\*Defender*.evtx -Destination $d -Credential $cred



  } catch {
    Write-Host "Error retrieving $($server.Name): $_"
  }
}





