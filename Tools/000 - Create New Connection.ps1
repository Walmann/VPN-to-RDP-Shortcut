# $a = Read-Host -Prompt "(E)nkel eller (a)vansert konfigurering? (Avansert konfig er ikke tiljengelig ennå.) "
$a = "e"


if ($a.ToLower() -eq "e" -or $null -eq $a) {
    $New_VPN_Name           = Read-Host -Prompt "Navnet til ny tilkobling? Dette blir navnet på tilkoblingsfilen"
    $New_VPN_Username       = Read-Host -Prompt "Brukernavn for VPN?"
    $New_RDP_Server_IP      = Read-Host -Prompt "Lokal-IP til server (RDP)"
    $New_RDP_Server_Port    = Read-Host -Prompt "RDP Port (La være blank for standard RDP port)"
    $New_RDP_Username       = Read-Host -Prompt "Brukernavn for RDP (La være blank viss lik VPN bruker)"


    #Lag PBK filen, inneholder VPN instillinger
    $Path_Phonebook = ($New_VPN_Name + ".pbk")
    New-Item -Path $Path_Phonebook -ItemType File
    $Path_Full_Phonebook = Get-ChildItem -Path "./" -Filter $Path_Phonebook
    $Path_Full_Phonebook = $Path_Full_Phonebook.FullName
    # Write-Host $Path_Full_Phonebook.FullName
    # $abcd = $env:SystemRoot + "\System32\rasdial.exe"
    Start-Process -FilePath "$env:SystemRoot\System32\rasphone.exe" -ArgumentList "-f $Path_Phonebook","-a $New_VPN_Name" -Wait
    Start-Process -FilePath "$env:SystemRoot\System32\rasphone.exe" -ArgumentList "-f $Path_Phonebook","-e $New_VPN_Name" -Wait

    #Lag en kopi av template og bytt ut informasjon
    New-Item -Path "." -Name ($New_VPN_Name + ".ps1") -ItemType "file"
    $Template_Content = @"
    `$Arguments = @{
    
        # VPN_Name        = "$New_VPN_Name"             #Navnet til VPN tilkoblingen i .dep\Phonebook.pbk
        # RDP_Server_IP   = "$New_RDP_Server_IP"        #Må være IP addresse
        # RDP_Port        = "$New_RDP_Server_Port"      #Viss denne er tom brukes standard port
        # RDP_Username    = "$New_RDP_Username"
        # VPN_User        = "$New_VPN_Username"         #Viss denne er tom brukes RDP_Username
    }
        #OBS!!! Argumenter som ikke er i bruk må kommenteres ut med "#"
    
    Powershell.exe -executionpolicy Bypass -Command ".\dep\_MainConnect.ps1" @Arguments
"@
    $Path_Connect_Template = ("./$New_VPN_Name" + ".ps1")
    Add-Content -Path $Path_Connect_Template -Value $Template_Content
    
    $List_Variables_To_Change = ${New_VPN_Name},${New_VPN_Username},${New_RDP_Server_IP},${New_RDP_Server_IP},${New_RDP_Server_Port},${New_RDP_Username}

    Foreach ($Entry in $List_Variables_To_Change) {
        if ("" -ne ($Entry)){
            Set-Content -Path $Path_Connect_Template -Value (get-content -Path $Path_Connect_Template | (Select-String -Pattern $Entry).Line.Replace("#", "", 1))
        }
    } # End Foreach.


}
$cleanup = Read-Host -Prompt "Cleanup files?"
if ($cleanup -eq "y"){
    Remove-Item $Path_Phonebook
    Remove-Item $Path_Connect_Template
}
