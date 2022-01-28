$RDPConnection      = $args[0]
$RDPUsername        = $args[1]
$RDPPort            = $args[2] #Viss denne er tom brukes standard port
$RDPServerIP        = $args[3]
$VPNRemoteAddress   = $args[4]
$VPNUsername        = $args[5]


$VPNTempName    = "TempVPNConnection"



#Debug:
$RDPConnection  = "remote.msgproduction.no"
$RDPUsername    = "nett-opp"
$RDPPort        = "" #Viss denne er tom brukes standard port
$RDPServerIP    = "10.10.1.10" #Må være IP addresse

#Viss en VPN instilling er tom, brukes RDP info.
$VPNRemoteAddress   = ""
$VPNUsername    = ""






function New-VPN-Profile {
    $DoesVPNAlreaduExists = Get-VpnConnection -Name $VPNTempName -ErrorAction:Ignore
    if (-not ([string]::IsNullOrEmpty($DoesVPNAlreaduExists))) {
        Remove-VpnConnection -Name $VPNTempName -Force
    }

    Add-VpnConnection -Name $VPNTempName `
                      -ServerAddress $VPNRemoteAddress `
                      -SplitTunneling `
                      -RememberCredential:$true

    Set-VpnConnectionUsernamePassword -connectionname $VPNTempName `
                                      -username $VPNUsername `
                                      -password $VPNPassword `
                                      -domain ''

    Write-Host
    # $PKGlocation = "$Env:Appdata\Microsoft\Network\Connections\Pbk\rasphone.pbk"
    # ((Get-Content -path $PKGlocation -Raw) -replace 'PreviewUserPw=1','PreviewUserPw=0') | Set-Content -Path $PKGlocation |Wait-Event
    # Write-Host
}

function Wait-VPNConnection {
    $Timeout = 10
    $timer = [Diagnostics.Stopwatch]::StartNew()

    do {
        Write-Host -NoNewline "Prøver å koble til VPN. Timeout: $Timeout"
        $isconnected = Test-Connection -ComputerName "$RDPServerIP" -Count 1 -Quiet
        Start-Sleep -s 1
        # Write-Host $isconnected
    } until (($isconnected -eq "True") -or $timer.Elapsed.Seconds -ge $Timeout)
    Write-Host "Tilkoblet VPN"


    #TODO Hva skjer etter timeout.
}


function New-Credidential {

    #RDP Passord
    $RDPPasswordsec = Read-Host -Prompt "Passord for gjeldene RDP konfigurasjon ($VPNRemoteAddress / $VPNUsername): " -AsSecureString
    $RDPPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($RDPPasswordsec))
    New-StoredCredential -Target $RDPServerIP -UserName $RDPUsername -Password $RDPPassword -Persist 'LocalMachine'

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
    # Set-ExecutionPolicy Unrestricted
    Install-Module -Name CredentialManager
} 


#Lager en ny credential i Windows Legitimasjonsenter
$CredAlreadyExists = Get-StoredCredential -Target $RDPServerIP
if ([string]::IsNullOrEmpty($CredAlreadyExists)) {
    $RDPPassword = New-Credidential #Returns Passwordc
    $RDPPassword = $RDPPassword[1]
}
else {
    Write-Host "Legitimasjon finnes alerede, bruker denne."
}

#Henter VPN Instillinger
if ([string]::IsNullOrEmpty($VPNRemoteAddress) -or [string]::IsNullOrEmpty($VPNUsername) -or [string]::IsNullOrEmpty($VPNPassword) ) {
    if ([string]::IsNullOrEmpty($VPNRemoteAddress)) {
        $VPNRemoteAddress   = $RDPConnection
        Write-Host "Using RDP Adress as VPN Address"
    }
    if ([string]::IsNullOrEmpty($VPNUsername)) {
        $VPNUsername    = $RDPUsername
        Write-Host "Using RDP Username as VPN Username"
    }
    if ([string]::IsNullOrEmpty($VPNPassword)) {
        $VPNPassword    = $RDPPassword
        Write-Host "Using RDP Adress as VPN Password"
    }
}

New-VPN-Profile | Out-Null

# Koble til VPN
Write-Host "Connecting to VPN"
start-sleep -s 2
$vpn = Get-VpnConnection -Name $VPNTempName;
if($vpn.ConnectionStatus -eq "Disconnected"){
    rasdial.exe -d "$VPNTempName"
    $VPNid = (Get-Process rasdial).Id
    Wait-Process -Id $VPNid
    }
Write-Host $vpn.ConnectionStatus


#Kobler til VPN
Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$RDPServerIP"
$RDPid = (Get-Process mstsc).Id
Wait-Process -Id $RDPid

Write-Host "RDP Avsluttet. Avslutter og sletter Temp VPN"
$vpn = Get-VpnConnection -Name "$VPNTempName";
if($vpn.ConnectionStatus -eq "Connected"){
    rasdial.exe $VPNTempName /DISCONNECT;
  }

$DoesVPNAlreaduExists = Get-VpnConnection -Name $VPNTempName
if (-not ([string]::IsNullOrEmpty($DoesVPNAlreaduExists))) {
    Remove-VpnConnection -Name $VPNTempName -Force
}

# Remove-StoredCredential -Target $RDPConnection