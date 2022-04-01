$Arguments = @{
    
    RDP_Address     = "remote.example.no"
    RDP_Username    = "Username"
    # RDP_Port        = ""                    #Viss denne er tom brukes standard port
    RDP_Server_IP   = "10.10.10.10"         #Må være IP addresse
    VPN_Name        = "TempVpn"             #Navnet til VPN tilkoblingen i .dep\Phonebook.pbk
    # VPN_User        = ""                    #Viss denne er tom brukes RDP_Username
}


Powershell.exe -executionpolicy Bypass -Command  ".\dep\_MainConnect.ps1" @Arguments
