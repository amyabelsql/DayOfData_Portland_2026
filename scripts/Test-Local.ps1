# Runs every check that doesn't touch GitHub, as many times as you like.
#   pwsh ./scripts/Test-Local.ps1
#   pwsh ./scripts/Test-Local.ps1 -Rounds 5
# Needs Docker running. Exits 1 if any check fails in any round.
param([int]$Rounds = 1)
. "$PSScriptRoot/Common.ps1"
Set-Location $RepoRoot
$PSNativeCommandUseErrorActionPreference = $false

$results = [System.Collections.Generic.List[object]]::new()
$proc = 'database/procs/usp_GetActiveOrders.sql'

# Runs one check. The block returns $true for pass. On failure, $script:Log is printed.
function Test-It([string]$Name, [scriptblock]$Check) {
    $script:Log = ''
    $sw = [Diagnostics.Stopwatch]::StartNew()
    $ok = try { [bool](& $Check) } catch { $script:Log += $_.Exception.Message; $false }
    $secs = [Math]::Round($sw.Elapsed.TotalSeconds)
    if ($ok) { Write-Host "  PASS  $Name ($secs s)" -ForegroundColor Green }
    else {
        Write-Host "  FAIL  $Name ($secs s)" -ForegroundColor Red
        $script:Log -split "`n" | Select-Object -Last 15 | ForEach-Object { Write-Host "        $_" }
    }
    $results.Add([pscustomobject]@{ Round = $round; Check = $Name; Result = $(if ($ok) { 'PASS' } else { 'FAIL' }) })
}

# Runs a script in a fresh pwsh and keeps its output for the log.
function Invoke-Child([string]$File, [string[]]$ArgList = @()) {
    $script:Log = pwsh -NoProfile -File $File @ArgList 2>&1 | Out-String
    $LASTEXITCODE
}

foreach ($round in 1..$Rounds) {
    Write-Host ""
    Write-Host "=== Round $round of $Rounds ===" -ForegroundColor Cyan

    Test-It 'Every PowerShell script parses' {
        $bad = Get-ChildItem -Recurse -Filter *.ps1 | Where-Object {
            $e = $null
            [void][Management.Automation.Language.Parser]::ParseFile($_.FullName, [ref]$null, [ref]$e)
            $e
        }
        $script:Log = $bad.Name -join "`n"
        -not $bad
    }

    Test-It 'Real workflows pass every guardrail' { (Invoke-Child 07_Guardrails/Test-Guardrails.ps1) -eq 0 }

    Test-It 'Risky workflow fails all 5 guardrails' {
        $code = Invoke-Child 07_Guardrails/Test-Guardrails.ps1 @('-Path', '07_Guardrails/examples/risky-workflow.yml')
        $code -eq 1 -and ([regex]::Matches($script:Log, 'FAIL').Count -ge 5)
    }

    Test-It 'actionlint finds no workflow problems' {
        $script:Log = docker run --rm -v "${RepoRoot}:/repo" -w /repo rhysd/actionlint:1.7.7 -no-color 2>&1 | Out-String
        $LASTEXITCODE -eq 0
    }

    Test-It 'No em dashes in any file' {
        $files = git ls-files -co --exclude-standard | Where-Object { $_ -ne 'BUILD_SPEC.md' -and (Test-Path $_) }
        $hits = Select-String -LiteralPath $files -Pattern ([string][char]0x2014) -SimpleMatch
        $script:Log = $hits -join "`n"
        -not $hits
    }

    Test-It 'The .env password is in no file git would commit' {
        if (Test-Path .env) { Import-DotEnv }
        if (-not $env:MSSQL_SA_PASSWORD) { return $true }
        $files = git ls-files -co --exclude-standard | Where-Object { Test-Path $_ }
        $hits = Select-String -LiteralPath $files -Pattern $env:MSSQL_SA_PASSWORD -SimpleMatch
        $script:Log = $hits -join "`n"
        (git check-ignore .env) -and -not $hits
    }

    Test-It 'Step 05 passes from a clean start' {
        docker compose down *> $null
        (Invoke-Child 05_Containers/run.ps1) -eq 0
    }

    Test-It 'Step 05 passes again (safe to run twice)' { (Invoke-Child 05_Containers/run.ps1) -eq 0 }

    Test-It 'Broken proc fails with a clear message' {
        $original = Get-Content $proc -Raw
        try {
            (Get-Content $proc) | Where-Object { $_ -notmatch "WHERE .*Status = 'Active'" } | Set-Content $proc
            [void](Invoke-Child scripts/Deploy-Database.ps1)
            $code = Invoke-Child scripts/Invoke-DatabaseTests.ps1
            $code -eq 1 -and $script:Log -match 'Is the WHERE clause missing'
        }
        finally {
            Set-Content $proc $original -NoNewline
            [void](pwsh -NoProfile -File scripts/Deploy-Database.ps1 2>&1)
        }
    }

    Test-It 'Step 06 proc and step 00 seed index deploy and pass' {
        $copies = @{
            '06_CopilotAndPRs/new-proc/usp_GetCustomerOrderCount.sql'          = 'database/procs/usp_GetCustomerOrderCount.sql'
            '06_CopilotAndPRs/new-proc/test-customer-order-count.sql'          = 'database/tests/test-customer-order-count.sql'
            '06_CopilotAndPRs/new-proc/rollback-usp_GetCustomerOrderCount.sql' = 'database/rollback/usp_GetCustomerOrderCount.sql'
            '00_Prerequisites/seed/03-orders-orderdate-index.sql'              = 'database/schema/03-orders-orderdate-index.sql'
        }
        try {
            foreach ($src in $copies.Keys) { Copy-Item $src $copies[$src] }
            (Invoke-Child scripts/Deploy-Database.ps1) -eq 0 -and
            (Invoke-Child scripts/Invoke-DatabaseTests.ps1) -eq 0 -and
            $script:Log -match 'PASS  test-customer-order-count'
        }
        finally { $copies.Values | ForEach-Object { Remove-Item $_ -ErrorAction SilentlyContinue } }
    }
}

$failed = @($results | Where-Object Result -eq 'FAIL')
Write-Host ""
if ($failed.Count) {
    Write-Fail "$($failed.Count) of $($results.Count) checks failed across $Rounds round(s)"
    $failed | Format-Table Round, Check -AutoSize | Out-String | Write-Host
    exit 1
}
Write-Ok "All $($results.Count) checks passed across $Rounds round(s)"
