# install.ps1 — install this repo as an Agent Skill on Windows.
# Auto-detects Cursor / Claude Code / Codex CLI skills directories and
# installs into each that exists on the machine. Prefers symlink so
# `git pull` updates every install; falls back to copy on failure.
#
# Usage:
#   .\install.ps1                # auto-detect and install into all found platforms
#   .\install.ps1 -Target cursor # install into a specific platform only
#   .\install.ps1 -All           # install into all three (create missing dirs)

param(
    [string]$Target = "",
    [switch]$All
)

$ErrorActionPreference = "Stop"

$sourceDir = Split-Path -Parent $MyInvocation.MyCommand.Path
$skillName = "bigquery"

$platforms = @{
    "cursor"      = "$env:USERPROFILE\.cursor\skills"
    "claude"      = "$env:USERPROFILE\.claude\skills"
    "codex"       = "$env:USERPROFILE\.codex\skills"
}

# Decide which platforms to install into
$selected = @()
if ($Target) {
    if (-not $platforms.ContainsKey($Target)) {
        Write-Error "Unknown -Target '$Target'. Valid: cursor, claude, codex."
        exit 1
    }
    $selected += $Target
} elseif ($All) {
    $selected = $platforms.Keys
} else {
    foreach ($k in $platforms.Keys) {
        if (Test-Path $platforms[$k]) { $selected += $k }
    }
    if (-not $selected) {
        Write-Warning "No known agent skills directories found. Falling back to -All."
        $selected = $platforms.Keys
    }
}

Write-Host "Installing skill '$skillName' from: $sourceDir"
Write-Host "Targets: $($selected -join ', ')"
Write-Host ""

foreach ($p in $selected) {
    $baseDir   = $platforms[$p]
    $targetDir = Join-Path $baseDir $skillName

    if (-not (Test-Path $baseDir)) {
        New-Item -ItemType Directory -Path $baseDir -Force | Out-Null
    }

    if (Test-Path $targetDir) {
        Write-Warning "[$p] Target already exists: $targetDir"
        $ans = Read-Host "        Overwrite? (y/N)"
        if ($ans -ne "y") { Write-Host "[$p] Skipped."; continue }
        Remove-Item -Recurse -Force $targetDir
    }

    try {
        New-Item -ItemType SymbolicLink -Path $targetDir -Target $sourceDir | Out-Null
        Write-Host "[$p] Symlinked -> $targetDir"
    }
    catch {
        Write-Warning "[$p] Symlink failed (needs Developer Mode or admin). Copying instead."
        Copy-Item -Recurse -Force $sourceDir $targetDir
        Write-Host "[$p] Copied -> $targetDir"
    }
}

Write-Host ""
Write-Host "Done. Restart your agent (or reload the workspace) to pick up the skill."
