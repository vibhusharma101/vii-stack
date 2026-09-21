# Tests for the vii-stack PreToolUse hooks.
#
# Feeds real hook payloads to each hook script and asserts on what it does:
#   vii-careful-check   block (exit 2) vs allow (exit 0)
#   vii-freeze-check    block (exit 2) vs allow (exit 0)
#   vii-cheap-rewrite   whether it rewrites, to what, and whether it approves
#
# Exits 1 on any failure so CI can gate on it.
#
#   .\bin\vii-hook-test.ps1

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root    = Split-Path -Parent $PSScriptRoot
$Careful = Join-Path $Root "bin/vii-careful-check.ps1"
$Freeze  = Join-Path $Root "bin/vii-freeze-check.ps1"
$Cheap   = Join-Path $Root "bin/vii-cheap-rewrite.ps1"
$PsExe   = (Get-Process -Id $PID).Path

function New-TempDir($tag) {
    $d = Join-Path ([System.IO.Path]::GetTempPath()) ("vii-hook-test-$tag-" + [guid]::NewGuid().ToString("N"))
    New-Item -ItemType Directory -Path $d | Out-Null
    return $d
}

$failed = 0
function Pass($name) { Write-Host "    ok    $name" -ForegroundColor DarkGray }
function Fail($name, $detail) {
    $script:failed++
    Write-Host "    FAIL  $name" -ForegroundColor Red
    if ($detail) { Write-Host "          $detail" -ForegroundColor DarkGray }
}

# Run a hook with a payload. Returns exit code and stdout; stderr is discarded
# because the block message is not what the assertions are about.
function Invoke-Hook($hook, $payload) {
    $json = $payload | ConvertTo-Json -Depth 6 -Compress
    $stdout = $json | & $PsExe -NoProfile -File $hook 2>$null | Out-String
    return @{ code = $LASTEXITCODE; stdout = $stdout.Trim() }
}

# A hook signals a block on stderr + exit 2. Windows PowerShell turns a native
# command's stderr into NativeCommandError, which 'Stop' would treat as fatal,
# so relax it for the invocations below. The exit code is the assertion.
$ErrorActionPreference = 'Continue'

# ===========================================================================
# vii-careful-check
# ===========================================================================

# Run against a throwaway cwd so a stray .vii/careful-acked-* in the real repo
# can't mask a genuine block.
$CarefulCwd = New-TempDir "careful"

