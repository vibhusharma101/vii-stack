# vii-stack

A personal Claude Code skill pack that turns Claude Code into a virtual engineering team — CEO, Designer, Eng Manager, QA, Release Manager, Doc Engineer — for one builder (you).

Inspired by [garrytan/gstack](https://github.com/garrytan/gstack). Built for **Claude Code only**. No Codex, no cross-AI orchestration.

## Status

Phase 1 — **spec only**. No code yet.

- [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) — how the pieces fit together
- [`docs/skills.md`](docs/skills.md) — every slash command, what it does, what it outputs

## The loop

```
Think → Plan → Build → Review → Test → Ship → Reflect
```

Each skill consumes the output of the previous stage and produces input for the next. Skipping stages is allowed but discouraged.

## Install (planned, not built)

```powershell
git clone <vii-stack> $HOME\.claude\skills\vii-stack
cd $HOME\.claude\skills\vii-stack
.\setup.ps1
```

The installer will:
1. Append a `## vii-stack` block to `~/.claude/CLAUDE.md` listing every `/vii-*` command.
2. Merge hook entries into `~/.claude/settings.json` (PreToolUse guards for `/vii-careful` and `/vii-freeze`).
3. Register the Playwright MCP server in `~/.claude/settings.json` for `/vii-browse`.
4. Initialize GBrain (PGLite by default, opt-in Supabase).

## License

MIT (planned).
