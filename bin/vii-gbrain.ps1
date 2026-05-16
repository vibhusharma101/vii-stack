# GBrain CLI shim. Stub for Phase 2 — full backend lands in Phase 6.
# Usage:
#   vii-gbrain init                    # create ~/.vii/gbrain.db from schema
#   vii-gbrain add <tag> <text>        # store a note
#   vii-gbrain search <query>          # full-text search
#   vii-gbrain list [--tag <tag>]      # list recent entries
#   vii-gbrain remove <id>             # delete by id

param(
    [Parameter(Position=0)]
    [string]$Command,

    [Parameter(Position=1, ValueFromRemainingArguments=$true)]
    [string[]]$Args
)

$ErrorActionPreference = 'Stop'

$ViiRoot = Join-Path $HOME ".vii"
$DbPath  = Join-Path $ViiRoot "gbrain.db"

switch ($Command) {
    'init' {
        if (-not (Test-Path $ViiRoot)) { New-Item -ItemType Directory -Path $ViiRoot | Out-Null }
        Write-Output "vii-gbrain: stub. Phase 6 wires PGLite at $DbPath."
        Write-Output "Schema lives at: $PSScriptRoot/../gbrain/schema.sql"
    }
    default {
        Write-Output "vii-gbrain: stub (Phase 2). Commands not yet implemented: $Command"
        Write-Output "Phase 6 lands the PGLite backend. For now this command is a no-op."
    }
}
