
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


# $PKGlocation = "$Env:Appdata\Microsoft\Network\Connections\Pbk\rasphone.pbk"
# ((Get-Content -path $PKGlocation -Raw) -replace 'PreviewUserPw=1','PreviewUserPw=0') | Set-Content -Path $PKGlocation |Wait-Event
# Write-Host
