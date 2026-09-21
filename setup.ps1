# vii-stack installer (Windows / PowerShell).
# Idempotent: re-running re-syncs skills, CLAUDE.md block, and settings.json hooks.

[CmdletBinding()]
param(
    [switch]$DryRun
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root = $PSScriptRoot

# Detect which PowerShell executable to use in hooks (pwsh 7+ preferred, fallback to Windows PowerShell 5.1).
$PsExe = $null
$pwshCmd = Get-Command pwsh -ErrorAction SilentlyContinue
if ($pwshCmd) { $PsExe = $pwshCmd.Source }
if (-not $PsExe) {
    $psCmd = Get-Command powershell -ErrorAction SilentlyContinue
    if ($psCmd) { $PsExe = $psCmd.Source }
}
if (-not $PsExe) { throw "vii-stack: no powershell executable found on PATH" }

$ClaudeDir = Join-Path $HOME ".claude"
$SkillsDir = Join-Path $ClaudeDir "skills"
$ClaudeMd  = Join-Path $ClaudeDir "CLAUDE.md"
$Settings  = Join-Path $ClaudeDir "settings.json"
$ViiHome   = Join-Path $HOME ".vii"

function Step($msg) { Write-Host "==> $msg" -ForegroundColor Cyan }
function Info($msg) { Write-Host "    $msg" -ForegroundColor DarkGray }
function Warn($msg) { Write-Host "    $msg" -ForegroundColor Yellow }

# Recursively turn ConvertFrom-Json output into plain hashtables. Stands in for
# `ConvertFrom-Json -AsHashtable`, which does not exist on Windows PowerShell
# 5.1 - the version the README says vii-stack supports.
function ConvertTo-HashtableDeep($obj) {
    if ($null -eq $obj) { return $null }
    if ($obj -is [string] -or $obj -is [valuetype]) { return $obj }
    if ($obj -is [System.Collections.IDictionary]) {
        $h = @{}
        foreach ($k in @($obj.Keys)) { $h[$k] = ConvertTo-HashtableDeep $obj[$k] }
        return $h
    }
    if ($obj -is [System.Collections.IEnumerable]) {
        $arr = @(foreach ($item in $obj) { ConvertTo-HashtableDeep $item })
        # `return $arr` would unwrap a single-element array into a scalar, and
        # ConvertTo-Json would then write an object where the file had a
        # one-item list. That silently corrupts any third-party setting shaped
        # like [{...}] - a hooks matcher with exactly one hook, for instance,
        # which Claude Code then refuses to load. The unary comma keeps it an
        # array of one.
        return ,$arr
    }
    if ($obj -is [psobject]) {
        $h = @{}
        foreach ($p in $obj.PSObject.Properties) { $h[$p.Name] = ConvertTo-HashtableDeep $p.Value }
        return $h
    }
    return $obj
}

# ---------------------------------------------------------------------------
# 1. Ensure ~/.claude and ~/.vii exist.
# ---------------------------------------------------------------------------
Step "Preparing directories"
foreach ($d in @($ClaudeDir, $SkillsDir, $ViiHome)) {
    if (-not (Test-Path $d)) {
        if ($DryRun) { Info "would create $d" }
        else        { New-Item -ItemType Directory -Path $d | Out-Null; Info "created $d" }
    } else {
        Info "exists $d"
    }
}

# ---------------------------------------------------------------------------
# 2. Sync skills: flatten skills/<stage>/vii-* into ~/.claude/skills/vii-*.
# ---------------------------------------------------------------------------
Step "Syncing skills to $SkillsDir"
$srcSkillRoot = Join-Path $Root "skills"
if (-not (Test-Path $srcSkillRoot)) {
    Warn "no skills/ directory in repo - skipping"
} else {
    $skillDirs = Get-ChildItem -Path $srcSkillRoot -Recurse -Directory |
        Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") }

    foreach ($s in $skillDirs) {
        $dest = Join-Path $SkillsDir $s.Name
        if ($DryRun) {
            Info "would sync $($s.Name) -> $dest"
            continue
        }
        if (Test-Path $dest) { Remove-Item -Recurse -Force $dest }
        Copy-Item -Recurse -Path $s.FullName -Destination $dest
        Info "synced $($s.Name)"
    }
}

# ---------------------------------------------------------------------------
# 3. Merge vii-stack block into ~/.claude/CLAUDE.md.
# ---------------------------------------------------------------------------
Step "Updating $ClaudeMd"
$blockPath = Join-Path $Root "CLAUDE.md"
$block = Get-Content -Raw -Path $blockPath

$existing = ""
if (Test-Path $ClaudeMd) { $existing = Get-Content -Raw -Path $ClaudeMd }

$beginMark = '<!-- BEGIN vii-stack -->'
$endMark   = '<!-- END vii-stack -->'
$blockPattern = '(?s)<!-- BEGIN vii-stack -->.*?<!-- END vii-stack -->'

# Extract just the BEGIN..END portion of $block (drops the leading HTML comment header).
$blockCore = [regex]::Match($block, $blockPattern).Value
if (-not $blockCore) { throw "vii-stack: CLAUDE.md template is missing BEGIN/END markers" }

if ($existing -match $blockPattern) {
    $merged = [regex]::Replace(
        $existing,
        $blockPattern,
        { param($m) $blockCore }
    )
    Info "replaced existing vii-stack block"
} else {
    $sep = if ($existing.Length -gt 0 -and -not $existing.EndsWith("`n")) { "`n`n" } else { "`n" }
    $merged = $existing + $sep + $blockCore
    Info "appended vii-stack block"
}

if ($DryRun) { Info "would write $ClaudeMd" }
else        { Set-Content -Path $ClaudeMd -Value $merged -Encoding utf8 }

# ---------------------------------------------------------------------------
# 4. Merge hooks + MCP server into ~/.claude/settings.json.
# ---------------------------------------------------------------------------
Step "Updating $Settings"
$snippetPath = Join-Path $Root "hooks/settings.snippet.json"
$snippetRaw  = Get-Content -Raw -Path $snippetPath
$rootForJson = ($Root -replace '\\', '/')
$snippetRaw  = $snippetRaw -replace '\{\{VII_STACK_ROOT\}\}', $rootForJson
$psExeForJson = ($PsExe -replace '\\', '/')
$snippetRaw  = $snippetRaw -replace '\{\{PS_EXE\}\}', $psExeForJson
$snippet     = $snippetRaw | ConvertFrom-Json

$current = @{}
if (Test-Path $Settings) {
    $rawSettings = Get-Content -Raw -Path $Settings
    if ($rawSettings -and $rawSettings.Trim()) {
        # ConvertFrom-Json -AsHashtable is PowerShell 7+. On 5.1 it throws, so
        # parse to PSCustomObject and convert by hand rather than falling back
        # to an empty hashtable - that would silently discard the user's
        # existing settings.json on the very next write.
        try {
            $current = ConvertTo-HashtableDeep ($rawSettings | ConvertFrom-Json)
        } catch {
            throw "vii-stack: $Settings is not valid JSON ($($_.Exception.Message)). Refusing to overwrite it - fix or move the file, then re-run setup.ps1."
        }
        if ($null -eq $current) { $current = @{} }

        # Keep one timestamped copy before rewriting a file we did not create.
        if (-not $DryRun) {
            $backup = "$Settings.vii-backup-" + (Get-Date -Format 'yyyyMMdd-HHmmss')
            Copy-Item -Path $Settings -Destination $backup -Force
            Info "backed up existing settings to $backup"
        } else {
            Info "would back up existing settings"
        }
    }
}

# Merge hooks
if (-not $current.ContainsKey('hooks')) { $current['hooks'] = @{} }
foreach ($evt in $snippet.hooks.PSObject.Properties.Name) {
    $incoming = @($snippet.hooks.$evt)
    # Strip any prior vii-stack entries by matching command substring "vii-stack".
    $existingArr = @()
    if ($current.hooks.ContainsKey($evt)) {
        $existingArr = @($current.hooks[$evt] | Where-Object {
            $keep = $true
            foreach ($h in @($_.hooks)) {
                if ($h.command -and ($h.command -match 'vii-stack' -or $h.command -match 'vii-careful-check' -or $h.command -match 'vii-cheap-rewrite' -or $h.command -match 'vii-freeze-check' -or $h.command -match 'vii-session-start')) {
                    $keep = $false; break
                }
            }
            $keep
        })
    }
    # vii-stack's entries go FIRST. A PreToolUse hook that returns
    # hookSpecificOutput (RTK's `rtk hook claude` does this for every git
    # command) ends the chain, so anything registered ahead of
    # vii-careful-check silently disables it - destructive commands then run
    # unblocked. Safety enforcement cannot depend on being registered first by
    # luck, so claim the front of the list on every install.
    $current.hooks[$evt] = @($incoming + $existingArr)
}

# Merge mcpServers
if (-not $current.ContainsKey('mcpServers')) { $current['mcpServers'] = @{} }
foreach ($name in $snippet.mcpServers.PSObject.Properties.Name) {
    $current.mcpServers[$name] = $snippet.mcpServers.$name
}

$out = $current | ConvertTo-Json -Depth 20
if ($DryRun) { Info "would write $Settings" }
else        { Set-Content -Path $Settings -Value $out -Encoding utf8; Info "wrote $Settings" }

# ---------------------------------------------------------------------------
# 5. Install vii-brain dependencies and initialise the database.
# ---------------------------------------------------------------------------
Step "Setting up vii-brain"
$ViibrainDir = Join-Path $Root "vii-brain"
$NodeModules = Join-Path $ViibrainDir "node_modules"
if ($DryRun) {
    Info "would npm install in $ViibrainDir"
    Info "would run vii-brain init"
} else {
    $NpmCmd = Get-Command npm -ErrorAction SilentlyContinue
    if (-not $NpmCmd) {
        Warn "npm not found - skipping vii-brain dependency install. Install Node.js 18+ and re-run setup.ps1."
    } else {
        if (-not (Test-Path $NodeModules)) {
            Push-Location $ViibrainDir
            try { & npm install --silent; Info "npm install complete" } finally { Pop-Location }
        } else {
            Info "node_modules already present, skipping install"
        }
        & $PsExe -NoProfile -File (Join-Path $Root "bin/vii-brain.ps1") init
    }
}

# ---------------------------------------------------------------------------
# Done.
# ---------------------------------------------------------------------------
Write-Host ""
Write-Host "vii-stack installed." -ForegroundColor Green
Write-Host "Open Claude Code in any project and try: /vii-office-hours"
