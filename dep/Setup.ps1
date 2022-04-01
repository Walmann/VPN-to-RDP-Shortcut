
param([switch]$Elevated)


#Copy self to Temp folder, then check if CWD is TEMP, if yes, continue
if (-Not(Test-Path -Path "$env:temp/Setup.ps1")){
    #Set CWD to script folder
    $scriptpath = $MyInvocation.MyCommand.Path
    $dir = Split-Path $scriptpath
    Set-Location $dir


    Copy-Item -Path "./Setup.ps1" -Destination $env:temp
    Set-Location $env:temp
    Start-Process powershell.exe "./Setup.ps1"
    exit
}


function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        Write-Error "tried to elevate, did not work"
        Read-Host ""
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}


function Get-AdminStatus {([Security.Principal.WindowsPrincipal] `
    [Security.Principal.WindowsIdentity]::GetCurrent() `
    ).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

# function Start-RestartWithAdmin {
#         if (!
#         #current role
#         (New-Object Security.Principal.WindowsPrincipal(
#             [Security.Principal.WindowsIdentity]::GetCurrent()
#         #is admin?
#         )).IsInRole(
#             [Security.Principal.WindowsBuiltInRole]::Administrator
#         )
#     ) {
#         #elevate script and exit current non-elevated runtime
#         Powershell.exe -executionpolicy Bypass -Command ".\dep\Setup.ps1" -Verb RunAs
#         exit
#     }
# }

function Install-Dependencies {
    if (Get-AdminStatus) {
        Write-Host "Setter ExecutionPolucy til RemoteSigned"
        Write-Host ""
        #Setter muligheten for å kjøre skriptet.
        Set-ExecutionPolicy -ExecutionPolicy RemoteSigned #BUG Make check for ExecutionPolicy, this gives error when Policy is set in GPO.

        #Installerer CredidentialManager
        # https://www.powershellgallery.com/packages/CredentialManager/2.0
        # https://github.com/davotronic5000/PowerShell_Credential_Manager
        if (-Not (Get-Module -ListAvailable -Name CredentialManager)) {
            Write-Host "CredidentialManager er ikke installert. Installerer (Dette kan ta noen sekunder) "
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Install-Module -Name CredentialManager
        } 
        #Installerer VPNCredentialsHelper
        # https://www.powershellgallery.com/packages/VPNCredentialsHelper
        # https://github.com/paulstancer/VPNCredentialsHelper
        if (-Not (Get-Module -ListAvailable -Name VPNCredentialsHelper)) {
            Write-Host "VPNCredentialsHelper er ikke installert. Installerer (Dette kan ta noen sekunder) "
            Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
            Install-Module -Name VPNCredentialsHelper
        } 

        if (Get-Module -ListAvailable -Name CredentialManager){
            Write-Host "CredentialManager er installert!"
            Write-Host ""
        }
        else {
            Write-Host "Kan ikke finne CredentialManager. Prøv igjen, eller kontakt Tov."
            $ErrorLevel = "1"
        }
        if (Get-Module -ListAvailable -Name VPNCredentialsHelper){
            Write-Host "VPNCredentialsHelper er installert!"
            Write-Host ""
        }
        else {
            Write-Host "Kan ikke finne VPNCredentialsHelper. Prøv igjen, eller kontakt Tov."
            $ErrorLevel = "1"
        }
        if (-Not((Get-ExecutionPolicy) -eq "RemoteSigned")){
            Write-Error "ExecutionPolicy er ikke satt til RemoteSigned. Du kan endre dette ved å manuelt kjøre 'Set-ExecutionPolicy RemoteSigned'"
        }


        if (($ErrorLevel) -eq "1"){
            Read-Host "Feil ves installasjon. Se ovenfor for feilmeldinger"
        }
        else{
            Remove-Item -Path "$env:temp/Setup.ps1"
            Read-Host "Installasjon suksessfull! Trykk Enter for å fortsette"
            exit
        }
    }
    else {
        # Write-Error "Kan ikke installere dependencies. Vennligst kjør Setup.ps1 med administrator rettigheter."
        # Start-RestartWithAdmin
        Write-Error "Scriptet er ikke startet med admin rettigheter. Dette skal skje automatisk."    
        Read-Host ""    
        #elevate script and exit current non-elevated runtime
        # Powershell.exe -executionpolicy Bypass -Command "./Setup.ps1" -Verb RunAs
        # Start-Process -FilePath "powershell" -Verb RunAs
        # exit
    }
}

Clear-Host
Write-Host "Starter installasjon."
Install-Dependencies
# Remove-Item -Path "$env:temp/Setup.ps1"