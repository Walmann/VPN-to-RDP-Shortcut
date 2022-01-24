$RDPConnection  = "remote.exaple.com"
$RDPUsername    = "username"
$RDPPort        = "" #Viss denne er tom brukes standard port
$RDPServerIP    = "10.10.10.10" #Må være IP addresse

#Viss en VPN instilling er tom, brukes RDP info.
$VPNIPAddress   = ""
$VPNUsername    = ""


Powershell.exe -executionpolicy remotesigned -Command  ".\dep\_MainConnect.ps1 $RDPConnection $RDPUsername $RDPPort $RDPServerIP $VPNIPAddress $VPNUsername"
