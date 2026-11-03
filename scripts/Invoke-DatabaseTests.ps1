# Runs every test in database/tests. Prints PASS or FAIL and exits 1 on any failure.
# In GitHub Actions it also writes a results table to the job summary.
. "$PSScriptRoot/Common.ps1"
Import-DotEnv

$results = foreach ($t in Get-ChildItem "$RepoRoot/database/tests/*.sql" | Sort-Object Name) {
    $r = Invoke-DemoSql -File $t.FullName -Database 'DemoShop'
    if ($r.ExitCode -eq 0) {
        Write-Host "  PASS  $($t.BaseName)" -ForegroundColor Green
        [pscustomobject]@{ Test = $t.BaseName; Result = 'PASS'; Message = '' }
    }
    else {
        # THROW messages start with FAIL:, so pull that line out for a clean message.
        $msg = ($r.Output -split "`n" | Where-Object { $_ -match 'FAIL:' } | Select-Object -First 1) ?? $r.Output
        Write-Host "  FAIL  $($t.BaseName)" -ForegroundColor Red
        Write-Host "        $($msg.Trim())" -ForegroundColor Red
        [pscustomobject]@{ Test = $t.BaseName; Result = 'FAIL'; Message = $msg.Trim() }
    }
}

if ($env:GITHUB_STEP_SUMMARY) {
    $lines = @('## Database tests', '', '| Test | Result | Message |', '|---|---|---|')
    $lines += $results | ForEach-Object {
        $icon = if ($_.Result -eq 'PASS') { ':white_check_mark: PASS' } else { ':x: FAIL' }
        "| $($_.Test) | $icon | $($_.Message) |"
    }
    $lines | Add-Content $env:GITHUB_STEP_SUMMARY
}

$failed = @($results | Where-Object Result -eq 'FAIL').Count
if ($failed) { Write-Fail "$failed test(s) failed"; exit 1 }
Write-Ok "All $(@($results).Count) tests passed"
