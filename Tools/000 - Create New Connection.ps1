# $a = Read-Host -Prompt "(E)nkel eller (a)vansert konfigurering? (Avansert konfig er ikke tiljengelig ennå.) "
$a = "e"


if ($a.ToLower() -eq "e" -or $null -eq $a) {
    $New_VPN_Name = Read-Host -Prompt "Name of new VPN"
    $Path_Phonebook = ($New_VPN_Name + ".pbk")
    New-Item -Path $Path_Phonebook -ItemType File
    $Path_Full_Phonebook = Get-ChildItem -Path "./" -Filter $Path_Phonebook
    $Path_Full_Phonebook = $Path_Full_Phonebook.FullName
    # Write-Host $Path_Full_Phonebook.FullName
    rasdial.exe $Path_Full_Phonebook
   
}
$cleanup = Read-Host -Prompt "Cleanup files?"
if ($cleanup -eq "y"){
    Remove-Item $Path_Phonebook
}

##TODO: Mak kan lage en tom pbk fil, og kjøre en setup der. Også endre ting derfra.
## Åpne i RASPHONE.EXE