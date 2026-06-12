# PreToolUse hook for Bash. When "cheap mode" is on (.vii/cheap-mode sentinel)
# and the `rtk` binary is installed, rewrites safe read-heavy commands to their
# `rtk <cmd>` equivalents so RTK compresses the output before it reaches the
# model's context window. Reduces token consumption 50-90% on those commands.
#
# Reads tool input from stdin as JSON. Emits hookSpecificOutput.updatedInput to
# rewrite the command. Exit 0 always (this hook never blocks).
#
# Safety: only a conservative allowlist of read-only / diagnostic commands is
# wrapped. Write operations (git commit/push, rm, etc.) are never touched.
# Pipelines, redirects, and command chains are skipped to avoid mangling.

$ErrorActionPreference = 'SilentlyContinue'

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$cmd = $payload.tool_input.command
if (-not $cmd) { exit 0 }

# Resolve the project directory and check the cheap-mode sentinel.
$cwd = $payload.cwd
if (-not $cwd) { $cwd = (Get-Location).Path }
$sentinel = Join-Path $cwd ".vii/cheap-mode"
if (-not (Test-Path $sentinel)) { exit 0 }

# rtk must be installed, otherwise this is a silent no-op.
if (-not (Get-Command rtk -ErrorAction SilentlyContinue)) { exit 0 }

$trimmed = $cmd.TrimStart()

# Never touch anything already routed through rtk (e.g. rtk's own global hook).
if ($trimmed -match '^rtk(\s|$)') { exit 0 }

# Skip pipelines, redirects, chains, substitutions - wrapping these is unsafe.
if ($cmd -match '[|<>;`]' -or $cmd -match '&&' -or $cmd -match '\$\(') { exit 0 }

# Conservative allowlist of read-only / diagnostic commands RTK is known to
# support. Two-word prefixes are matched before single-word leads. Write-side
# git verbs (commit/push/add/pull) are deliberately excluded.
$allow = @(
    '^git\s+(status|log|diff|show)\b',
    '^cargo\s+(test|build|clippy|check)\b',
    '^go\s+test\b',
    '^pnpm\s+list\b',
    '^pip\s+list\b',
    '^docker\s+ps\b',
    '^golangci-lint\s+run\b',
    '^(ls|grep|find|tsc|eslint|prettier|pytest|jest|vitest|ruff|rubocop|rspec)\b'
)

$match = $false
foreach ($pat in $allow) {
    if ($trimmed -match $pat) { $match = $true; break }
}
if (-not $match) { exit 0 }

# Ultra-compact mode: if the sentinel contains the word "ultra", add -u for
# even tighter output.
$prefix = 'rtk '
try {
    $body = (Get-Content $sentinel -Raw -ErrorAction SilentlyContinue)
    if ($body -and $body -match 'ultra') { $prefix = 'rtk -u ' }
} catch {}

$new = $prefix + $trimmed

$out = @{
    hookSpecificOutput = @{
        hookEventName     = "PreToolUse"
        permissionDecision = "allow"
        updatedInput      = @{
            command = $new
        }
    }
} | ConvertTo-Json -Depth 6 -Compress

Write-Output $out
exit 0
