# Puts the WHERE line back on the same PR and watches it go green.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '05' 'Fix the build' 'the same check proves the fix' -Pause:$Pause

$branch = 'demo/break-the-build'
$proc   = 'database/procs/usp_GetActiveOrders.sql'

$pr = Get-OpenPr $branch
if (-not $pr) { Write-Fail "No open pull request for $branch. Run break-it.ps1 first."; exit 1 }

Write-Step W 'Put the proc back the way it is on main, then push to the same pull request.'
git fetch origin --quiet
git switch $branch --quiet
git reset --hard "origin/$branch" --quiet
git checkout origin/main -- $proc
if (Save-DemoCommit 'Put back the WHERE clause') { git push origin $branch --quiet; Write-Ok 'Fix pushed' }
else { Write-Ok 'The fix is already pushed' }
git switch main --quiet

Write-Step R 'Watch the checks go green.'
if (Watch-PrChecks $pr) { Write-Host ""; Write-Ok 'Green. Same test, same fresh server, and the fix is proven.' }
else { Write-Fail 'Still red. Check the run log.'; exit 1 }
Open-Page (gh pr view $pr --json url --jq .url)
