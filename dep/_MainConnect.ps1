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
# $VPN_User                   = ""
# $VPN_And_RDP_PW_Same        = ""
# $VPN_Config_Name            = ""
# $RDP_Server_IP              = ""
#Debug End


$PhoneBookLocation  = ".\Phonebooks\$VPN_Config_Name.pbk"
if ($VPN_And_RDP_PW_Same -eq "n"){
    $VPN_And_RDP_PW_Same = $false
}
if ($VPN_And_RDP_PW_Same -eq "y"){
    $VPN_And_RDP_PW_Same = $true
}


function New-Credidential {

    #RDP Passord
    $RDPPasswordsec = Read-Host -Prompt "Passord for $VPN_Name (RDP)" -AsSecureString
    $RDPPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($RDPPasswordsec))
    New-StoredCredential -Target $RDP_Server_IP -UserName "$RDP_Username" -Password $RDPPassword -Persist 'LocalMachine' -Comment "$VPN_Name"

    Return $RDPPassword
}




#Sjekker om Dependencies er installert.
if ((-Not (Get-Module -ListAvailable -Name CredentialManager)) -or (-Not (Get-Module -ListAvailable -Name VPNCredentialsHelper))) {
    Write-Error "Kan ikke finne dependencies. Vennligst kjør Setup.ps1"
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
    if ($VPN_And_RDP_PW_Same -eq $true) {
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
Write-Host "Connecting to VPN with stored credentials"
rasdial.exe "$VPN_Name" "$VPN_User" $VPNPassword "/phonebook:$PhoneBookLocation"



if (-Not (Test-Connection -ComputerName $RDP_Server_IP -Count 1 -Quiet)){
[System.Windows.MessageBox]::Show(" Kunne ikke koble til VPN. `nDette betyr enten feil i instillinger, eller ingen lagret passord. `n I neste vindu velger du 'Koble til' deretter fyller du ut innloggings informasjonen.")
rasphone -FilePath $PhoneBookLocation
$RasPid = (Get-Process rasphone).Id
Wait-Process -Id $RasPid
}


#Kobler til RPD
Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$RDP_IP_And_Port"
$RDPid = (Get-Process mstsc).Id
Wait-Process -Id $RDPid

Write-Host "RDP Avsluttet. Avslutter og rydder opp."
rasdial.exe "$VPN_Name" /DISCONNECT

