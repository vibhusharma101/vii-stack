# PreToolUse hook for Edit/Write/NotebookEdit. Enforces /vii-freeze directory lock.
# Reads tool input from stdin as JSON; exit 2 = block, exit 0 = allow.

$ErrorActionPreference = 'Stop'

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$cwd = $payload.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }
$freezeFile = Join-Path $cwd ".vii/freeze"

if (-not (Test-Path $freezeFile)) { exit 0 }

$lockedDir = (Get-Content $freezeFile -Raw).Trim()
if (-not $lockedDir) { exit 0 }

$target = $payload.tool_input.file_path
if (-not $target) { $target = $payload.tool_input.notebook_path }
if (-not $target) { exit 0 }

# Normalize both paths for comparison.
try {
    $resolvedTarget = [System.IO.Path]::GetFullPath($target)
    $resolvedLock   = [System.IO.Path]::GetFullPath($lockedDir)
} catch {
    exit 0
}

if ($resolvedTarget.StartsWith($resolvedLock, [System.StringComparison]::OrdinalIgnoreCase)) {
    exit 0
}

$msg = @{
    decision = "block"
    reason   = "vii-stack: edits frozen to '$resolvedLock'. Target '$resolvedTarget' is outside the lock. Run /vii-unfreeze to release, or /vii-freeze <new-dir> to relock."
} | ConvertTo-Json -Compress

[Console]::Error.WriteLine($msg)
exit 2
