# GBrain

Cross-project persistent knowledge base for vii-stack.

## Status

Phase 2 — schema defined, CLI is a stub.
Phase 6 — wire PGLite backend end-to-end.

## Backends

- **PGLite (default).** Embedded Postgres in a single file at `~/.vii/gbrain.db`. Zero setup.
- **Supabase (opt-in).** Set `gbrain.backend: supabase` in `~/.vii/config.yaml` and provide `SUPABASE_URL` + `SUPABASE_KEY` env vars. Useful for multi-device sync.

## What goes in

- Past PR descriptions and outcomes
- Retro notes (one row per week, tag `retro`)
- Design taste profile (tag `design`)
- Per-domain reference URLs (tag `ref:<domain>`)
- Indexed code symbols (tag `code:<repo>`)

## What doesn't

- Conversational state — that belongs in Claude Code's auto-memory at `~/.claude/projects/.../memory/`.
- Secrets. GBrain is a plaintext SQLite/Postgres file.

## Querying

```powershell
vii-gbrain search "auth middleware"
vii-gbrain list --tag retro
```

Skills call this CLI at session start to recall prior context.
