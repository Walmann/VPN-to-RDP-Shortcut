# $a = Read-Host -Prompt "(E)nkel eller (a)vansert konfigurering? (Avansert konfig er ikke tiljengelig ennå.) "
$a = "e"


if ($a.ToLower() -eq "e" -or $null -eq $a) {
    $New_VPN_Name           = Read-Host -Prompt "Navnet til ny tilkobling? Dette blir navnet på tilkoblingsfilen"
    $New_VPN_Username       = Read-Host -Prompt "Brukernavn for VPN?"
    $New_RDP_Server_IP      = Read-Host -Prompt "Lokal-IP til server (RDP)"
    $New_RDP_Server_Port    = Read-Host -Prompt "INTERN RDP Port (La være blank for standard RDP port)"
    $New_RDP_Username       = Read-Host -Prompt "Brukernavn for RDP (La være blank viss lik VPN bruker)"
    $New_VPN_And_RDP_PW_Same= Read-Host -Prompt "Er VPN og RDP Passord det samme? (Y/n)"

    $New_VPN_Config_Name    = "RDP_TO_VPN_$New_VPN_Name"

    if ([string]::IsNullOrEmpty($New_RDP_Username)){
        $New_RDP_Username = $New_VPN_Username
    }

    if ($New_VPN_And_RDP_PW_Same.ToLower -eq "y"){
        $New_VPN_And_RDP_PW_Same = $true
    }
    if ($New_VPN_And_RDP_PW_Same.ToLower -eq "n"){
        $New_VPN_And_RDP_PW_Same = $false
    }

    #Lag PBK filen, inneholder VPN instillinger
    $Path_Phonebook = ($New_VPN_Config_Name + ".pbk")
    New-Item -Path $Path_Phonebook -ItemType File
    $Path_Full_Phonebook = Get-ChildItem -Path "./" -Filter $Path_Phonebook
    $Path_Full_Phonebook = $Path_Full_Phonebook.FullName
    # Write-Host $Path_Full_Phonebook.FullName
    # $abcd = $env:SystemRoot + "\System32\rasdial.exe"
    Start-Process -FilePath "$env:SystemRoot\System32\rasphone.exe" -ArgumentList "-f `"$Path_Phonebook`"","-a `"$New_VPN_Name`"" -Wait
    Start-Process -FilePath "$env:SystemRoot\System32\rasphone.exe" -ArgumentList "-f `"$Path_Phonebook`"","-e `"$New_VPN_Name`"" -Wait

    #Lag en kopi av template og bytt ut informasjon
    New-Item -Path "." -Name ($New_VPN_Name + ".ps1") -ItemType "file"
    $Template_Content_start = @"
`$Arguments = @{

"@


    [System.Collections.ArrayList]$Template_Content_mid = @()
    if (![string]::IsNullOrEmpty($New_VPN_Name)){
        $Template_Content_mid.Add(' VPN_Name                   = ' + "`"`'$New_VPN_Name`'`"" + "`n")
        }
    if (![string]::IsNullOrEmpty($New_RDP_Server_IP)){
        $Template_Content_mid.Add(' RDP_Server_IP              = ' + "`"$New_RDP_Server_IP`"" + "`n")
        }
    if (![string]::IsNullOrEmpty($New_RDP_Server_Port)){
        $Template_Content_mid.Add(' RDP_Port                   = ' + "`"$New_RDP_Server_Port`"" + "`n")
    }
    if (![string]::IsNullOrEmpty($New_RDP_Username)){
        $Template_Content_mid.Add(' RDP_Username               = ' + "`"$New_RDP_Username`"" + "`n")
        }
    if (![string]::IsNullOrEmpty($New_VPN_Username)){
        $Template_Content_mid.Add(' VPN_User                   = ' + "`"$New_VPN_Username`"" + "`n")
        }
    if (![string]::IsNullOrEmpty($New_VPN_And_RDP_PW_Same)){
        $Template_Content_mid.Add(' VPN_And_RDP_PW_Same        = ' + "`"$New_VPN_And_RDP_PW_Same`"" + "`n")
        }
    if (![string]::IsNullOrEmpty($New_VPN_Config_Name)){
        $Template_Content_mid.Add(' VPN_Config_Name            = ' + "`"`'$New_VPN_Config_Name`'`"" + "`n")
        }
    $Template_Content_end = @"

}
#OBS!!! Argumenter som ikke er i bruk må kommenteres ut med "#"

Powershell.exe -executionpolicy Bypass -Command ".\dep\_MainConnect.ps1" @Arguments
"@


            

    $Path_Connect_Template = ("./$New_VPN_Name" + ".ps1")
    Add-Content -Path $Path_Connect_Template -Value ($Template_Content_start + $Template_Content_mid + $Template_Content_end)
    



    #Copy files to right folders
    Move-Item -Path $Path_Connect_Template -Destination "../$Path_Connect_Template"
    Move-Item -Path $Path_Full_Phonebook -Destination "../Phonebooks/$Path_Phonebook"


}
# $cleanup = Read-Host -Prompt "Cleanup files?"
# if ($cleanup -eq "y"){
#     Remove-Item $Path_Phonebook
#     Remove-Item $Path_Connect_Template
# }
