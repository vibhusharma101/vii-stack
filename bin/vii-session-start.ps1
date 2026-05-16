# SessionStart hook. Prints vii-stack status into the session and records the
# current session id so /vii-careful can create the right ack file.

$ErrorActionPreference = 'SilentlyContinue'

$payload = $null
try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
    $cwd = $payload.cwd
} catch {}
if (-not $cwd) { $cwd = (Get-Location).Path }

# Record the session id for /vii-careful. Also sweep any stale ack files from
# prior sessions so careful state is genuinely per-session.
if ($payload -and $payload.session_id) {
    $viiDir = Join-Path $cwd ".vii"
    if (-not (Test-Path $viiDir)) { New-Item -ItemType Directory -Path $viiDir | Out-Null }
    Set-Content -Path (Join-Path $viiDir ".current-session") -Value $payload.session_id -Encoding utf8 -NoNewline
    Get-ChildItem -Path $viiDir -Filter "careful-acked-*" -ErrorAction SilentlyContinue |
        Where-Object { $_.Name -ne "careful-acked-$($payload.session_id)" } |
        Remove-Item -Force -ErrorAction SilentlyContinue
}

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
