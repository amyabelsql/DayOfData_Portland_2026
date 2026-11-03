# Step 04. The busy work of tracking requests can run itself.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '04' 'Issue forms and a project board' 'busy work runs itself' -Pause:$Pause

$repo  = Get-Repo
$owner = $repo.Split('/')[0]
$title = 'Database Work'

# --- The board ---------------------------------------------------------------
$project = gh project list --owner $owner --format json --limit 100 | ConvertFrom-Json |
    Select-Object -ExpandProperty projects | Where-Object title -eq $title | Select-Object -First 1
if ($project) {
    Write-Step R "The project board '$title' already exists. Reusing it."
}
else {
    Write-Step W "Create the project board '$title'."
    $project = gh project create --owner $owner --title $title --format json | ConvertFrom-Json
}
$num = $project.number

Write-Step W 'Link the board to this repo.'
$PSNativeCommandUseErrorActionPreference = $false
gh project link $num --owner $owner --repo $repo *> $null   # fine if it's already linked
$PSNativeCommandUseErrorActionPreference = $true
Write-Ok "Linked project #$num"

function Get-Fields { gh project field-list $num --owner $owner --format json | ConvertFrom-Json | Select-Object -ExpandProperty fields }
$fields = Get-Fields
Write-Step W 'Add two custom fields: Server (text) and Risk (Low, Medium, High). Skips any that exist.'
if (-not ($fields | Where-Object name -eq 'Server')) {
    gh project field-create $num --owner $owner --name Server --data-type TEXT | Out-Null
}
if (-not ($fields | Where-Object name -eq 'Risk')) {
    gh project field-create $num --owner $owner --name Risk --data-type SINGLE_SELECT --single-select-options 'Low,Medium,High' | Out-Null
}
$fields  = Get-Fields
$status  = $fields | Where-Object name -eq 'Status'
$server  = $fields | Where-Object name -eq 'Server'
$risk    = $fields | Where-Object name -eq 'Risk'
Write-Ok 'Fields ready'

# --- The sample issues -------------------------------------------------------
Write-Step W 'Create the sample DBA requests, add them to the board, and set Status, Server, and Risk.'
$existing = gh issue list --state all --limit 200 --json number,title,url,state | ConvertFrom-Json
foreach ($s in Get-Content "$PSScriptRoot/sample-issues.json" -Raw | ConvertFrom-Json) {
    $issue = $existing | Where-Object title -eq $s.title | Select-Object -First 1
    $url = if ($issue) { $issue.url }
           else { gh issue create --title $s.title --body $s.body --label database-change --label needs-dba }

    $item = gh project item-add $num --owner $owner --url $url --format json | ConvertFrom-Json
    gh project item-edit --id $item.id --project-id $project.id --field-id $status.id `
        --single-select-option-id ($status.options | Where-Object name -eq $s.status).id | Out-Null
    gh project item-edit --id $item.id --project-id $project.id --field-id $server.id --text $s.server | Out-Null
    gh project item-edit --id $item.id --project-id $project.id --field-id $risk.id `
        --single-select-option-id ($risk.options | Where-Object name -eq $s.risk).id | Out-Null

    if ($s.status -eq 'Done' -and (-not $issue -or $issue.state -eq 'OPEN')) {
        gh issue close $url --reason completed | Out-Null
    }
    Write-Ok "$($s.status.PadRight(12)) $($s.title)"
}

# --- The release -------------------------------------------------------------
$PSNativeCommandUseErrorActionPreference = $false
gh release view v1.0.0 *> $null
$hasRelease = $LASTEXITCODE -eq 0
$PSNativeCommandUseErrorActionPreference = $true
if ($hasRelease) {
    Write-Step R 'Release v1.0.0 already exists.'
}
else {
    Write-Step W 'Create release v1.0.0. GitHub writes the notes from the labeled pull requests.'
    gh release create v1.0.0 --title 'v1.0.0' --generate-notes | Out-Null
    Write-Ok 'Release created'
}

# --- Show it -----------------------------------------------------------------
Write-Step R 'Open the issue form, the board, and the release.'
Open-Page "https://github.com/$repo/issues/new?template=database-change.yml"
Open-Page $project.url
Open-Page (gh release view v1.0.0 --json url --jq .url)

Write-Watch 'Two one-time clicks the API cannot do yet:'
Write-Clicks @(
    "On the board, click the view menu and switch the layout to Board.",
    "Board menu (...) > Workflows. Turn on: Auto-add to project (filter: label:database-change), Item closed (set Status to Done), and Pull request merged (set Status to Done)."
)
