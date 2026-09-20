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

# Strip everything that is data rather than command, so prose that merely
# mentions a destructive command can't trigger a block. Order matters:
# heredoc bodies first, because they span lines and may contain loose quotes
# that would otherwise desynchronise the quoted-string stripping below.

# 1. Heredoc bodies: `cmd <<'EOF' ... EOF`. Keep the rest of the introducing
#    line (it may chain another command), drop body and terminator. Writing a
#    file whose text documents `git reset --hard` is not running it.
$cmdToCheck = $cmd
$heredoc = "(?ms)<<-?\s*(['`"]?)(\w+)\1([^\r\n]*)\r?\n(?:.*?\r?\n)?[ \t]*\2[ \t]*(?=\r?\n|$)"
for ($i = 0; $i -lt 10; $i++) {
    $stripped = [regex]::Replace($cmdToCheck, $heredoc, '<<HEREDOC$3')
    if ($stripped -eq $cmdToCheck) { break }
    $cmdToCheck = $stripped
}

# 2. Truncate at free-text argument flags so content passed to --body/-m/etc.
#    can't trigger false positives, then strip remaining quoted strings.
$cmdToCheck = $cmdToCheck -replace '\s+(-m|--message|--body|--body-file|-F|--trailer)\s+[\s\S]*$', ''
$cmdToCheck = $cmdToCheck -replace '"[^"]*"', '""' -replace "'[^']*'", "''"

$hit = $null
foreach ($pat in $dangerous) {
    if ($cmdToCheck -match $pat) { $hit = $pat; break }
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
