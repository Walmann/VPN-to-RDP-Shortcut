$RDPConnection  = $args[0]
$RDPUsername    = $args[1]
$RDPPort        = $args[2] #Viss denne er tom brukes standard port
$RDPServerIP    = $args[3]
$VPNIPAddress   = $args[4]
$VPNUsername    = $args[5]


$VPNTempName    = "Temp VPN Connection"



# param([switch]$Elevated)




function New-Credidential {

    #RDP Passord
    $RDPPasswordsec = Read-Host -Prompt "Passord for gjeldene RDP konfigurasjon ($RDPUsername): " -AsSecureString
    $RDPPassword = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($RDPPasswordsec))
    New-StoredCredential -Target $RDPServerIP -UserName $RDPUsername -Password $RDPPassword -Persist 'LocalMachine'

    # #VPN Passord
    # $VPNPWSameAsRDP = Read-Host -Prompt "Er passordet for VPN det samme som RDP? Y/N"
    # if (($VPNPWSameAsRDP -eq "Y") -or $VPNPWSameAsRDP -eq "yes") {
    #     $VPNPassword = $RDPPassword
    # }

    Return $RDPPassword
}


function New-VPN-Profile {
    $DoesVPNAlreaduExists = Get-VpnConnection -Name $VPNTempName
    if (-not ([string]::IsNullOrEmpty($DoesVPNAlreaduExists))) {
        Remove-VpnConnection -Name $VPNTempName -Force
    }

    Add-VpnConnection -Name $VPNTempName `
                      -ServerAddress $VPNIPAddress `
                      -SplitTunneling `
                      -UseWinlogonCredential
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

# #Skjekk om PC-en kan kjøre Powershell script.
# $ExecutionPolicy = Get-ExecutionPolicy
# if (($ExecutionPolicy) -ne "Unrestricted" -or ($ExecutionPolicy) -ne "Bypass") {
#     Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process
#     $ExecutionPolicy = Get-ExecutionPolicy
#     Write-Host "ExecutionPolicy er ikke riktig konfigurert. Dette skal være satt i via GPO.`n Prøv å kjør GPUPDATE /FORCE. Viss dette ikke fungerer, spør Tov om hvordan man fikser dette. `n Gjeldende ExecutionPolicy: $ExecutionPolicy"
#     Exit
# }


#Setter muligheten for å kjøre skriptet.
Set-ExecutionPolicy -ExecutionPolicy Bypass -Scope Process

if (-Not (Get-Module -ListAvailable -Name CredentialManager)) {
    Write-Host "CredidentialManager er ikke installert. Installerer (Dette kan ta noen sekunder) "
    Set-PSRepository -Name 'PSGallery' -InstallationPolicy Trusted
    # Set-ExecutionPolicy Unrestricted
    Install-Module -Name CredentialManager
} 

$CredAlreadyExists = Get-StoredCredential -Target $RDPServerIP
if ([string]::IsNullOrEmpty($CredAlreadyExists)) {
    $RDPPassword = New-Credidential #Returns Passwordc
    $RDPPassword = $RDPPassword[1]
}
else {
    Write-Host "Legitimasjon finnes alerede, bruker denne."
}

#Get VPN settings,
if ([string]::IsNullOrEmpty($VPNIPAddress) -or [string]::IsNullOrEmpty($VPNUsername) -or [string]::IsNullOrEmpty($VPNPassword) ) {
    if ([string]::IsNullOrEmpty($VPNIPAddress)) {
        $VPNIPAddress   = $RDPConnection
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

# Get-VpnConnection -Name $VPNTempName | Wait-VPNConnection
Write-Host "Connecting to VPN"
start-sleep -s 2
$vpn = Get-VpnConnection -Name $VPNIPAddress  -AllUserConnection;
if($vpn.ConnectionStatus -eq "Disconnected"){
    rasphone -d $VPNIPAddress ;
    }
Write-Host $vpn.ConnectionStatus

# Write-Debug

Start-Process "$env:windir\system32\mstsc.exe" -ArgumentList "/v:$RDPServerIP"


# Remove-StoredCredential -Target $RDPConnection