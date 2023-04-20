
# v2.1 
#This script creates a directory as the machines hostname in the root of C:\ and pulls necessary event and IIS logs for typical engagements
#Run as admin, set-remoteexecutionpolicy unrestricted

Write-Host "
 _____ _                     _       _
| ____| |    ___ _ __   __ _| |_ ___| |__   ___ _ __
|  _| | |   / __| '_ \ / _' | __/ __| '_ \ / _ \ '__|  Event
| |___| |___\__ \ | | | (_| | || (__| | | |  __/ |     Log
|_____|_____|___/_| |_|\__,_|\__\___|_| |_|\___|_|     Snatcher
"

Write-Host "This script must be ran as admin" -Foregroundcolor Yellow
Write-Host "it will start the extraction process with the most standard event logs, do you want to begin?" -ForegroundColor Yellow

do{
    $ans = Read-Host '(Y/N)'
    if($ans -eq 'N'){Write-Host "???" -ForegroundColor Red
     return }
}
until($ans -eq 'Y')


#Creating directory
$h = hostname

New-Item C:\$h -itemType Directory | Out-Null

$d = "C:\$h"
write-host "`n"
Write-Host "Directory created at C:\$h"
#Get sysinfo and add to the new dir 
systeminfo.exe > $d\$h"info.txt" 

#Moving event log files
Set-Location C:\Windows\System32\winevt\logs\
Write-Host "Copying event logs ..."
Copy-item Application.evtx -Destination $d
Copy-item Security.evtx -Destination $d
Copy-item System.evtx -Destination $d
Copy-item "Windows PowerShell.evtx" -Destination $d
Copy-item *Microsoft-Windows-PowerShell%4Admin.evtx -Destination $d
Copy-item *Microsoft-Windows-PowerShell%4Operational.evtx -Destination $d
Copy-item *Microsoft-Windows-RemoteDesktopServices-RdpCoreTS%4Operational.evtx -Destination $d
Copy-item *Defender*.evtx -Destination $d
Write-Host "Completed all necessary event logs" -ForegroundColor Green
Write-Host "`n"

#Ask user if machine is exchange server to pull IIS and exchange logs
Write-Host "Is this an exchange server? Entering 'Y' will copy over IIS and exchange event logs (if enabled and available.)" -foregroundcolor yellow
Write-Host "Enter 'N' to return and end the script" -foregroundcolor yellow

do{
    $ans = Read-Host '(Y/N)'
    if($ans -eq 'N'){Write-Host "The copied logs are located in C:\$h" -ForegroundColor Green
    Write-Host "Don't forget to remove all .ps1 files/evidence, set the remote execution policy back to remote-signed" -ForegroundColor Green
     return }
}
until($ans -eq 'Y')

write-host "`n"
Write-Host "Copying over exchange event logs, this may take some time depending on file size ..."

Copy-item *Exchange*.evtx  -Destination $d

#get user input for amount of days back to pull IIS logs 
Write-Host "How many days back of IIS logs do you want to pull? Typical is 31, over 2 months - the file size could become too thick" -ForegroundColor Yellow

do {
  write-host -nonewline "Enter a numeric value: "
  $inputString = read-host
  $ageoflogsinput = $inputString -as [Double]
  $ok = $NULL -ne $ageoflogsinput
  if ( -not $ok ) { write-host "You must enter a numeric value" }
}
until ( $ok )

$ageoflogs = -$ageoflogsinput

Set-Location C:\inetpub\logs\LogFiles

New-Item C:\$h\iislogs -ItemType Directory | Out-Null

Write-Host "Copying over IIS logs, this may take some time depending on file size ... "
Write-Host "`n"
Write-Host "Now would be a good time to get the Exchange Server version, instructions below" -ForegroundColor Yellow
Write-Host "Open a Microsoft Exchange Management Console as Admin and paste in the following command: 'Get-ExchangeServer | Format-List Name, Edition, AdminDisplayVersion'"


#Copy over IIS logs based on age
Get-ChildItem *.log -Path . -Recurse | Where-Object {$_.LastWriteTime -gt (Get-Date).AddDays($ageoflogs)} |Copy-Item -Destination C:\$h\iislogs
write-host "`n"
Write-Host "Exchange and IIS logs completed" -ForegroundColor Green
Write-Host "`n"

#get and tell user accumulated log file size and ask if want to compress/zip 
$size = "{0:N2}" -f ((Get-ChildItem -path $d -recurse | Measure-Object -property length -sum ).sum /1GB) + " GB"

Write-Host "The file size of the accumulated event/logs is $size, do you want to compress the log file?" -foregroundcolor yellow
Write-Host "Zipping in powershell is only available in versions 5.0 and above, the current version is listed below." 
$PSVersionTable

Write-Host "`n"
Write-Host "Enter 'n' if this machine is too old and dusty, you'll have to zip manually"
do{
    $ans = Read-Host '(Y/N)'
    if($ans -eq 'N'){Write-Host "The copied logs are located in C:\$h, have a swell day" -ForegroundColor Green
     return }
}
until($ans -eq 'Y')

$final = "C:\$h.zip"

Compress-Archive -Path C:\$h -DestinationPath $final
Write-Host "`n"
write-host "Compression complete, zipped file is located here: '$final' do you want the OG file to be deleted?" -ForegroundColor Green

do{
    $ans = Read-Host '(Y/N)'
    if($ans -eq 'N'){Write-Host "Don't forget to remove all .ps1 files/evidence, set the remote execution policy back to remote-signed" -ForegroundColor Green
     return }
}
until($ans -eq 'Y')

#delete OG folder once compression is completed
Remove-Item $d -Recurse -Force
Set-Location C:\
Write-Host "`n"
Write-Host "SUCCESS, Don't forget to remove all .ps1 files/evidence, set the remote execution policy back to remote-signed" -ForegroundColor Green
