# SessionStart hook. Prints vii-stack status into the session.

$ErrorActionPreference = 'SilentlyContinue'

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $cwd = $payload.cwd
} catch {}
if (-not $cwd) { $cwd = (Get-Location).Path }

$lines = @()
$lines += "vii-stack active"

$freezeFile = Join-Path $cwd ".vii/freeze"
if (Test-Path $freezeFile) {
    $locked = (Get-Content $freezeFile -Raw).Trim()
    $lines += "  freeze: edits locked to $locked (run /vii-unfreeze to release)"
} else {
    $lines += "  freeze: off"
}

$planFile = Join-Path $cwd ".vii/plan.md"
if (Test-Path $planFile) {
    $lines += "  plan: .vii/plan.md present"
}

$retroDir = Join-Path $cwd ".vii/retro"
if (Test-Path $retroDir) {
    $latest = Get-ChildItem $retroDir -Filter *.md | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if ($latest) { $lines += "  last retro: $($latest.Name)" }
}

$out = @{
    hookSpecificOutput = @{
        hookEventName     = "SessionStart"
        additionalContext = ($lines -join "`n")
    }
} | ConvertTo-Json -Depth 5 -Compress

Write-Output $out
exit 0
