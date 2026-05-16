# PreToolUse hook for Bash. Blocks destructive commands unless /vii-careful was acknowledged this session.
# Reads tool input from stdin as JSON; exit 2 = block, exit 0 = allow.

$ErrorActionPreference = 'Stop'

try {
    $payload = [Console]::In.ReadToEnd() | ConvertFrom-Json
} catch {
    exit 0
}

$cmd = $payload.tool_input.command
if (-not $cmd) { exit 0 }

$dangerous = @(
    'rm\s+-rf\s+/',
    'rm\s+-rf\s+~',
    'rm\s+-rf\s+\$HOME',
    'git\s+reset\s+--hard',
    'git\s+push\s+.*--force',
    'git\s+push\s+.*-f(\s|$)',
    'git\s+clean\s+-[a-z]*f',
    'git\s+branch\s+-D',
    'DROP\s+TABLE',
    'DROP\s+DATABASE',
    'TRUNCATE\s+TABLE',
    'mkfs\.',
    'dd\s+if=.*of=/dev/',
    'shutdown\s',
    'reboot\s'
)

$hit = $null
foreach ($pat in $dangerous) {
    if ($cmd -match $pat) { $hit = $pat; break }
}

if (-not $hit) { exit 0 }

$sessionId = $payload.session_id
$cwd = $payload.cwd
if (-not $cwd) { $cwd = Get-Location }
$ack = Join-Path $cwd ".vii/careful-acked-$sessionId"

if (Test-Path $ack) { exit 0 }

$msg = @{
    decision = "block"
    reason   = "vii-stack: destructive command pattern '$hit' detected. Run /vii-careful to acknowledge for this session, or rephrase the command."
} | ConvertTo-Json -Compress

[Console]::Error.WriteLine($msg)
exit 2
