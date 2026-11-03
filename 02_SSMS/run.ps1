# Step 02. You don't have to leave SSMS to work with GitHub.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '02' 'SSMS meets GitHub' 'your scripts are code' -Pause:$Pause

$branch = 'demo/ssms-change'
$repo = Get-Repo

git fetch origin --quiet
$PSNativeCommandUseErrorActionPreference = $false
git rev-parse --verify --quiet "origin/$branch" *> $null
$exists = $LASTEXITCODE -eq 0
$PSNativeCommandUseErrorActionPreference = $true

if ($exists) {
    Write-Step R "Branch $branch is already on GitHub, so we'll reuse it."
}
else {
    Write-Step W "Make a fresh branch, $branch, and push it so SSMS can see it."
    New-DemoBranch $branch
    git push -u origin $branch --quiet
    git switch main --quiet
    Write-Ok "Pushed $branch"
}

Write-Step R 'Now switch to SSMS 22 and do this:'
Write-Clicks @(
    "Git > Clone Repository, paste https://github.com/$repo.git (or open your existing clone).",
    "In the status bar, switch the branch to $branch.",
    'Open database/procs/usp_GetActiveOrders.sql.',
    'Ask Copilot in SSMS: "Explain this procedure."',
    'Make a small safe edit, like a better comment at the top.',
    'Git > Commit or Stash, write a message, then Commit All and Push.'
)
[void](Read-Host "`n      Press Enter after you've pushed from SSMS")

$ahead = 0
while ($true) {
    git fetch origin --quiet
    $ahead = [int](git rev-list --count "origin/main..origin/$branch")
    if ($ahead -gt 0) { break }
    Write-Watch "No commits on $branch yet. Push from SSMS, then press Enter."
    [void](Read-Host '      Press Enter to check again')
}
Write-Ok "Found $ahead commit(s) on $branch"

$pr = Get-OpenPr $branch
if ($pr) {
    Write-Step R "A pull request is already open (#$pr). Opening it."
}
else {
    Write-Step W 'Open a pull request from the commit you just made.'
    gh pr create --head $branch --base main --fill --label database
    $pr = Get-OpenPr $branch
}
gh pr view $pr --web
Write-Ok 'Your SSMS change now has history, a reviewer, and a way back.'
