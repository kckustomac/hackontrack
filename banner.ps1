ECHO $PSScriptRoot
$ROOTPATH=($pwd).path
CD /
CD '$ROOTPATH'
PWD
@ECHO OFF
CLS
ECHO. > .\BRIGHTSPRING.BANNER
ECHO. >> .\BRIGHTSPRING.BANNER
ECHO. >> .\BRIGHTSPRING.BANNER
ECHO. >>██████╗ ██████╗ ██╗ ██████╗ ██╗  ██╗████████╗███████╗██████╗ ██████╗ ██╗███╗   ██╗ ██████╗  >> .\BRIGHTSPRING.BANNER
ECHO. >>██╔══██╗██╔══██╗██║██╔════╝ ██║  ██║╚══██╔══╝██╔════╝██╔══██╗██╔══██╗██║████╗  ██║██╔════╝  >> .\BRIGHTSPRING.BANNER  
ECHO. >>██████╔╝██████╔╝██║██║  ███╗███████║   ██║   ███████╗██████╔╝██████╔╝██║██╔██╗ ██║██║  ███╗ >> .\BRIGHTSPRING.BANNER  
ECHO. >>██╔══██╗██╔══██╗██║██║   ██║██╔══██║   ██║   ╚════██║██╔═══╝ ██╔══██╗██║██║╚██╗██║██║   ██║ >> .\BRIGHTSPRING.BANNER  
ECHO. >>██████╔╝██║  ██║██║╚██████╔╝██║  ██║   ██║   ███████║██║     ██║  ██║██║██║ ╚████║╚██████╔╝ >> .\BRIGHTSPRING.BANNER  
ECHO. >>╚═════╝ ╚═╝  ╚═╝╚═╝ ╚═════╝ ╚═╝  ╚═╝   ╚═╝   ╚══════╝╚═╝     ╚═╝  ╚═╝╚═╝╚═╝  ╚═══╝ ╚═════╝  >> .\BRIGHTSPRING.BANNER  
ECHO. >> .\BRIGHTSPRING.BANNER
ECHO. >> .\BRIGHTSPRING.BANNER
ECHO. >> .\BRIGHTSPRING.BANNER
    if (!(Test-Path $ROOTPATH\BRIGHTSPRING.BANNER)) {
        Write-Output $ROOTPATH\BRIGHTSPRING.BANNER
     }

