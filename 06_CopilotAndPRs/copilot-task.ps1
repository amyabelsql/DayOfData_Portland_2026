# Files an issue for the Copilot coding agent. Run it before the talk, it takes a few minutes.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '06' 'A task for Copilot' 'Copilot can take the first pass' -Pause:$Pause

$title = 'Add ShippedAt to Orders and a usp_GetShippedOrders proc'
$url = gh issue list --state open --search "in:title `"$title`"" --json title,url --jq ".[] | select(.title == `"$title`") | .url"
if ($url) {
    Write-Step R 'The Copilot issue is already open.'
}
else {
    Write-Step W 'Create the issue and assign it to Copilot.'
    $PSNativeCommandUseErrorActionPreference = $false
    $url = gh issue create --title $title --body-file "$PSScriptRoot/copilot-issue.md" --label database-change --assignee '@copilot' 2>$null
    if ($LASTEXITCODE) {
        $PSNativeCommandUseErrorActionPreference = $true
        $url = gh issue create --title $title --body-file "$PSScriptRoot/copilot-issue.md" --label database-change
        Write-Watch 'Copilot could not be assigned from here. On the issue page:'
        Write-Clicks @('Click Assignees.', 'Pick Copilot.', 'Click Assign.')
    }
    $PSNativeCommandUseErrorActionPreference = $true
}
Write-Ok $url
Start-Process $url
Write-Watch 'Copilot opens a draft pull request in a few minutes. Show it at step 06.'
