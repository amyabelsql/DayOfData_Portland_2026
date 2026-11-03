# Step 99. Leave it ready for the next run.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '99' 'Clean up after the talk' 'reset for next time' -Pause:$Pause

if ((Read-Host 'This closes demo PRs and issues and resets main. Type RESET to continue') -cne 'RESET') {
    Write-Watch 'Nothing changed.'; exit 0
}

Write-Step W 'Close the demo pull requests (demo/* and copilot/* branches) and delete their branches.'
$prs = gh pr list --state open --limit 100 --json number,headRefName | ConvertFrom-Json |
    Where-Object { $_.headRefName -like 'demo/*' -or $_.headRefName -like 'copilot/*' }
foreach ($p in $prs) { gh pr close $p.number --delete-branch | Out-Null; Write-Ok "Closed PR #$($p.number) ($($p.headRefName))" }

Write-Step W 'Close demo issues. The sample issues from step 04 stay, so the board keeps its history.'
$keep = (Get-Content "$RepoRoot/04_TemplatesIssuesBoard/sample-issues.json" -Raw | ConvertFrom-Json).title
$issues = gh issue list --state open --limit 200 --json number,title | ConvertFrom-Json | Where-Object { $_.title -notin $keep }
foreach ($i in $issues) { gh issue close $i.number --reason 'not planned' | Out-Null; Write-Ok "Closed issue #$($i.number) $($i.title)" }

Write-Step W 'Delete any demo/* branches left on GitHub and on this machine.'
git fetch origin --prune --quiet
$current = git branch --show-current
if ($current -like 'demo/*') { git switch main --quiet }
foreach ($b in git ls-remote --heads origin 'demo/*') { $name = ($b -split 'refs/heads/')[1]; git push origin --delete $name --quiet; Write-Ok "Deleted origin/$name" }
foreach ($b in git branch --list 'demo/*' --format '%(refname:short)') { git branch -D $b --quiet; Write-Ok "Deleted local $b" }

Write-Step W 'Put database/ on main back to how it was at release v1.0.0, with a normal pull request.'
git fetch origin --tags --quiet
if (-not (git tag --list v1.0.0)) {
    Write-Watch 'No v1.0.0 release yet (step 04 makes it). Skipping the reset of main.'
}
else {
    New-DemoBranch 'reset/demo-changes'
    git rm -r -q database
    git checkout v1.0.0 -- database
    if (Save-DemoCommit 'Reset demo changes') {
        git push -u origin reset/demo-changes --force --quiet
        gh pr create --head reset/demo-changes --base main --title 'Reset demo changes' --body 'Puts database/ back to v1.0.0 after the talk.' | Out-Null
        $PSNativeCommandUseErrorActionPreference = $false
        gh pr merge reset/demo-changes --auto --squash --delete-branch
        if ($LASTEXITCODE) { gh pr checks reset/demo-changes --watch; gh pr merge reset/demo-changes --squash --delete-branch }
        $PSNativeCommandUseErrorActionPreference = $true
        Write-Ok 'Reset pull request opened. It merges after the database-tests check passes.'
    }
    else { Write-Ok 'main already matches v1.0.0. Nothing to reset.' }
    git switch main --quiet
    git branch -D reset/demo-changes --quiet
}

Write-Step W 'Stop the local SQL Server container.'
docker compose down
Write-Ok 'Ready for the next run.'
