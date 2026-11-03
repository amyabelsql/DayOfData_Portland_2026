# Step 05. A brand new SQL Server, a fresh deploy, and a full test run. Locally.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '05' 'A fresh SQL Server every time' 'every change gets tested' -Pause:$Pause

if (Initialize-DotEnv) { Write-Ok 'Made .env with a random SQL password (gitignored)' }

Write-Step W 'Start SQL Server 2022 in a container with docker compose.'
docker compose up -d

Write-Step R 'Wait until SQL Server answers.'
& "$RepoRoot/scripts/Wait-SqlServer.ps1"

Write-Step W 'Deploy the DemoShop database: create, schema, procs, seed.'
& "$RepoRoot/scripts/Deploy-Database.ps1"

Write-Step R 'Run every test.'
$PSNativeCommandUseErrorActionPreference = $false
& "$RepoRoot/scripts/Invoke-DatabaseTests.ps1"
$failed = $LASTEXITCODE

Write-Host ""
Write-Watch 'This exact flow runs in GitHub Actions on every pull request.'
Write-Host  '        Next: pwsh ./05_Containers/break-it.ps1   then   pwsh ./05_Containers/fix-it.ps1'
exit $failed
