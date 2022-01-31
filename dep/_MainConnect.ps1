[CmdletBinding()]
param (
    # [Parameter(Mandatory=$true)]
    [Parameter()]
    [string]$RDP_Address,

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
    [string]$VPN_User
)
$PhoneBookLocation  = ".\dep\Phonebook.pbk"


#Debug:
# $RDP_Address     = ""
# $RDP_Username    = """
# $RDP_Port        = ""                    #Viss denne er tom brukes standard port
# $RDP_Server_IP   = ""                    #Må være IP addresse
# $VPN_Name        = ""                    #Navnet til VPN tilkoblingen i .dep\Phonebook.pbk
# $VPN_User        = ""                    #Viss denne er tom brukes RDP_Username


function New-Credidential {

    #RDP Passord
    $RDPPasswordsec = Read-Host -Prompt "Passord for $VPN_Name" -AsSecureString
    $RDPPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($RDPPasswordsec))
    New-StoredCredential -Target $RDP_Server_IP -UserName $RDP_Username -Password $RDPPassword -Persist 'LocalMachine'

    # #VPN Passord
    # $VPNPWSameAsRDP = Read-Host -Prompt "Er passordet for VPN det samme som RDP? Y/N"
    # if (($VPNPWSameAsRDP -eq "Y") -or $VPNPWSameAsRDP -eq "yes") {
    #     $VPNPassword = $RDPPassword
    # }

    Return $RDPPassword
}


#Setter muligheten for å kjøre skriptet.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

#Installerer CredidentialManager
if (-Not (Get-Module -ListAvailable -Name CredentialManager)) {
    Write-Host "CredidentialManager er ikke installert. Installerer (Dette kan ta noen sekunder) "
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    Install-Module -Name CredentialManager
} 


#Lager en ny credential i Windows Legitimasjonsenter, viss den ikke finnes fra før.
if ($null -eq (Get-StoredCredential -Target "$RDP_Server_IP")) {
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
    if ([string]::IsNullOrEmpty($VPNPassword)) {
        $VPNPassword = Get-StoredCredential -Target $RDP_Server_IP
        $VPNPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($VPNPassword.Password))
        Write-Host "Using RDP Password as VPN Password"
    }
}

# Koble til VPN
Write-Host "Connecting to VPN"
rasdial.exe $VPN_Name $VPN_User $VPNPassword "/phonebook:$PhoneBookLocation"
# Write-Host $VPN_Name.ConnectionStatus


#Kobler til VPN
Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$RDP_Server_IP"
$RDPid = (Get-Process mstsc).Id
Wait-Process -Id $RDPid

Write-Host "RDP Avsluttet. Avslutter og rydder opp."
rasdial.exe $VPN_Name /DISCONNECT

# Remove-StoredCredential -Target $RDPConnection