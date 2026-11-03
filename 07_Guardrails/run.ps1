# Step 07. A little chaos is fun on stage. In production, you want a safety net.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '07' 'Guardrails I add every time' 'automation needs a safety net' -Pause:$Pause

Write-Step R 'Grade a workflow that breaks every rule on purpose. Expect all red.'
& "$PSScriptRoot/Test-Guardrails.ps1" -Path "$PSScriptRoot/examples/risky-workflow.yml"
if ($LASTEXITCODE) { Write-Watch 'All red, as expected. That one never runs, it lives outside .github/workflows.' }
$global:LASTEXITCODE = 0

Write-Step R 'Grade the real workflows in this repo. Expect all green.'
& "$PSScriptRoot/Test-Guardrails.ps1"

Write-Step W 'Start the nightly check with simulate_failure=true, so it fails and files its own bug.'
$run = Start-Workflow '07-nightly-check.yml' @('simulate_failure=true')
Write-Watch "Run $run started. Watch it go red."
gh run watch $run

Write-Step R 'Show the issue the workflow opened on its own.'
Start-Sleep -Seconds 5
gh issue list --label automation --label needs-dba --state open --limit 3
$url = gh issue list --label automation --label needs-dba --state open --limit 1 --json url --jq '.[0].url'
if ($url) { Start-Process $url; Write-Ok 'Nobody had to notice. The workflow filed the bug.' }
else      { Write-Watch "No issue yet. Check the run: gh run view $run --web" }
