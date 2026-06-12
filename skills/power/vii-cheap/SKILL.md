---
name: vii-cheap
description: Toggle "cheap mode" - transparently route read-heavy shell commands (git status/log/diff, cargo test, pytest, ls, grep, etc.) through RTK (Rust Token Killer) so their output is compressed 50-90% before it reaches the model's context window. Use when the user says "cheap mode", "save tokens", "token saving", "run cheaper", or invokes /vii-cheap. Args: `on`, `off`, `status`, `ultra`, or `gain`.
---

# /vii-cheap

You are toggling **cheap mode** for the current project. Cheap mode wraps a
curated allowlist of read-only / diagnostic shell commands with
[`rtk`](https://github.com/rtk-ai/rtk) (Rust Token Killer), which compresses
their stdout/stderr before it is fed back into the context window. RTK reports
50-90% reduction on commands like `cargo test`, `git status`, `find`, and
`grep`.

The mechanism mirrors `/vii-careful` and `/vii-freeze`: a sentinel file plus a
PreToolUse hook. The hook is `bin/vii-cheap-rewrite.ps1`; the sentinel is
`.vii/cheap-mode`. When the sentinel exists **and** `rtk` is on PATH, the hook
rewrites matching Bash commands to `rtk <cmd>` via `hookSpecificOutput.updatedInput`.

## Arguments

- `on` (default) - turn cheap mode on for this project.
- `off` - turn it off.
- `status` - report current state (sentinel present? rtk installed?).
- `ultra` - turn on with `-u` ultra-compact output (maximum savings).
- `gain` - show RTK's token-savings analytics (`rtk gain`).

## Method

1. **Check rtk is installed.** Run `Get-Command rtk`. If missing, do **not**
   silently enable a no-op. Tell the user cheap mode needs the RTK binary and
   give the install options, then ask whether to proceed (the sentinel still
   works once they install it later):
   - Homebrew: `brew install rtk`
   - Cargo: `cargo install --git https://github.com/rtk-ai/rtk`
   - Script: `curl -fsSL https://raw.githubusercontent.com/rtk-ai/rtk/master/install.sh | sh`

   Do not run the install command yourself without the user confirming - it
   pulls and builds third-party software.

2. **`on` / `ultra`** - ensure `.vii/` exists, then write `.vii/cheap-mode`:

   ```
   mode: <on|ultra>
   enabled_at: <ISO-8601 timestamp>
   ```

   For `ultra`, the body must contain the word `ultra` (the hook keys off it to
   add `-u`). Confirm which commands are now auto-wrapped (see Reference).

3. **`off`** - delete `.vii/cheap-mode`. Confirm cheap mode is off; commands run
   raw again.

4. **`status`** - report: sentinel present or not, rtk installed or not, and
   whether ultra is active.

5. **`gain`** - run `rtk gain` and relay the savings summary. Mention
   `rtk gain --graph`, `--history`, `--daily`, and `--all --format json` for
   detail.

## What the hook wraps (and what it never touches)

Wrapped (read-only / diagnostic only):

- `git status`, `git log`, `git diff`, `git show`
- `cargo test|build|clippy|check`, `go test`
- `pytest`, `jest`, `vitest`, `rspec`, `rubocop`, `ruff`
- `tsc`, `eslint`, `prettier`, `golangci-lint run`
- `pnpm list`, `pip list`, `docker ps`
- `ls`, `grep`, `find`

Never touched:

- Write-side git verbs (`commit`, `push`, `add`, `pull`).
- Anything with a pipe `|`, redirect `<`/`>`, chain `&&`/`;`, or substitution `$()`.
- Commands already starting with `rtk`.
- Destructive commands (those remain governed by `/vii-careful`).

## Behavior notes to tell the user

- Wrapped commands are **auto-approved** by the hook (`permissionDecision:
  allow`) since the allowlist is read-only. This also means fewer permission
  prompts for those commands - a side benefit.
- Cheap mode is **per project** and **persists across sessions** (unlike
  `/vii-careful`, which is per session). Run `/vii-cheap off` to disable.
- This is independent of RTK's own global hook (`rtk init -g`). If the user
  wants RTK on for *every* tool everywhere, `rtk init -g` is the always-on
  route; `/vii-cheap` is the toggleable, project-scoped route.

## What not to do

- **Do not enable ultra by default.** `-u` is terser and occasionally drops
  context an agent might want; let the user opt in.
- **Do not widen the allowlist** by editing the hook to wrap arbitrary
  commands. RTK only safely handles known commands; wrapping unknown ones can
  error or mangle output.
- **Do not run the rtk install command** without explicit user confirmation.
