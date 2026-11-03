# Pushes a broken change (no WHERE clause) and opens a PR, so the room watches it go red.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '05' 'Break the build' 'the tests catch it before main does' -Pause:$Pause

$branch = 'demo/break-the-build'
$proc   = 'database/procs/usp_GetActiveOrders.sql'

Write-Step W "Make branch $branch and delete the WHERE Status = 'Active' line from the proc."
New-DemoBranch $branch
(Get-Content $proc) | Where-Object { $_ -notmatch "WHERE .*Status = 'Active'" } | Set-Content $proc
git diff --stat
Save-DemoCommit 'Simplify usp_GetActiveOrders' | Out-Null

Write-Step W 'Push it and open a pull request.'
git push -u origin $branch --force --quiet
$pr = Get-OpenPr $branch
if (-not $pr) {
    gh pr create --head $branch --base main --title 'Simplify usp_GetActiveOrders' `
        --body 'Removes a line from usp_GetActiveOrders. What could go wrong?' | Out-Null
    $pr = Get-OpenPr $branch
}
git switch main --quiet
Write-Ok "Pull request #$pr is open"

Write-Step R 'Watch the checks. A fresh SQL Server spins up in Actions and runs the tests.'
if (Watch-PrChecks $pr) { Write-Watch 'Checks passed. That is not what we expected.' }
else { Write-Host ""; Write-Fail 'Red, on purpose. The test says the proc returned orders that are not Active.' }
Write-Host '        Next: pwsh ./05_Containers/fix-it.ps1'
exit 0
