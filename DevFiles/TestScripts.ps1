$Timeout = 5
$timer = [Diagnostics.Stopwatch]::StartNew()


do {
    Write-Host "Waiting"
    Start-Sleep -s 1
} until ($timer.Elapsed.Seconds -ge $Timeout)

Write-Host "Done"