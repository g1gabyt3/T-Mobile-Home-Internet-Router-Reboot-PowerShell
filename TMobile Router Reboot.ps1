$ErrorActionPreference = 'SilentlyContinue'
function token
{

#replace PASSWORD below with the password to your router. 	
$Pass = "PASSWORD"
$body = @"
{
"username": "admin",
"password": "$Pass"
}
"@
$login = Invoke-RestMethod -Method POST -Uri "http://192.168.12.1/TMI/v1/auth/login" -Body $body
$token = $login.auth.token
$global:header = @{Authorization="Bearer $token"}

}

function Show-Menu
{
    param (
        [string]$Title = 'My Menu'
    )
    Clear-Host
    Write-Host "Options for Gateway"
    Write-Host "y: Press 'y' to Reboot Gateway."    
    Write-Host "n: Press 'n' to Quit."
}

function reboot
{

    $response = Invoke-RestMethod -TimeoutSec 1 -Method POST -Uri "http://192.168.12.1/TMI/v1/gateway/reset?set=reboot" -headers $global:header

}

function menu
{
    Show-Menu -Title 'My Menu'
    $selection = Read-Host "Please make a selection"
    switch ($selection)
    {
           'y' {
            token
            'Rebooting Gateway'
            Start-Sleep -s 1
            reboot
            return
         
         } 'n' {
            Exit
            return
         }
     }

 }
menu

$response

#hide cursor because it flashes when it goes through each of the loops below and is distracting. 
[Console]::CursorVisible = $false
Start-Sleep -Seconds 5
Write-Host "Rebooting gateway......"
Start-Sleep -Seconds 5

#Make sure we can no longer ping gateway. 
do {
    clear
    Write-Host "Waiting for gateway to shutdown..."
    Start-Sleep -Seconds 1
}
while (Test-Connection -ComputerName 192.168.12.1 -Quiet -Count 1)

#gateway is down now we can continue
Write-Host "Gateway has shutdown. We will test for it to come back online."
Start-Sleep -Seconds 3
$StartTime = $(get-date)

#loop until we can ping gateway again
do {
    Clear-Host
    #Output a timer so we know so we can see how long we've been waiting.
    $elapsedTime = $(get-date) - $StartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Output "Elapsed Time: " $totalTime
    Write-Host
    Write-Host "Testing connnection to 192.168.12.1...."
    Start-Sleep -Seconds 1
}
until (Test-Connection -ComputerName 192.168.12.1 -Quiet -Count 1)
#Gateway is now pingable. 
Write-Host "192.168.12.1 is up"

#Wait another 30 seconds to give router time to establish a connection to T-Mobile. 
Start-Sleep -Seconds 30

#Unhide cursor now that we are finished. 
[Console]::CursorVisible = $true