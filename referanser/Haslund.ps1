
param([switch]$Elevated)

function Test-Admin {
    $currentUser = New-Object Security.Principal.WindowsPrincipal $([Security.Principal.WindowsIdentity]::GetCurrent())
    $currentUser.IsInRole([Security.Principal.WindowsBuiltinRole]::Administrator)
}

if ((Test-Admin) -eq $false)  {
    if ($elevated) {
        # tried to elevate, did not work, aborting
    } else {
        Start-Process powershell.exe -Verb RunAs -ArgumentList ('-noprofile -noexit -executionpolicy bypass -file "{0}" -elevated' -f ($myinvocation.MyCommand.Definition))
    }
    exit
}



$VPN_connection_name = Read-Host -Prompt "Navn på ny VPN tilkobling: "
$VPN_server = Read-Host -Prompt "VPN addresse: "

$A = New-EapConfiguration
Add-VpnConnection -Name $VPN_connection_name -ServerAddress $VPN_server -TunnelType Pptp -SplitTunneling -AllUserConnection  -Force -EncryptionLevel "Required" -AuthenticationMethod Eap -EapConfigXmlStream $A.EapConfigXmlStream -PassThru #MSCHAPv2

Write-Host "Connecting to VPN"
start-sleep -s 2
$vpn = Get-VpnConnection -Name $VPN_connection_name -AllUserConnection;
if($vpn.ConnectionStatus -eq "Disconnected"){
    rasphone -d $VPN_connection_name;
    }
Write-Host $vpn.ConnectionStatus
Read-Host -Prompt "Continue? CTRL + C to quit. "


$domene = Read-Host -Prompt "Hva heter domene? "
# $adminbruker = Read-Host -Prompt "Administrator konto: "
# $adminpass = Read-Host -Prompt "Administrator passord: "

add-computer –domainname $($domene) -restart –force