[CmdletBinding()]
param (
    # # [Parameter(Mandatory=$true)]
    # [Parameter()]
    # [string]$RDP_Address,

    # [Parameter(Mandatory=$true)]
    [Parameter()]
    [string]$RDP_Username,

    [Parameter()]
    [string]$RDP_Port,

    # [Parameter(Mandatory=$true)]
    [Parameter()]
    [string]$RDP_Server_IP,

    [Parameter()]
    [string]$VPN_Name,

    [Parameter()]
    [string]$VPN_User,

    [Parameter()]
    [string]$VPN_And_RDP_PW_Same,
    
    [Parameter()]
    [string]$VPN_Config_Name
)


#Debug:
# $VPN_Name                   = ""
# $RDP_Server_IP              = ""
# $VPN_User                   = ""
# $VPN_And_RDP_PW_Same        = ""
# $VPN_Config_Name            = ""
#Debug End


$PhoneBookLocation  = ".\dep\Phonebooks\$VPN_Config_Name.pbk"
function New-Credidential {

    #RDP Passord
    $RDPPasswordsec = Read-Host -Prompt "Passord for $VPN_Name (RDP og VPN)" -AsSecureString
    $RDPPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($RDPPasswordsec))
    New-StoredCredential -Target $RDP_Server_IP -UserName $RDP_Username -Password $RDPPassword -Persist 'LocalMachine' -Comment $VPN_Name

    # # #VPN Passord
    # $VPNPWSameAsRDP = Read-Host -Prompt "Er passordet for VPN det samme som RDP? Y/N"
    # if (($VPNPWSameAsRDP.ToLower -eq "n") -or $VPNPWSameAsRDP.ToLower -eq "no") {

    #     $RDPPasswordsec = Read-Host -Prompt "Passord for $VPN_Name (VPN)" -AsSecureString
    #     $RDPPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($RDPPasswordsec))
    #     New-StoredCredential -Target $RDP_Server_IP -UserName $RDP_Username -Password $RDPPassword -Persist 'LocalMachine' -Comment $VPN_Name
    # }

    Return $RDPPassword
}


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


#Lager en ny credential i Windows Legitimasjonsenter, viss den ikke finnes fra før.
if ($null -eq (Get-StoredCredential -Target $RDP_Server_IP -AsCredentialObject)) {
    $RDPPassword = New-Credidential #Returns Passwordc
    $RDPPassword = $RDPPassword[1]
}
else {
    Write-Host "Legitimasjon finnes alerede, bruker denne."
}

#Henter VPN Instillinger
if ([string]::IsNullOrEmpty($VPN_User) -or [string]::IsNullOrEmpty($VPNPassword) ) {
    if ([string]::IsNullOrEmpty($VPN_User)) {
        $VPN_User    = $RDP_Username
        Write-Host "Using RDP Username as VPN Username"
    }
    # if ([string]::IsNullOrEmpty($VPNPassword)) {
    if ($New_VPN_And_RDP_PW_Same -eq $true) {
        $VPNPassword = Get-StoredCredential -Target $RDP_Server_IP -AsCredentialObject
        # $VPNPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VPNPassword.Password))
        $VPNPassword = $VPNPassword.Password
        Write-Host "Using RDP Password as VPN Password"
    }
    if ($New_VPN_And_RDP_PW_Same -eq $false) {
        $VPNPassword = Get-StoredCredential -Target $RDP_Server_IP -AsCredentialObject
        # $VPNPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VPNPassword.Password))
        $VPNPassword = $VPNPassword.Password
        Write-Host "Using RDP Password as VPN Password"
    }
}

#Kofigurere RDP Port variabel
if ([string]::IsNullOrEmpty($RDP_Port)){
    $RDP_IP_And_Port = ${RDP_Server_IP}
}
else {$RDP_IP_And_Port = "${RDP_Server_IP}:${RDP_Port}"}


# Koble til VPN
Write-Host "Connecting to VPN"
rasdial.exe "$VPN_Name" $VPN_User $VPNPassword "/phonebook:$PhoneBookLocation"
# Write-Host $VPN_Name.ConnectionStatus


#Kobler til RPD
Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$RDP_IP_And_Port"
$RDPid = (Get-Process mstsc).Id
Wait-Process -Id $RDPid

Write-Host "RDP Avsluttet. Avslutter og rydder opp."
rasdial.exe "$VPN_Name" /DISCONNECT

