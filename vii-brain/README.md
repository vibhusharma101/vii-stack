# vii-brain

Cross-project persistent memory store for vii-stack.

## How it works

vii-brain stores notes, retro entries, design decisions, and PR outcomes in an embedded Postgres database (PGLite) at `~/.vii/vii-brain.db/`. It is scoped to the current git project automatically, but searchable across all projects.

## Commands

```powershell
# Store a note
vii-brain add retro "shipped auth refactor — token rotation was the tricky part"
vii-brain add learn "always run /vii-cso before pushing auth changes"
vii-brain add ship "https://github.com/org/repo/pull/42"
vii-brain add ref  "https://docs.example.com/api — rate limit is 100 req/min"

# Search across all entries
vii-brain search "auth"

# List recent entries (all, or filtered by tag)
vii-brain list
vii-brain list --tag retro

# Delete an entry by id
vii-brain remove 7
```

## Tags

| Tag | Written by | Contains |
|---|---|---|
| `retro` | `/vii-retro` | Weekly retro notes |
| `learn` | `/vii-learn` | Cross-project learnings |
| `ship` | `/vii-ship` | PR URLs and outcomes |
| `design` | `/vii-plan-design` | Design decisions |
| `ref` | manual | Reference URLs per domain |

## Storage

- **Default:** PGLite embedded Postgres at `~/.vii/vii-brain.db/` (a directory). Zero setup.
- The database is local to your machine. No network access.

## Dependencies

Requires Node.js 18+. `vii-brain.mjs` uses `@electric-sql/pglite`. Dependencies are installed automatically on first use, or by running `setup.ps1`.
