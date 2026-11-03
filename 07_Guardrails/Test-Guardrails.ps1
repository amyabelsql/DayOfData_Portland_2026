# Grades workflow files against the guardrails from the talk and prints a scorecard.
# Exits 1 if any file breaks any rule.
#   pwsh ./07_Guardrails/Test-Guardrails.ps1
#   pwsh ./07_Guardrails/Test-Guardrails.ps1 -Path ./07_Guardrails/examples/risky-workflow.yml
param([string]$Path = '.github/workflows')
. "$PSScriptRoot/../scripts/Common.ps1"

# Jobs are the 2-space-indented keys under "jobs:". Returns a name -> text map.
function Get-Jobs([string[]]$Lines) {
    $jobs = [ordered]@{}; $inJobs = $false; $current = $null
    foreach ($line in $Lines) {
        if ($line -match '^jobs:\s*$') { $inJobs = $true; continue }
        if ($inJobs -and $line -match '^\S') { $inJobs = $false }
        if (-not $inJobs) { continue }
        if ($line -match '^  ([A-Za-z0-9_-]+):\s*(#.*)?$') { $current = $Matches[1]; $jobs[$current] = ''; continue }
        if ($current) { $jobs[$current] += "$line`n" }
    }
    $jobs
}

$files = if (Test-Path $Path -PathType Container) { Get-ChildItem $Path -Include *.yml, *.yaml -Recurse } else { Get-Item $Path }

$rows = foreach ($f in $files) {
    $lines = Get-Content $f.FullName
    $text  = $lines -join "`n"

    # 1. Every action (not local ./ ones) is pinned to a 40-character commit SHA.
    $uses   = $lines | Where-Object { $_ -match '^\s*(-\s+)?uses:\s*([^\s#]+)' } | ForEach-Object { ($_ -replace '^\s*(-\s+)?uses:\s*', '' -split '\s')[0] }
    $pinned = -not ($uses | Where-Object { $_ -notmatch '^\./' -and $_ -notmatch '@[0-9a-f]{40}$' })

    # 2. There is a permissions: block.
    $perms = $text -match '(?m)^\s*permissions:'

    # 3. Every job has timeout-minutes. Jobs that call another workflow can't, so they're skipped.
    $jobs = Get-Jobs $lines
    $timeouts = $jobs.Count -gt 0 -and -not ($jobs.Keys | Where-Object {
        $jobs[$_] -notmatch '(?m)^    timeout-minutes:' -and $jobs[$_] -notmatch '(?m)^    uses:'
    })

    # 4. There is a concurrency group.
    $concurrency = $text -match '(?m)^\s*concurrency:'

    # 5. No plain-text passwords or keys. Values from ${{ }} or $VARIABLES are fine.
    $secretPattern = '(?im)^\s*[\w-]*(password|passwd|pwd|secret|token|api[_-]?key)[\w-]*\s*[:=]\s*["'']?(?![$"''\s])\S{4,}'
    $noSecrets = $text -notmatch $secretPattern

    [pscustomobject]@{
        File = $f.Name; Pinned = $pinned; Permissions = $perms; Timeouts = $timeouts
        Concurrency = $concurrency; NoSecrets = $noSecrets
    }
}

$rules = 'Pinned', 'Permissions', 'Timeouts', 'Concurrency', 'NoSecrets'
$width = [Math]::Max(30, ($rows.File | Measure-Object Length -Maximum).Maximum + 2)
Write-Host ""
Write-Host (('{0,-' + $width + '}') -f 'File') -NoNewline
$rules | ForEach-Object { Write-Host ('{0,-13}' -f $_) -NoNewline }
Write-Host ""
foreach ($r in $rows) {
    Write-Host (('{0,-' + $width + '}') -f $r.File) -NoNewline
    foreach ($rule in $rules) {
        if ($r.$rule) { Write-Host ('{0,-13}' -f 'PASS') -ForegroundColor Green -NoNewline }
        else          { Write-Host ('{0,-13}' -f 'FAIL') -ForegroundColor Red -NoNewline }
    }
    Write-Host ""
}

$bad = @($rows | Where-Object { $r = $_; $rules | Where-Object { -not $r.$_ } })
Write-Host ""
if ($bad.Count) { Write-Fail "$($bad.Count) of $(@($rows).Count) workflow file(s) break a guardrail"; exit 1 }
Write-Ok "All $(@($rows).Count) workflow file(s) follow every guardrail"
