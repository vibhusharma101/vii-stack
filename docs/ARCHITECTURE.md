# vii-stack Architecture

## Goal

Give a single builder (using Claude Code) the discipline and throughput of a small team by encoding role-based workflows as slash commands. Each command is a markdown skill file Claude reads and executes.

## Design principles

1. **Claude Code only.** No multi-AI orchestration, no Codex bridges, no cross-tool coordination.
2. **Skills are markdown.** Every `/vii-*` command is a `SKILL.md` file Claude reads at invocation time. No compiled binaries, no runtime daemons except where MCP requires it (Playwright).
3. **Prefixed namespace.** Every command is `/vii-<verb>` to avoid colliding with other skill packs.
4. **Stage gates.** Each stage in the Think→Ship loop produces an artifact the next stage consumes (e.g. `/vii-plan-eng` writes `.vii/plan.md`, `/vii-review` reads it).
5. **Hooks for safety, not skills.** Destructive-command blocking lives in `settings.json` hooks, not in skill prompts (skill prompts are advisory; hooks are enforced).
6. **Persistent memory is first-class.** GBrain is the long-term store; Claude Code's auto-memory is the short-term store. Both are wired in.

## Layout

```
vii-stack/
├── README.md
├── CLAUDE.md                       # Block appended to user CLAUDE.md during install
├── setup.ps1                       # Windows installer (primary)
├── setup.sh                        # POSIX installer (parity)
├── skills/
│   ├── think/
│   │   └── vii-office-hours/SKILL.md
│   ├── plan/
│   │   ├── vii-plan-ceo/SKILL.md
│   │   ├── vii-plan-eng/SKILL.md
│   │   ├── vii-plan-design/SKILL.md
│   │   ├── vii-plan-devex/SKILL.md
│   │   └── vii-autoplan/SKILL.md
│   ├── build/
│   │   ├── vii-design-consult/SKILL.md
│   │   ├── vii-design-shotgun/SKILL.md
│   │   └── vii-design-html/SKILL.md
│   ├── review/
│   │   ├── vii-review/SKILL.md
│   │   ├── vii-investigate/SKILL.md
│   │   ├── vii-design-review/SKILL.md
│   │   └── vii-devex-review/SKILL.md
│   ├── test/
│   │   ├── vii-qa/SKILL.md
│   │   ├── vii-qa-only/SKILL.md
│   │   └── vii-browse/SKILL.md
│   ├── ship/
│   │   ├── vii-ship/SKILL.md
│   │   ├── vii-land/SKILL.md
│   │   ├── vii-canary/SKILL.md
│   │   ├── vii-benchmark/SKILL.md
│   │   └── vii-doc-release/SKILL.md
│   ├── reflect/
│   │   ├── vii-retro/SKILL.md
│   │   └── vii-learn/SKILL.md
│   ├── security/
│   │   └── vii-cso/SKILL.md
│   └── power/
│       ├── vii-careful/SKILL.md
│       ├── vii-freeze/SKILL.md
│       ├── vii-guard/SKILL.md
│       └── vii-unfreeze/SKILL.md
├── bin/
│   ├── vii-freeze-check.ps1        # Called by PreToolUse hook
│   ├── vii-careful-check.ps1       # Called by PreToolUse hook
│   └── vii-gbrain.ps1              # GBrain CLI shim
├── hooks/
│   └── settings.snippet.json       # Merged into ~/.claude/settings.json by setup
├── gbrain/
│   ├── schema.sql                  # PGLite + Supabase schema
│   ├── migrations/
│   └── README.md
└── docs/
    ├── ARCHITECTURE.md
    └── skills.md
```

## Stage artifacts

Each stage writes its output under `.vii/` in the project repo so the next stage can read it.

| Stage   | Skill                   | Artifact                          |
|---------|-------------------------|-----------------------------------|
| Think   | `/vii-office-hours`     | `.vii/think/<topic>.md`           |
| Plan    | `/vii-plan-eng` etc.    | `.vii/plan.md`                    |
| Build   | `/vii-design-shotgun`   | `.vii/mockups/<variant>.html`     |
| Review  | `/vii-review`           | `.vii/review/<sha>.md`            |
| Test    | `/vii-qa`               | `.vii/qa/<run>.md`, screenshots/  |
| Ship    | `/vii-ship`             | PR link recorded in GBrain        |
| Reflect | `/vii-retro`            | `.vii/retro/<week>.md`            |

`.vii/` is git-ignored by default; user can opt to commit `plan.md` and `retro/`.

## GBrain (kept from gstack)

A persistent knowledge base that survives across Claude Code sessions and projects.

- **Default backend:** PGLite (embedded Postgres in a single file at `~/.vii/gbrain.db`). Zero setup.
- **Optional backend:** Supabase (for multi-device sync). User flips a flag in `~/.vii/config.yaml`.
- **Content:** indexed code symbols, past PR descriptions, retro notes, design taste profile, per-domain reference URLs.
- **Access:** Claude reads/writes via `bin/vii-gbrain.ps1` (CLI shim) called from skills. Skills query GBrain at the start of long sessions to recall prior context.
- **Distinct from Claude's auto-memory** at `~/.claude/projects/.../memory/`: that is conversational, slug-keyed, and per-project. GBrain is structured, queryable, and cross-project.

## Playwright MCP

`/vii-browse` calls the Playwright MCP server. The installer registers it under `mcpServers` in `~/.claude/settings.json`. Screenshots land in `.vii/screenshots/` so design review skills can pick them up.

## Hooks (enforced)

`settings.snippet.json` merges these into the user's settings:

- **PreToolUse / Bash**: runs `vii-careful-check.ps1` — blocks `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`, etc. unless the session has acknowledged `/vii-careful`.
- **PreToolUse / Edit, Write, NotebookEdit**: runs `vii-freeze-check.ps1` — if `.vii/freeze` exists, rejects edits outside the locked directory.
- **SessionStart**: prints active freeze status, current stage artifacts, and any pending retro.

Skills can *advise* the user but cannot bypass hooks — hooks are the source of truth for safety.

## Loop diagram

```
        ┌─────────┐
        │  Think  │   /vii-office-hours
        └────┬────┘
             ▼
        ┌─────────┐
        │  Plan   │   /vii-autoplan → CEO + Eng + Design + DevEx
        └────┬────┘
             ▼
        ┌─────────┐
        │  Build  │   /vii-design-shotgun → /vii-design-html → code
        └────┬────┘
             ▼
        ┌─────────┐
        │ Review  │   /vii-review, /vii-design-review, /vii-cso
        └────┬────┘
             ▼
        ┌─────────┐
        │  Test   │   /vii-qa (+ /vii-browse)
        └────┬────┘
             ▼
        ┌─────────┐
        │  Ship   │   /vii-ship → /vii-land → /vii-canary
        └────┬────┘
             ▼
        ┌─────────┐
        │ Reflect │   /vii-retro → /vii-learn → GBrain
        └─────────┘
```

## Non-goals

- Multi-AI coordination (`/pair-agent`, `/codex` from gstack).
- A GUI chrome extension (gstack's "GStack Browser"). Playwright MCP is enough.
- Telemetry. vii-stack ships zero phone-home.
- Cloud deploy automation beyond `/vii-land` calling whatever `deploy.ps1` the project defines.
