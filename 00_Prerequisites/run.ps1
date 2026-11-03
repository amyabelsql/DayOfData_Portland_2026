# Step 00. Get set up once, then everything else is one command.
#   pwsh ./00_Prerequisites/run.ps1
#   pwsh ./00_Prerequisites/run.ps1 -RepoName my-copy -Visibility public   (only used when the repo doesn't exist yet)
param(
    [string]$RepoName = (Split-Path (Split-Path $PSScriptRoot -Parent) -Leaf),
    [ValidateSet('public', 'private')][string]$Visibility = 'public',
    [switch]$Pause
)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '00' 'Before the talk' 'get set up once' -Pause:$Pause

# --- 1. Tools ------------------------------------------------------------------
Write-Step R 'Check that the tools are installed.'
$tools = @(
    @{ Name = 'pwsh';   Cmd = { $PSVersionTable.PSVersion.ToString() };            Mac = 'brew install powershell';   Win = 'winget install Microsoft.PowerShell' }
    @{ Name = 'docker'; Cmd = { (docker --version) -replace 'Docker version ', '' }; Mac = 'Install Docker Desktop';  Win = 'winget install Docker.DockerDesktop' }
    @{ Name = 'sqlcmd'; Cmd = { (sqlcmd --version | Select-Object -First 1) };     Mac = 'brew install sqlcmd';       Win = 'winget install sqlcmd' }
    @{ Name = 'gh';     Cmd = { (gh --version | Select-Object -First 1) -replace 'gh version ', '' }; Mac = 'brew install gh'; Win = 'winget install GitHub.cli' }
    @{ Name = 'git';    Cmd = { (git --version) -replace 'git version ', '' };      Mac = 'xcode-select --install';    Win = 'winget install Git.Git' }
)
$missing = 0
$table = foreach ($t in $tools) {
    if ($t.Name -eq 'pwsh' -or (Get-Command $t.Name -ErrorAction SilentlyContinue)) {
        [pscustomobject]@{ Tool = $t.Name; Status = 'OK'; Version = (& $t.Cmd) }
    }
    else {
        $hint = if ($IsWindows) { $t.Win } else { $t.Mac }
        if ($t.Name -ne 'sqlcmd') { $missing++ }
        [pscustomobject]@{ Tool = $t.Name; Status = 'MISSING'; Version = "Install: $hint" }
    }
}
$table | Format-Table -AutoSize | Out-String | Write-Host
if (-not (Get-Command sqlcmd -ErrorAction SilentlyContinue)) {
    Write-Watch 'sqlcmd is optional locally. Without it, the scripts use the sqlcmd inside the SQL Server container.'
}
if ($PSVersionTable.PSVersion.Major -lt 7) { Write-Fail 'Run this with PowerShell 7 (pwsh).'; exit 1 }
if ($missing) { Write-Fail 'Install the missing tools, then run this again.'; exit 1 }

# --- 2. GitHub access ----------------------------------------------------------
Write-Step R 'Check that gh is logged in and has the project scope (for the board in step 04).'
$auth = gh auth status 2>&1 | Out-String
if ($auth -notmatch 'project') {
    Write-Watch 'The project scope is missing. Run this, then run this script again:'
    Write-Host  '        gh auth refresh -s project' -ForegroundColor Yellow
    exit 1
}
Write-Ok 'gh is logged in with the project scope'

# --- 3. .env -------------------------------------------------------------------
Write-Step W 'Make the local password file, .env, with a random strong password. It is gitignored.'
if (Initialize-DotEnv) { Write-Ok 'Created .env' } else { Write-Ok '.env already exists. Leaving it alone.' }

# --- 4. The repo ---------------------------------------------------------------
$PSNativeCommandUseErrorActionPreference = $false
$repo = gh repo view --json nameWithOwner --jq .nameWithOwner 2>$null
$PSNativeCommandUseErrorActionPreference = $true
if ($repo) {
    Write-Step R "The repo $repo already exists."
}
else {
    Write-Step W "Create the $Visibility repo $RepoName on GitHub and push this folder to it."
    gh repo create $RepoName "--$Visibility" --source . --push
    $repo = Get-Repo
}
git fetch origin --quiet
$ahead = [int](git rev-list --count origin/main..main)
if ($ahead) {
    Write-Step W "Push $ahead local commit(s) on main to GitHub, before the ruleset turns on."
    git push origin main --quiet
}

# --- 5. Settings ---------------------------------------------------------------
Write-Step W 'Turn on auto-merge, delete branch on merge, and the wiki.'
$PSNativeCommandUseErrorActionPreference = $false
gh repo edit $repo --enable-auto-merge --delete-branch-on-merge --enable-wiki
if ($LASTEXITCODE) { Write-Watch 'Some settings did not apply. Private repos on a free plan cannot use every feature.' }
else { Write-Ok 'Settings on' }
$PSNativeCommandUseErrorActionPreference = $true

