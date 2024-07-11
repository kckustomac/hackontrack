ECHO $PSScriptRoot
$ROOTPATH=($pwd).path
CD /
CD $ROOTPATH
PWD
CLS

function Cyan
{
    process { Write-Host $_ -ForegroundColor Cyan }
}

function White
{
    process { Write-Host $_ -ForegroundColor White }
}

$BANNER = [System.IO.File]::ReadAllLines('$PSScriptRoot\BANNER.BANNER')

Write-Output $BANNER | Cyan
Write-Output $BANNER | White
Write-Host $ROOTPATH\BANNER.BANNER

Pause
Get-Content $PSScriptRoot\BANNER.BANNER -Tail 10
PAUSE
Get-Content $PSScriptRoot\BANNER.BANNER -Tail 10 | Cyan
PAUSE
Get-Content $PSScriptRoot\BANNER.BANNER -Tail 10 | White
PAUSE