$carefulCases = @(
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

Write-Host "==> vii-careful-check ($($carefulCases.Count + 1) cases)" -ForegroundColor Cyan

foreach ($c in $carefulCases) {
    $r = Invoke-Hook $Careful @{
        session_id = "hook-test-no-ack"
        cwd        = $CarefulCwd
        tool_input = @{ command = $c.cmd }
    }
    $blocked = ($r.code -eq 2)
    if ($blocked -eq $c.block) { Pass $c.name }
    else {
        $want = if ($c.block) { "block" } else { "allow" }
        $got  = if ($blocked)  { "block" } else { "allow" }
        Fail $c.name "expected $want, got $got - cmd: $($c.cmd -replace "`n", '\n')"
    }
}

# An acknowledged session must allow everything.
New-Item -ItemType Directory -Path (Join-Path $CarefulCwd ".vii") -Force | Out-Null
Set-Content -Path (Join-Path $CarefulCwd ".vii/careful-acked-acked") -Value "ack" -Encoding utf8
$r = Invoke-Hook $Careful @{ session_id = "acked"; cwd = $CarefulCwd; tool_input = @{ command = "rm -rf /" } }
if ($r.code -eq 0) { Pass "acked session bypasses block" }
else               { Fail "acked session bypasses block" "expected allow, got block" }

# ===========================================================================
# vii-freeze-check
# ===========================================================================
#
# /vii-freeze always writes an absolute path, and Claude Code's Edit/Write tools
# always pass an absolute file_path, so those are the shapes tested here.

$Proj = New-TempDir "freeze"
$Lock = Join-Path $Proj "src"
foreach ($d in @("src", "src/nested", "src-old", "srcbackup", "docs", ".vii")) {
    New-Item -ItemType Directory -Path (Join-Path $Proj $d) -Force | Out-Null
}
$FreezeFile = Join-Path $Proj ".vii/freeze"

# Write the lock the way /vii-freeze specifies: one line, UTF-8, no BOM.
function Set-Lock($text) {
    [System.IO.File]::WriteAllText($FreezeFile, $text, [System.Text.UTF8Encoding]::new($false))
}

function Test-Freeze($name, $wantBlock, $toolInput) {
    $r = Invoke-Hook $Freeze @{ cwd = $Proj; tool_input = $toolInput }
    $blocked = ($r.code -eq 2)
    if ($blocked -eq $wantBlock) { Pass $name }
    else {
        $want = if ($wantBlock) { "block" } else { "allow" }
        $got  = if ($blocked)   { "block" } else { "allow" }
        $target = if ($toolInput.ContainsKey('file_path')) { $toolInput.file_path } else { $toolInput.notebook_path }
        Fail $name "expected $want, got $got - target: $target"
    }
}

Write-Host ""
Write-Host "==> vii-freeze-check" -ForegroundColor Cyan

# --- no lock in place: nothing is blocked ----------------------------------
Test-Freeze "no freeze file allows anything" $false @{ file_path = (Join-Path $Proj "docs/readme.md") }

Set-Lock ""
Test-Freeze "empty freeze file allows anything" $false @{ file_path = (Join-Path $Proj "docs/readme.md") }

# --- lock in place: inside is allowed --------------------------------------
Set-Lock $Lock
Test-Freeze "file directly inside lock"      $false @{ file_path = (Join-Path $Lock "app.ts") }
Test-Freeze "file in nested subdirectory"    $false @{ file_path = (Join-Path $Lock "nested/deep.ts") }
Test-Freeze "forward slashes inside lock"    $false @{ file_path = ((Join-Path $Lock "app.ts") -replace '\\', '/') }
Test-Freeze "different case inside lock"     $false @{ file_path = ((Join-Path $Lock "app.ts").ToUpperInvariant()) }

# --- lock in place: outside is blocked -------------------------------------
Test-Freeze "sibling directory"              $true  @{ file_path = (Join-Path $Proj "docs/readme.md") }
Test-Freeze "project root file"              $true  @{ file_path = (Join-Path $Proj "package.json") }
Test-Freeze ".. traversal out of lock"       $true  @{ file_path = (Join-Path $Lock "../package.json") }
Test-Freeze "notebook outside lock"          $true  @{ notebook_path = (Join-Path $Proj "docs/analysis.ipynb") }

# The lock is a directory, so a sibling that merely shares its name as a
# prefix is outside it. A plain string prefix check gets this wrong.
Test-Freeze "sibling sharing prefix (src-old)"   $true @{ file_path = (Join-Path $Proj "src-old/app.ts") }
Test-Freeze "sibling sharing prefix (srcbackup)" $true @{ file_path = (Join-Path $Proj "srcbackup/app.ts") }

# --- lock written with a trailing separator behaves the same ---------------
Set-Lock ($Lock + [System.IO.Path]::DirectorySeparatorChar)
Test-Freeze "trailing-slash lock: inside"    $false @{ file_path = (Join-Path $Lock "app.ts") }
Test-Freeze "trailing-slash lock: outside"   $true  @{ file_path = (Join-Path $Proj "docs/readme.md") }

# --- lock written with a BOM (what Set-Content -Encoding utf8 does on 5.1) --
[System.IO.File]::WriteAllText($FreezeFile, $Lock, [System.Text.UTF8Encoding]::new($true))
Test-Freeze "BOM-prefixed lock: inside"      $false @{ file_path = (Join-Path $Lock "app.ts") }
Test-Freeze "BOM-prefixed lock: outside"     $true  @{ file_path = (Join-Path $Proj "docs/readme.md") }

# ===========================================================================
# vii-cheap-rewrite
# ===========================================================================
#
# The hook only acts when .vii/cheap-mode exists AND an rtk binary resolves.
# Put a stub `rtk` first on PATH so the rewrite path is exercised on machines
# (and CI runners) with no real rtk, and point HOME at an empty dir so the
# ~/.rtk/bin fallback can't find the real one either.

$CheapProj = New-TempDir "cheap"
$StubBin   = New-TempDir "rtkstub"
$EmptyHome = New-TempDir "home"
Set-Content -Path (Join-Path $StubBin "rtk.cmd") -Value "@echo off" -Encoding ascii
$CheapSentinel = Join-Path $CheapProj ".vii/cheap-mode"
New-Item -ItemType Directory -Path (Join-Path $CheapProj ".vii") -Force | Out-Null

$origPath = $env:PATH
$origProfile = $env:USERPROFILE

function Invoke-Cheap($cmd, [switch]$NoRtk) {
    try {
        $env:USERPROFILE = $EmptyHome
        # System32 only: enough to run, and guaranteed not to contain rtk.
        $env:PATH = if ($NoRtk) { "$env:SystemRoot\System32" } else { "$StubBin;$env:SystemRoot\System32" }
        $r = Invoke-Hook $Cheap @{ cwd = $CheapProj; tool_input = @{ command = $cmd } }
    } finally {
        $env:PATH = $origPath
        $env:USERPROFILE = $origProfile
    }
    $rewritten = $null; $decision = $null
    if ($r.stdout) {
        try {
            $o = $r.stdout | ConvertFrom-Json
            $rewritten = $o.hookSpecificOutput.updatedInput.command
            $decision  = $o.hookSpecificOutput.permissionDecision
        } catch {}
    }
    return @{ code = $r.code; rewritten = $rewritten; decision = $decision }
}

# Expect the command wrapped to exactly $want, and auto-approved.
function Test-Wrapped($name, $cmd, $want, [switch]$NoRtk) {
    $r = Invoke-Cheap $cmd -NoRtk:$NoRtk
    if ($r.code -ne 0)             { Fail $name "hook exited $($r.code) - it must never block"; return }
    if ($r.rewritten -ne $want)    { Fail $name "expected '$want', got '$($r.rewritten)'"; return }
    if ($r.decision -ne 'allow')   { Fail $name "wrapped but permissionDecision is '$($r.decision)'"; return }
    Pass $name
}

# Expect the command left completely alone: no rewrite, and no approval.
function Test-Untouched($name, $cmd, [switch]$NoRtk) {
    $r = Invoke-Cheap $cmd -NoRtk:$NoRtk
    if ($r.code -ne 0)     { Fail $name "hook exited $($r.code) - it must never block"; return }
    if ($r.rewritten)      { Fail $name "rewrote to '$($r.rewritten)' - should be untouched"; return }
    if ($r.decision)       { Fail $name "auto-approved ($($r.decision)) - only read-only commands may be"; return }
    Pass $name
}

Write-Host ""
Write-Host "==> vii-cheap-rewrite" -ForegroundColor Cyan

# --- gated off: no sentinel, or no rtk --------------------------------------
Remove-Item $CheapSentinel -ErrorAction SilentlyContinue
Test-Untouched "no sentinel: git status untouched" "git status"

Set-Content -Path $CheapSentinel -Value "mode: on" -Encoding utf8
Test-Untouched "no rtk binary: git status untouched" "git status" -NoRtk

# --- read-only allowlist is wrapped and approved ----------------------------
Test-Wrapped "git status"           "git status"            "rtk git status"
Test-Wrapped "git log with args"    "git log --oneline -5"  "rtk git log --oneline -5"
Test-Wrapped "git diff"             "git diff HEAD~1"       "rtk git diff HEAD~1"
Test-Wrapped "cargo test"           "cargo test"            "rtk cargo test"
Test-Wrapped "pytest"               "pytest -q"             "rtk pytest -q"
Test-Wrapped "ls"                   "ls -la"                "rtk ls -la"
Test-Wrapped "leading whitespace"   "   git status"         "rtk git status"

# --- write-side git verbs are never touched ---------------------------------
Test-Untouched "git commit"         "git commit -m wip"
Test-Untouched "git push"           "git push origin main"
Test-Untouched "git add"            "git add ."
Test-Untouched "git pull"           "git pull"
Test-Untouched "git checkout"       "git checkout main"

# --- shell composition is never touched --------------------------------------
Test-Untouched "pipe"               "git status | head"
Test-Untouched "redirect out"       "ls > files.txt"
Test-Untouched "redirect in"        "grep x < in.txt"
Test-Untouched "&& chain"           "git status && git log"
Test-Untouched "; chain"            "git status; git log"
Test-Untouched "command substitution" 'echo $(git status)'
Test-Untouched "backtick substitution" 'echo `git status`'

# --- word boundaries: a lookalike command is not the allowlisted one --------
Test-Untouched "lsof is not ls"     "lsof -i :8080"
Test-Untouched "gitk is not git"    "gitk --all"
Test-Untouched "git status-ish verb" "git stash"

# --- no double wrapping ------------------------------------------------------
Test-Untouched "already rtk-wrapped" "rtk git status"

# --- allowlisted tools with a write flag must not be auto-approved -----------
# The hook's contract is a read-only allowlist whose members are safe to
# auto-approve. These are the same tools invoked to modify files, and an
# auto-approval skips the permission prompt the user would otherwise see.
Test-Untouched "find -delete"       "find . -name *.tmp -delete"
Test-Untouched "prettier --write"   "prettier --write src"
Test-Untouched "eslint --fix"       "eslint --fix src"
Test-Untouched "ruff --fix"         "ruff check --fix ."
Test-Untouched "rubocop -a"         "rubocop -a"
Test-Untouched "rubocop -A"         "rubocop -A"

# --- ultra mode adds -u -------------------------------------------------------
Set-Content -Path $CheapSentinel -Value "mode: ultra" -Encoding utf8
Test-Wrapped "ultra adds -u"        "git status"            "rtk -u git status"

# ===========================================================================

foreach ($d in @($CarefulCwd, $Proj, $CheapProj, $StubBin, $EmptyHome)) {
    Remove-Item -Recurse -Force $d -ErrorAction SilentlyContinue
}

Write-Host ""
if ($failed -gt 0) {
    Write-Host "FAILED - $failed case(s)" -ForegroundColor Red
    exit 1
}
Write-Host "PASSED - all hook cases" -ForegroundColor Green
