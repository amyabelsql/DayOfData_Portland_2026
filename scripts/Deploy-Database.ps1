# Deploys DemoShop in order: create database, schema, procs, seed.
# Stops on the first error (sqlcmd -b).
. "$PSScriptRoot/Common.ps1"
Import-DotEnv

$db = Join-Path $RepoRoot 'database'
$files = @(Get-Item "$db/00-create-database.sql")
foreach ($folder in 'schema', 'procs', 'seed') {
    $files += Get-ChildItem "$db/$folder/*.sql" | Sort-Object Name
}

foreach ($f in $files) {
    $target = if ($f.Name -eq '00-create-database.sql') { 'master' } else { 'DemoShop' }
    $result = Invoke-DemoSql -File $f.FullName -Database $target
    $name = [IO.Path]::GetRelativePath($RepoRoot, $f.FullName)
    if ($result.ExitCode -ne 0) {
        Write-Fail $name
        Write-Host $result.Output
        exit 1
    }
    Write-Ok "Deployed $name"
}
