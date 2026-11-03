# Step 03. Docs and diagrams are text, so they get versioned like code.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '03' 'Docs and diagrams in a wiki' 'docs and diagrams are text' -Pause:$Pause

$repo = Get-Repo
$temp = Join-Path ([IO.Path]::GetTempPath()) "wiki-$([guid]::NewGuid().ToString('N').Substring(0, 8))"

Write-Step R 'Clone the wiki. A GitHub wiki is just another Git repo.'
$PSNativeCommandUseErrorActionPreference = $false
while ($true) {
    git clone --quiet "https://github.com/$repo.wiki.git" $temp 2>$null
    if ($LASTEXITCODE -eq 0) { break }
    Write-Watch "The wiki isn't set up yet. GitHub needs one page made by hand first."
    Write-Clicks @('Click "Create the first page".', 'Click "Save page". Leave the text as it is.')
    Open-Page "https://github.com/$repo/wiki"
    [void](Read-Host '      Press Enter when the first page is saved')
}
$PSNativeCommandUseErrorActionPreference = $true

Write-Step W 'Make the wiki match 03_DocsWikiMermaid/wiki exactly, then commit and push.'
Get-ChildItem $temp -Filter *.md | Remove-Item   # pages not in the folder go away. Wiki history keeps them.
Copy-Item "$PSScriptRoot/wiki/*.md" $temp -Force
Push-Location $temp
try {
    git add -A
    if (git status --porcelain) {
        git commit --quiet -m 'Publish wiki from 03_DocsWikiMermaid'
        git push --quiet origin HEAD
        Write-Ok "Published $((Get-ChildItem *.md).Count) pages"
    }
    else { Write-Ok 'The wiki already matches. Nothing to push.' }
}
finally { Pop-Location; Remove-Item $temp -Recurse -Force }

Write-Step R 'Open the wiki. Every page has a diagram GitHub draws from text.'
Open-Page "https://github.com/$repo/wiki"
