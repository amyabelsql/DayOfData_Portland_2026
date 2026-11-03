# Waits until SQL Server answers SELECT 1, for up to 90 seconds.
param([int]$TimeoutSeconds = 90)
. "$PSScriptRoot/Common.ps1"
Import-DotEnv

$deadline = (Get-Date).AddSeconds($TimeoutSeconds)
while ((Get-Date) -lt $deadline) {
    if ((Invoke-DemoSql -Query 'SELECT 1').ExitCode -eq 0) {
        Write-Ok 'SQL Server is ready'
        exit 0
    }
    Write-Host '  ...waiting for SQL Server'
    Start-Sleep -Seconds 3
}
Write-Fail "SQL Server didn't answer within $TimeoutSeconds seconds"
exit 1
