# Tests for the vii-careful-check PreToolUse hook.
# Feeds real hook payloads to the script and asserts block (exit 2) vs allow
# (exit 0). Exits 1 on any failure so CI can gate on it.
#
#   .\bin\vii-hook-test.ps1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = Split-Path -Parent $PSScriptRoot
$Hook = Join-Path $Root "bin/vii-careful-check.ps1"
$PsExe = (Get-Process -Id $PID).Path

# Run against a throwaway cwd so a stray .vii/careful-acked-* in the real repo
# can't mask a genuine block.
$TmpCwd = Join-Path ([System.IO.Path]::GetTempPath()) ("vii-hook-test-" + [guid]::NewGuid().ToString("N"))
New-Item -ItemType Directory -Path $TmpCwd | Out-Null

$cases = @(
    # --- must block: the command itself is destructive -------------------
    @{ block = $true;  name = "rm -rf /";                cmd = "rm -rf /" }
    @{ block = $true;  name = "git reset --hard";        cmd = "git reset --hard origin/main" }
    @{ block = $true;  name = "git push --force";        cmd = "git push --force origin main" }
    @{ block = $true;  name = "git clean -fd";           cmd = "git clean -fd" }
    @{ block = $true;  name = "DROP TABLE";              cmd = "psql -c DROP TABLE users" }
    @{ block = $true;  name = "destructive before heredoc"
       cmd = "git reset --hard HEAD~1 && cat > note.md <<'EOF'`nharmless`nEOF" }

    # --- must allow: ordinary commands -----------------------------------
    @{ block = $false; name = "git status";              cmd = "git status" }
    @{ block = $false; name = "git log";                 cmd = "git log --oneline -5" }

    # --- must allow: the pattern appears as DATA, not as a command -------
    @{ block = $false; name = "heredoc documents reset"
       cmd = "cat > SKILL.md <<'MD'`n- Do not discard changes: no git reset --hard.`nMD" }
    @{ block = $false; name = "heredoc documents rm -rf"
       cmd = "cat > README.md <<'EOF'`nNever run rm -rf / on your machine.`nEOF" }
    @{ block = $false; name = "unquoted heredoc marker"
       cmd = "cat > f.txt <<EOF`ngit push --force is dangerous`nEOF" }
    @{ block = $false; name = "two heredocs in one command"
       cmd = "cat > a <<'A'`ngit reset --hard`nA`ncat > b <<'B'`nrm -rf /`nB" }
    @{ block = $false; name = "indented heredoc terminator"
       cmd = "cat > f <<-EOF`ngit clean -fd`n  EOF" }
    @{ block = $false; name = "--body mentions force push"
       cmd = 'gh pr create --body "explains why git push --force is banned"' }
    @{ block = $false; name = "commit -m mentions DROP TABLE"
       cmd = 'git commit -m "guard against DROP TABLE in migrations"' }
)

$failed = 0
Write-Host "==> Testing vii-careful-check ($($cases.Count) cases)" -ForegroundColor Cyan

# The hook signals a block on stderr + exit 2. Windows PowerShell turns a
# native command's stderr into NativeCommandError, which 'Stop' would treat as
# fatal, so relax it for the invocations below. The exit code is the assertion.
$ErrorActionPreference = 'Continue'

foreach ($c in $cases) {
    $payload = @{
        session_id = "hook-test-no-ack"
        cwd        = $TmpCwd
        tool_input = @{ command = $c.cmd }
    } | ConvertTo-Json -Depth 5 -Compress

    $out = $payload | & $PsExe -NoProfile -File $Hook 2>&1
    $code = $LASTEXITCODE
    $blocked = ($code -eq 2)

    if ($blocked -eq $c.block) {
        Write-Host "    ok    $($c.name)" -ForegroundColor DarkGray
    } else {
        $failed++
        $want = if ($c.block) { "block" } else { "allow" }
        $got  = if ($blocked)  { "block" } else { "allow" }
        Write-Host "    FAIL  $($c.name): expected $want, got $got" -ForegroundColor Red
        Write-Host "          cmd: $($c.cmd -replace "`n", '\n')" -ForegroundColor DarkGray
        if ($out) { Write-Host "          hook: $out" -ForegroundColor DarkGray }
    }
}

# An acknowledged session must allow everything.
$ackPayload = @{
    session_id = "acked"
    cwd        = $TmpCwd
    tool_input = @{ command = "rm -rf /" }
} | ConvertTo-Json -Depth 5 -Compress
New-Item -ItemType Directory -Path (Join-Path $TmpCwd ".vii") -Force | Out-Null
Set-Content -Path (Join-Path $TmpCwd ".vii/careful-acked-acked") -Value "ack" -Encoding utf8
$ackPayload | & $PsExe -NoProfile -File $Hook 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) {
    Write-Host "    ok    acked session bypasses block" -ForegroundColor DarkGray
} else {
    $failed++
    Write-Host "    FAIL  acked session bypasses block: expected allow, got block" -ForegroundColor Red
}

Remove-Item -Recurse -Force $TmpCwd -ErrorAction SilentlyContinue

Write-Host ""
if ($failed -gt 0) {
    Write-Host "FAILED - $failed case(s)" -ForegroundColor Red
    exit 1
}
Write-Host "PASSED - all hook cases" -ForegroundColor Green
