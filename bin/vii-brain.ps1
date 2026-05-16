# vii-brain CLI shim.
# Locates Node and delegates to vii-brain/vii-brain.mjs.
# Usage: vii-brain <init|add|search|list|remove> [args]

$ErrorActionPreference = 'Stop'

$Root    = Split-Path $PSScriptRoot -Parent
$Script  = Join-Path $Root "vii-brain/vii-brain.mjs"

$NodeCmd = Get-Command node -ErrorAction SilentlyContinue
if (-not $NodeCmd) {
    Write-Error "vii-brain: 'node' not found on PATH. Install Node.js 18+ to use vii-brain."
    exit 1
}

$NodeModules = Join-Path $Root "vii-brain/node_modules"
if (-not (Test-Path $NodeModules)) {
    Write-Host "vii-brain: first run — installing dependencies (npm install)..." -ForegroundColor Cyan
    $NpmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $NpmCmd) { Write-Error "vii-brain: 'npm' not found. Install Node.js 18+."; exit 1 }
    Push-Location (Join-Path $Root "vii-brain")
    try { & npm install --silent } finally { Pop-Location }
}

& node $Script @args
exit $LASTEXITCODE
