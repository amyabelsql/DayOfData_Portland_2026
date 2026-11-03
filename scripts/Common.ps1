# Shared helpers so every step looks and behaves the same.
# Dot-source it at the top of a script:  . "$PSScriptRoot/../scripts/Common.ps1"

$ErrorActionPreference = 'Stop'
$PSNativeCommandUseErrorActionPreference = $true   # a failing gh/git/docker call stops the script

$RepoRoot      = Split-Path $PSScriptRoot -Parent
$SqlContainer  = 'demoshop-sql'
$script:PauseOn = $false

# Banner with the step number and the big idea. Also moves to the repo root.
function Start-Demo {
    param([string]$Number, [string]$Title, [string]$Idea, [switch]$Pause)
    Set-Location $RepoRoot
    $script:PauseOn = $Pause.IsPresent
    $line = '=' * 64
    Write-Host ""
    Write-Host $line -ForegroundColor Cyan
    Write-Host "  $Number  $Title" -ForegroundColor Cyan
    Write-Host "  The big idea: $Idea" -ForegroundColor White
    Write-Host $line -ForegroundColor Cyan
}

# One plain sentence before each action. [R] = read only, [W] = changes something.
function Write-Step {
    param([ValidateSet('R', 'W')][string]$Tag, [string]$Message)
    Write-Host ""
    $color = if ($Tag -eq 'W') { 'Magenta' } else { 'Cyan' }
    Write-Host "[$Tag] " -ForegroundColor $color -NoNewline
    Write-Host $Message
    if ($script:PauseOn) { [void](Read-Host '      Press Enter to continue') }
}

function Write-Ok    { param([string]$Message) Write-Host "  OK    $Message" -ForegroundColor Green }
function Write-Watch { param([string]$Message) Write-Host "  WATCH $Message" -ForegroundColor Yellow }
function Write-Fail  { param([string]$Message) Write-Host "  FAIL  $Message" -ForegroundColor Red }

# Opens a page in the browser. Set DEMO_NO_BROWSER=1 to print the URL instead (handy when testing).
function Open-Page {
    param([string]$Url)
    if ($env:DEMO_NO_BROWSER) { Write-Host "  PAGE  $Url" } else { Start-Process $Url }
}

# Prints manual clicks as a numbered list.
function Write-Clicks {
    param([string[]]$Steps)
    $i = 1
    foreach ($s in $Steps) { Write-Host "    $i. $s" -ForegroundColor Yellow; $i++ }
}

# Owner/name of the repo that origin points to, like "amyabelsql/DayOfData_Portland_2026".
function Get-Repo {
    gh repo view --json nameWithOwner --jq .nameWithOwner
}

# Makes .env with a random strong password if it doesn't exist yet.
function Initialize-DotEnv {
    $envFile = Join-Path $RepoRoot '.env'
    if (Test-Path $envFile) { return $false }
    $chars = [char[]]'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789'
    $random = -join (1..20 | ForEach-Object { $chars | Get-Random })
    "MSSQL_SA_PASSWORD=Db1!$random" | Set-Content $envFile
    return $true
}

# Loads .env into environment variables. sqlcmd reads the password from SQLCMDPASSWORD.
function Import-DotEnv {
    $envFile = Join-Path $RepoRoot '.env'
    if (Test-Path $envFile) {
        foreach ($line in Get-Content $envFile) {
            if ($line -match '^\s*([A-Za-z_][A-Za-z0-9_]*)\s*=\s*(.*)$') {
                [Environment]::SetEnvironmentVariable($Matches[1], $Matches[2])
            }
        }
    }
    if (-not $env:SQLCMDPASSWORD) { $env:SQLCMDPASSWORD = $env:MSSQL_SA_PASSWORD }
    if (-not $env:SQLCMDPASSWORD) { throw 'No SQL password found. Run ./00_Prerequisites/run.ps1 or copy .env.example to .env.' }
}

# Runs a SQL file or query. Uses sqlcmd on this machine if it's installed,
# otherwise the sqlcmd that ships inside the SQL Server container.
# Returns the exit code and output instead of throwing, so tests can report PASS or FAIL.
function Invoke-DemoSql {
    param([string]$File, [string]$Query, [string]$Database = 'master')
    $PSNativeCommandUseErrorActionPreference = $false
    $server = $env:SQL_SERVER ?? 'localhost,1433'
    $sqlArgs = @('-U', 'sa', '-d', $Database, '-C', '-b')

    if (Get-Command sqlcmd -ErrorAction SilentlyContinue) {
        $output = if ($File) { sqlcmd -S $server @sqlArgs -i $File 2>&1 }
                  else       { sqlcmd -S $server @sqlArgs -Q $Query 2>&1 }
    }
    else {
        $exec = @('exec', '-i', '-e', 'SQLCMDPASSWORD', $SqlContainer, '/opt/mssql-tools18/bin/sqlcmd', '-S', 'localhost') + $sqlArgs
        $output = if ($File) { Get-Content $File -Raw | docker @exec 2>&1 }
                  else       { docker @exec -Q $Query 2>&1 }
    }
    [pscustomobject]@{ ExitCode = $LASTEXITCODE; Output = ($output | Out-String).Trim() }
}

# Starts a fresh branch from origin/main. Stops if there are uncommitted changes.
function New-DemoBranch {
    param([string]$Name)
    if (git status --porcelain --untracked-files=no) {
        throw 'You have uncommitted changes. Commit or stash them first, then run this again.'
    }
    git fetch origin --quiet
    git switch -C $Name origin/main --quiet
}

# Commits everything staged or changed, if there is anything to commit.
function Save-DemoCommit {
    param([string]$Message)
    git add -A
    if (git status --porcelain) { git commit -m $Message --quiet; return $true }
    return $false
}

# Number of the open pull request for a branch, or $null.
function Get-OpenPr {
    param([string]$Branch)
    $n = gh pr list --head $Branch --state open --json number --jq '.[0].number'
    if ($n) { [int]$n } else { $null }
}

# Waits for checks to show up on a pull request, then watches them.
# Returns $true when they all pass.
function Watch-PrChecks {
    param([int]$Number)
    $PSNativeCommandUseErrorActionPreference = $false
    foreach ($i in 1..30) {
        $out = gh pr checks $Number 2>&1 | Out-String
        if ($out -notmatch 'no checks reported') { break }
        Start-Sleep -Seconds 4
    }
    gh pr checks $Number --watch --interval 5
    return ($LASTEXITCODE -eq 0)
}

# Starts a workflow_dispatch workflow, waits for the new run to appear, and returns its id.
function Start-Workflow {
    param([string]$Workflow, [string[]]$Fields = @())
    $before = gh run list --workflow $Workflow --limit 1 --json databaseId --jq '.[0].databaseId'
    $fieldArgs = $Fields | ForEach-Object { '-f', $_ }
    gh workflow run $Workflow @fieldArgs | Out-Null
    foreach ($i in 1..30) {
        Start-Sleep -Seconds 2
        $id = gh run list --workflow $Workflow --limit 1 --json databaseId --jq '.[0].databaseId'
        if ($id -and $id -ne $before) { return $id }
    }
    throw "The run for $Workflow didn't show up. Check the Actions tab."
}
