# Step 01. A workflow is just a file.
param([switch]$Pause)
. "$PSScriptRoot/../scripts/Common.ps1"
Start-Demo '01' 'How a workflow works' 'a workflow is just a file' -Pause:$Pause

$file = '.github/workflows/01-hello-workflow.yml'
Write-Step R 'Show the workflow file. Point at the trigger (on), the job, and the steps.'
$n = 1
Get-Content $file | ForEach-Object { Write-Host ('{0,3}  {1}' -f $n++, $_) }

Write-Step W 'Start the workflow. GitHub spins up a fresh machine just for this.'
$run = Start-Workflow '01-hello-workflow.yml'

Write-Step R 'Follow the run live.'
gh run watch $run --exit-status
Write-Ok 'Done. A file, a trigger, a machine, a result.'

Write-Step R 'Open the run in the browser to show the job summary.'
gh run view $run --web
