# install.ps1 — install this repo as a personal Cursor skill on Windows.
# Run from anywhere inside the cloned repo. Requires PowerShell 5+.

$ErrorActionPreference = "Stop"

$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$targetDir = Join-Path $env:USERPROFILE ".cursor\skills\bigquery"

if (Test-Path $targetDir) {
    Write-Warning "Target already exists: $targetDir"
    $ans = Read-Host "Overwrite? (y/N)"
    if ($ans -ne "y") { Write-Host "Aborted."; exit 1 }
    Remove-Item -Recurse -Force $targetDir
}

# Prefer symlink so `git pull` in the repo updates the installed skill.
try {
    New-Item -ItemType SymbolicLink -Path $targetDir -Target $sourceDir | Out-Null
    Write-Host "Symlinked $targetDir -> $sourceDir"
}
catch {
    Write-Warning "Symlink failed (needs Developer Mode or admin). Copying instead."
    Copy-Item -Recurse -Force $sourceDir $targetDir
    Write-Host "Copied to $targetDir"
}

Write-Host ""
Write-Host "Done. Restart Cursor (or reload the workspace) to pick up the skill."
