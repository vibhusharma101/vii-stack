# vii-stack skill validator.
# Checks every skills/<stage>/<name>/SKILL.md for the invariants setup.ps1 and
# Claude Code rely on. Exits 1 on any error so CI can gate on it.
#
#   .\bin\vii-validate.ps1            # validate
#   .\bin\vii-validate.ps1 -Quiet     # errors only

[CmdletBinding()]
param(
    [switch]$Quiet
)

$ErrorActionPreference = 'Stop'
Set-StrictMode -Version Latest

$Root      = Split-Path -Parent $PSScriptRoot
$SkillRoot = Join-Path $Root "skills"
$ReadMe    = Get-Content -Raw -Path (Join-Path $Root "README.md")
$ClaudeMd  = Get-Content -Raw -Path (Join-Path $Root "CLAUDE.md")

$errors   = [System.Collections.Generic.List[string]]::new()
$warnings = [System.Collections.Generic.List[string]]::new()
$seen     = @{}

function Fail($msg) { $script:errors.Add($msg) }
function Warn($msg) { $script:warnings.Add($msg) }
function Info($msg) { if (-not $Quiet) { Write-Host "    $msg" -ForegroundColor DarkGray } }

if (-not (Test-Path $SkillRoot)) { throw "vii-validate: no skills/ directory at $SkillRoot" }

$skillDirs = Get-ChildItem -Path $SkillRoot -Recurse -Directory |
    Where-Object { Test-Path (Join-Path $_.FullName "SKILL.md") } |
    Sort-Object Name

if ($skillDirs.Count -eq 0) { throw "vii-validate: no SKILL.md files found under skills/" }

Write-Host "==> Validating $($skillDirs.Count) skills" -ForegroundColor Cyan

foreach ($dir in $skillDirs) {
    $name  = $dir.Name
    $stage = Split-Path -Leaf (Split-Path -Parent $dir.FullName)
    $rel   = "skills/$stage/$name/SKILL.md"
    $body  = Get-Content -Raw -Path (Join-Path $dir.FullName "SKILL.md")

    # setup.ps1 flattens skills/<stage>/<name> -> ~/.claude/skills/<name>, so a
    # duplicate leaf name silently overwrites the earlier one at install time.
    if ($seen.ContainsKey($name)) {
        Fail "$rel : duplicate skill name - also defined at $($seen[$name]). setup.ps1 would overwrite one."
    } else {
        $seen[$name] = $rel
    }

    if ($name -notmatch '^vii-') { Fail "$rel : directory name must start with 'vii-'" }

    $fm = [regex]::Match($body, '(?s)\A---\r?\n(.*?)\r?\n---\r?\n')
    if (-not $fm.Success) {
        Fail "$rel : missing YAML frontmatter delimited by ---"
        continue
    }
    $front = $fm.Groups[1].Value

    $nameMatch = [regex]::Match($front, '(?m)^name:\s*(\S+)\s*$')
    if (-not $nameMatch.Success) {
        Fail "$rel : frontmatter has no 'name:' field"
    } elseif ($nameMatch.Groups[1].Value -ne $name) {
        Fail "$rel : frontmatter name '$($nameMatch.Groups[1].Value)' does not match directory '$name'"
    }

    if ($front -notmatch '(?m)^description:\s*\S') {
        Fail "$rel : frontmatter has no 'description:' field"
    }

    # Claude Code truncates long descriptions; gstack keeps them well under 1024.
    $descMatch = [regex]::Match($front, '(?ms)^description:\s*(.*?)(?=^\w+:|\Z)')
    if ($descMatch.Success -and $descMatch.Groups[1].Value.Trim().Length -gt 1024) {
        Warn "$rel : description exceeds 1024 chars - Claude Code may truncate it"
    }

    if ($body -notmatch "(?m)^#\s+/$([regex]::Escape($name))\s*$") {
        Warn "$rel : body has no '# /$name' heading"
    }

    # Every skill must be discoverable from both surfaces users read.
    if ($ReadMe   -notmatch [regex]::Escape("/$name")) { Fail "README.md : /$name is not listed in the command table" }
    if ($ClaudeMd -notmatch [regex]::Escape("/$name")) { Fail "CLAUDE.md : /$name is not registered in the command list" }

    Info "ok  $stage/$name"
}

# The README advertises a skill count in two places; keep both honest.
$count = $skillDirs.Count
foreach ($pattern in @('Commands \((\d+) total\)', 'Syncs all (\d+) skills')) {
    $m = [regex]::Match($ReadMe, $pattern)
    if (-not $m.Success) {
        Warn "README.md : could not find the '$pattern' line to check the skill count"
    } elseif ([int]$m.Groups[1].Value -ne $count) {
        Fail "README.md : says $($m.Groups[1].Value) skills, repo has $count"
    }
}

Write-Host ""
foreach ($w in $warnings) { Write-Host "warn  $w" -ForegroundColor Yellow }
foreach ($e in $errors)   { Write-Host "error $e" -ForegroundColor Red }

if ($errors.Count -gt 0) {
    Write-Host ""
    Write-Host "FAILED - $($errors.Count) error(s), $($warnings.Count) warning(s)" -ForegroundColor Red
    exit 1
}

Write-Host "PASSED - $count skills, $($warnings.Count) warning(s)" -ForegroundColor Green
