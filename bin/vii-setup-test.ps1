# End-to-end test for setup.ps1's settings.json merge.
#
# The merge rewrites a file setup.ps1 did not create, so the failure mode is
# data loss: an unparsed settings.json used to fall back to an empty hashtable
# and take the user's other settings with it. These cases pin that shut.
#
#   .\bin\vii-setup-test.ps1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root  = Split-Path -Parent $PSScriptRoot
$Setup = Join-Path $Root "setup.ps1"
$PsExe = (Get-Process -Id $PID).Path

$failed = 0
function Check($name, $condition, $detail) {
    if ($condition) {
        Write-Host "    ok    $name" -ForegroundColor DarkGray
    } else {
        $script:failed++
        Write-Host "    FAIL  $name" -ForegroundColor Red
        if ($detail) { Write-Host "          $detail" -ForegroundColor DarkGray }
    }
}

function New-FakeHome {
    $h = Join-Path ([System.IO.Path]::GetTempPath()) ("vii-setup-test-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path (Join-Path $h ".claude") -Force | Out-Null
    return $h
}

# setup.ps1 reads $HOME, which is read-only inside a session but derives from
# USERPROFILE at startup - so drive it through a child process.
function Invoke-Setup($fakeHome) {
    $prev = $env:USERPROFILE
    try {
        $env:USERPROFILE = $fakeHome
        $out = & $PsExe -NoProfile -ExecutionPolicy Bypass -File $Setup 2>&1 | Out-String
        return @{ out = $out; code = $LASTEXITCODE }
    } finally {
        $env:USERPROFILE = $prev
    }
}

Write-Host "==> Testing setup.ps1 settings.json merge" -ForegroundColor Cyan
$ErrorActionPreference = 'Continue'

# --- Case 1: an existing settings.json keeps its unrelated content ---------
$h1 = New-FakeHome
$settings1 = Join-Path $h1 ".claude/settings.json"
@{
    model       = "claude-opus-5"
    theme       = "dark"
    permissions = @{ allow = @("Bash(git status)", "Bash(ls)") }
    env         = @{ MY_TOKEN = "keep-me" }
} | ConvertTo-Json -Depth 10 | Set-Content -Path $settings1 -Encoding utf8

$r1 = Invoke-Setup $h1
$after1 = Get-Content -Raw -Path $settings1 | ConvertFrom-Json

Check "pre-existing 'model' survives"        ($after1.model -eq "claude-opus-5")   "got: $($after1.model)"
Check "pre-existing 'theme' survives"        ($after1.theme -eq "dark")            "got: $($after1.theme)"
Check "nested permissions.allow survives"    ($after1.permissions.allow.Count -eq 2) "got: $($after1.permissions.allow -join ',')"
Check "nested env value survives"            ($after1.env.MY_TOKEN -eq "keep-me")  "got: $($after1.env.MY_TOKEN)"
Check "vii-stack hooks were added"           ($null -ne $after1.hooks)             "hooks key missing"
Check "a backup was written"                 (@(Get-ChildItem (Join-Path $h1 ".claude") -Filter "settings.json.vii-backup-*").Count -ge 1) "no backup file"

# --- Case 2: re-running is idempotent, not additive ------------------------
$before2 = ($after1.hooks.PreToolUse | Measure-Object).Count
Invoke-Setup $h1 | Out-Null
$after2 = Get-Content -Raw -Path $settings1 | ConvertFrom-Json
$now2 = ($after2.hooks.PreToolUse | Measure-Object).Count
Check "re-run does not duplicate hooks"      ($now2 -eq $before2) "PreToolUse went $before2 -> $now2"
Check "re-run still keeps user settings"     ($after2.model -eq "claude-opus-5") "got: $($after2.model)"

# --- Case 2b: a pre-existing third-party hook is kept, but ranked after ----
# Reproduces the real failure: `rtk hook claude` registered ahead of
# vii-careful-check returns hookSpecificOutput for git commands, which ends the
# PreToolUse chain before the safety hook is ever consulted.
$h2 = New-FakeHome
$settings2b = Join-Path $h2 ".claude/settings.json"
@{
    hooks = @{
        PreToolUse = @(
            @{ matcher = "Bash"; hooks = @(@{ type = "command"; command = "rtk hook claude" }) }
        )
    }
} | ConvertTo-Json -Depth 10 | Set-Content -Path $settings2b -Encoding utf8

Invoke-Setup $h2 | Out-Null
$after2b = Get-Content -Raw -Path $settings2b | ConvertFrom-Json
$pre = @($after2b.hooks.PreToolUse)
$firstCmds = @($pre[0].hooks | ForEach-Object { $_.command })
$allCmds   = @($pre | ForEach-Object { $_.hooks } | ForEach-Object { $_.command })

Check "third-party hook is preserved" (@($allCmds | Where-Object { $_ -eq "rtk hook claude" }).Count -eq 1) "got: $($allCmds -join ' | ')"
Check "vii-careful-check runs first"  ($firstCmds -join ' ' -match 'vii-careful-check') "first group: $($firstCmds -join ' | ')"

$carefulIdx = [array]::FindIndex([string[]]$allCmds, [Predicate[string]]{ param($c) $c -match 'vii-careful-check' })
$rtkIdx     = [array]::FindIndex([string[]]$allCmds, [Predicate[string]]{ param($c) $c -eq 'rtk hook claude' })
Check "safety hook ranks above rtk"   ($carefulIdx -ge 0 -and $rtkIdx -ge 0 -and $carefulIdx -lt $rtkIdx) "careful=$carefulIdx rtk=$rtkIdx"

# --- Case 2c: single-element arrays survive the round-trip -----------------
# A third-party matcher with exactly one hook is shaped [{...}]. PowerShell
# unwraps a one-element array on return, so a naive deep-convert rewrites it as
# {...} - which Claude Code refuses to load, taking the whole entry with it.
# This is what happened to `rtk hook claude` in the wild.
$h5 = New-FakeHome
$settings5 = Join-Path $h5 ".claude/settings.json"
@{
    hooks = @{
        PreToolUse = @(
            @{ matcher = "Bash"; hooks = @(@{ type = "command"; command = "rtk hook claude" }) }
        )
    }
    permissions = @{ allow = @("Bash(ls)") }
} | ConvertTo-Json -Depth 10 | Set-Content -Path $settings5 -Encoding utf8

Invoke-Setup $h5 | Out-Null
$raw5 = Get-Content -Raw -Path $settings5
$after5 = $raw5 | ConvertFrom-Json
$rtkEntry = @($after5.hooks.PreToolUse) | Where-Object {
    $_.hooks -and (@($_.hooks) | Where-Object { $_.command -eq 'rtk hook claude' })
} | Select-Object -First 1

Check "one-hook matcher stays an array" ($null -ne $rtkEntry -and $rtkEntry.hooks -is [array]) "hooks is $(if ($rtkEntry) { $rtkEntry.hooks.GetType().Name } else { 'entry missing' })"
Check "one-item allow list stays an array" ($after5.permissions.allow -is [array]) "allow is $($after5.permissions.allow.GetType().Name)"

# --- Case 3: malformed JSON aborts instead of clobbering -------------------
$h3 = New-FakeHome
$settings3 = Join-Path $h3 ".claude/settings.json"
$corrupt = '{ "model": "claude-opus-5", this is not json '
Set-Content -Path $settings3 -Value $corrupt -Encoding utf8

$r3 = Invoke-Setup $h3
# Set-Content -Encoding utf8 writes a BOM and a trailing newline on 5.1, and
# U+FEFF is not whitespace to .NET - so normalise both sides before comparing.
$trimChars = [char[]]@([char]0xFEFF, ' ', "`r"[0], "`n"[0], "`t"[0])
$stillThere = (Get-Content -Raw -Path $settings3).Trim($trimChars)
$corruptTrimmed = $corrupt.Trim($trimChars)

Check "malformed settings.json fails loudly" ($r3.code -ne 0) "exit code was $($r3.code)"
Check "malformed settings.json is untouched" ($stillThere -eq $corruptTrimmed) "file was rewritten: $stillThere"

# --- Case 4: no settings.json at all -> created cleanly --------------------
$h4 = New-FakeHome
Invoke-Setup $h4 | Out-Null
$settings4 = Join-Path $h4 ".claude/settings.json"
Check "settings.json created when absent"    (Test-Path $settings4) "file not created"
if (Test-Path $settings4) {
    $after4 = Get-Content -Raw -Path $settings4 | ConvertFrom-Json
    Check "fresh install registers hooks"     ($null -ne $after4.hooks) "hooks key missing"
}

foreach ($h in @($h1, $h2, $h3, $h4, $h5)) { Remove-Item -Recurse -Force $h -ErrorAction SilentlyContinue }

Write-Host ""
if ($failed -gt 0) {
    Write-Host "FAILED - $failed check(s)" -ForegroundColor Red
    exit 1
}
Write-Host "PASSED - settings.json merge is non-destructive" -ForegroundColor Green