# --- 6. Labels -----------------------------------------------------------------
Write-Step W 'Create the labels. --force updates any that already exist.'
$labels = [ordered]@{
    'database-change' = @('B60205', 'A request to change a database')
    'database'        = @('1D76DB', 'Touches the database folder')
    'docs'            = @('0E8A16', 'Documentation')
    'automation'      = @('5319E7', 'Workflows and scripts')
    'needs-dba'       = @('D93F0B', 'Waiting on a DBA')
    'dependencies'    = @('0366D6', 'Dependency updates')
    'good-first-try'  = @('7057FF', 'A good first change to try')
}
foreach ($name in $labels.Keys) {
    gh label create $name --color $labels[$name][0] --description $labels[$name][1] --force | Out-Null
}
Write-Ok "$($labels.Count) labels ready"

# --- 7. Seed history -----------------------------------------------------------
Write-Step W 'Seed some history: three small labeled pull requests, merged now, before the ruleset exists.'
$seeds = @(
    @{ Branch = 'seed/docs';       Label = 'docs';       Title = 'Add a contributing guide';         Src = 'CONTRIBUTING.md';               Dest = 'CONTRIBUTING.md' }
    @{ Branch = 'seed/database';   Label = 'database';   Title = 'Add an index on Orders.OrderDate'; Src = '03-orders-orderdate-index.sql'; Dest = 'database/schema/03-orders-orderdate-index.sql' }
    @{ Branch = 'seed/automation'; Label = 'automation'; Title = 'Turn on Dependabot for actions';   Src = 'dependabot.yml';                Dest = '.github/dependabot.yml' }
)
foreach ($s in $seeds) {
    $PSNativeCommandUseErrorActionPreference = $false
    git cat-file -e "origin/main:$($s.Dest)" 2>$null
    $done = $LASTEXITCODE -eq 0
    $PSNativeCommandUseErrorActionPreference = $true
    if ($done) { Write-Ok "Already merged: $($s.Title)"; continue }

    New-DemoBranch $s.Branch
    Copy-Item "$PSScriptRoot/seed/$($s.Src)" $s.Dest
    Save-DemoCommit $s.Title | Out-Null
    git push -u origin $s.Branch --force --quiet
    git switch main --quiet
    gh pr create --head $s.Branch --base main --title $s.Title --body 'Seeded by 00_Prerequisites so release notes have real history.' --label $s.Label | Out-Null
    gh pr merge $s.Branch --squash --delete-branch | Out-Null
    git fetch origin --quiet
    Write-Ok "Merged: $($s.Title)"
}
git pull --ff-only --quiet

# --- 8. Ruleset ----------------------------------------------------------------
Write-Step W 'Protect main with a ruleset: pull request required, database-tests must pass, Copilot reviews.'
$rules = Get-Content "$PSScriptRoot/ruleset.json" -Raw | ConvertFrom-Json
$rules.PSObject.Properties.Remove('_comment')
$PSNativeCommandUseErrorActionPreference = $false
$existing = gh api "repos/$repo/rulesets" --jq ".[] | select(.name == `"$($rules.name)`") | .id" 2>$null
$method, $path = if ($existing) { 'PUT', "repos/$repo/rulesets/$existing" } else { 'POST', "repos/$repo/rulesets" }

$out = $rules | ConvertTo-Json -Depth 10 | gh api -X $method $path --input - 2>&1 | Out-String
if ($LASTEXITCODE -and $out -match 'copilot') {
    # Older API or no Copilot on this account. Save the rest of the ruleset, then print the clicks.
    $rules.rules = @($rules.rules | Where-Object type -ne 'copilot_code_review')
    $out = $rules | ConvertTo-Json -Depth 10 | gh api -X $method $path --input - 2>&1 | Out-String
    $clicks = @('Settings > Rules > Rulesets > Protect main.', 'Check "Automatically request Copilot code review".', 'Save changes.')
}
$PSNativeCommandUseErrorActionPreference = $true
if ($LASTEXITCODE) {
    Write-Fail 'The ruleset did not save. Private repos need GitHub Pro, Team, or Enterprise for rulesets.'
    Write-Host "        $($out.Trim())"
}
else { Write-Ok "Ruleset '$($rules.name)' is on" }

# --- 9. Summary ----------------------------------------------------------------
Write-Host ""
Write-Host "  You're ready. Repo: https://github.com/$repo" -ForegroundColor Green
if ($clicks) {
    Write-Watch 'One thing to click by hand:'
    Write-Clicks $clicks
}
Write-Host '  Next: pwsh ./03_DocsWikiMermaid/run.ps1, then pwsh ./04_TemplatesIssuesBoard/run.ps1'
