$ErrorActionPreference = 'SilentlyContinue'
function token
{
    Write-Host "Checking for saved password" -ForegroundColor Green
    $path = $PSScriptRoot
    $file = Join-Path -Path $path -ChildPath '\credential.txt'
    if (-not(Test-Path -Path $file  -PathType Leaf)) {
        try {
            $Pass = Read-Host "Enter the gateway password" 
            Write-Output $Pass | Out-File -FilePath $file
            Write-Host "The file [$file ] has been created to store your password." -ForegroundColor Green
        }
        catch {
            Write-Host "Oh no!"
            throw $_.Exception.Message
        }
    } else {
        Write-Host "Reading stored password from file [$file]" -ForegroundColor Red
        $Pass = Get-Content $file
    }

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
            'Rebooting Gateway.....'
            Start-Sleep -s 5
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

#Make sure we can no longer ping gateway. 
do {
    Clear-Host
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
Write-Host "Gateway is up"
Start-Sleep -Seconds 1
$StartTime = $(get-date)

do {
    Clear-Host
    $elapsedTime = $(get-date) - $StartTime
    $totalTime = "{0:HH:mm:ss}" -f ([datetime]$elapsedTime.Ticks)
    Write-Host "Gateway is up"
    Write-Host "Wait an additional 30 seconds for the gateway to establish a connection to the cell tower. "
    $seconds = [int]$totalTime.Substring(6,2)
    Write-Host $seconds "Seconds"
    Start-Sleep -Seconds 1
}
until ($seconds -gt 29)
Write-Host "Pinging Cloudflare..."
Test-Connection -ComputerName 1.1.1.1
Write-Host ""
Write-Host "Pinging Google DNS..."
Test-Connection -ComputerName 8.8.8.8
Write-Host "Exiting......."
#Unhide cursor now that we are finished. 
[Console]::CursorVisible = $true
Start-Sleep -Seconds 5