
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
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
        #Setter muligheten for å kjøre skriptet.
        Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

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
            Write-Host "CredentialManager er nå installert!"
            Write-Host ""
        }
        else {
            Write-Host "Kan ikke finne CredentialManager. Prøv igjen, eller kontakt Tov."
        }
        if (Get-Module -ListAvailable -Name VPNCredentialsHelper){
            Write-Host "VPNCredentialsHelper er nå installert!"
            Write-Host ""
        }
        else {
            Write-Host "Kan ikke finne VPNCredentialsHelper. Prøv igjen, eller kontakt Tov."
        }
    }
    else {
        # Write-Error "Kan ikke installere dependencies. Vennligst kjør Setup.ps1 med administrator rettigheter."
        # Start-RestartWithAdmin
        
        #elevate script and exit current non-elevated runtime
        # Powershell.exe -executionpolicy Bypass -Command "./Setup.ps1" -Verb RunAs
        Start-Process -FilePath "powershell" -Verb RunAs
        exit
    }
}

Clear-Host
Write-Host "Starter installasjon."
Install-Dependencies