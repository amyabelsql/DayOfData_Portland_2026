# Step 06. The pull request does its own chores, and Copilot writes the first draft.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '06' 'Copilot and pull requests that run themselves' 'the pull request does the chores' -Pause:$Pause

$branch = 'demo/new-proc'
$files = [ordered]@{
    "$PSScriptRoot/new-proc/usp_GetCustomerOrderCount.sql"             = 'database/procs/usp_GetCustomerOrderCount.sql'
    "$PSScriptRoot/new-proc/test-customer-order-count.sql"             = 'database/tests/test-customer-order-count.sql'
    "$PSScriptRoot/new-proc/rollback-usp_GetCustomerOrderCount.sql"    = 'database/rollback/usp_GetCustomerOrderCount.sql'
}

git fetch origin --quiet
$PSNativeCommandUseErrorActionPreference = $false
git cat-file -e "origin/main:database/procs/usp_GetCustomerOrderCount.sql" 2>$null
$onMain = $LASTEXITCODE -eq 0
$PSNativeCommandUseErrorActionPreference = $true
if ($onMain) {
    Write-Watch 'The new proc is already merged on main. Run ./99_Cleanup/run.ps1 to reset, then try again.'
    exit 0
}

$pr = Get-OpenPr $branch
if ($pr) {
    Write-Step R "Pull request #$pr is already open for $branch. Picking up from there."
}
else {
    Write-Step W "Make branch $branch with a new proc, its test, and its rollback script."
    New-DemoBranch $branch
    foreach ($src in $files.Keys) { Copy-Item $src $files[$src] }
    Save-DemoCommit 'Add dbo.usp_GetCustomerOrderCount' | Out-Null
    git push -u origin $branch --force --quiet
    git switch main --quiet

    Write-Step W 'Open a pull request with the checklist from the template already filled in.'
    $body = (Get-Content "$RepoRoot/.github/pull_request_template.md" -Raw) `
        -replace '## What changed and why\s*\n', "## What changed and why`nAdds dbo.usp_GetCustomerOrderCount so the support team can see order counts per customer.`n`n" `
        -replace '\[ \]', '[x]'
    gh pr create --head $branch --base main --title 'Add dbo.usp_GetCustomerOrderCount' --body $body | Out-Null
    $pr = Get-OpenPr $branch
}

Write-Step W 'Ask Copilot to review it. (The ruleset may have already done this.)'
$PSNativeCommandUseErrorActionPreference = $false
gh pr edit $pr --add-reviewer '@copilot' *> $null
if ($LASTEXITCODE) { Write-Watch 'Could not request Copilot here. Click Reviewers > Copilot on the PR page.' }
$PSNativeCommandUseErrorActionPreference = $true

Write-Step R 'Watch the pull request do its own chores.'
foreach ($i in 1..6) {
    $v = gh pr view $pr --json labels,reviewRequests,latestReviews,statusCheckRollup | ConvertFrom-Json
    Write-Host ""
    Write-Host "  Labels:    $(($v.labels.name -join ', ') ?? '')" -ForegroundColor Yellow
    Write-Host "  Reviewers: $((@($v.reviewRequests.login) + @($v.latestReviews.author.login) | Where-Object { $_ } | Sort-Object -Unique) -join ', ')" -ForegroundColor Yellow
    Write-Host "  Checks:    $(($v.statusCheckRollup | ForEach-Object { "$($_.name)=$($_.status.ToLower())" }) -join ', ')" -ForegroundColor Yellow
    if ($v.labels.Count -and $v.statusCheckRollup.Count) { break }
    Start-Sleep -Seconds 10
}
Write-Watch 'CODEOWNERS adds the owner as reviewer, unless the owner is the author (that is you, on stage).'

Write-Step W 'Turn on auto-merge. It merges by itself once the required check passes.'
$PSNativeCommandUseErrorActionPreference = $false
gh pr merge $pr --auto --squash --delete-branch
if ($LASTEXITCODE) {
    Write-Watch 'Auto-merge is not available here (it needs a required check). Waiting for checks, then merging.'
    if (Watch-PrChecks $pr) { gh pr merge $pr --squash --delete-branch }
}
$PSNativeCommandUseErrorActionPreference = $true

Write-Step R 'Wait for it to merge on its own.'
foreach ($i in 1..90) {
    $state = gh pr view $pr --json state --jq .state
    if ($state -eq 'MERGED') { break }
    Start-Sleep -Seconds 10
}
if ($state -eq 'MERGED') {
    git pull --ff-only --quiet
    Write-Ok "Pull request #$pr merged itself. Nobody clicked merge."
}
else { Write-Watch "Still waiting after 15 minutes. Check: gh pr view $pr --web" }
