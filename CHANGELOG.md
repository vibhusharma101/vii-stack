# Changelog

All notable changes to vii-stack are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Since vii-stack is a skill pack rather than a library, "breaking" means a
command was renamed or removed, or `setup.ps1` needs a manual step on upgrade.

## [Unreleased]

### Fixed
- **`setup.ps1` could discard an existing `~/.claude/settings.json`.** The merge
  read it with `ConvertFrom-Json -AsHashtable`, which only exists on PowerShell
  7+. On Windows PowerShell 5.1 — the version the README advertises as the
  floor — the call threw, a `catch` reset the result to an empty hashtable, and
  the file was rewritten with nothing but the vii-stack hooks, silently losing
  `model`, `permissions`, `env` and anything else the user had set. Parsing is
  now version-independent, unparseable JSON aborts the install instead of
  overwriting, and a timestamped backup is written before any rewrite.
- **`/vii-careful` blocked writing files that merely mention a destructive
  command.** Heredoc bodies were matched as if they were commands, so writing a
  doc containing `git reset --hard` in a "do not do this" line was refused.
  Heredoc bodies are now stripped before matching, while a destructive command
  on the same line still blocks.

### Added
- `bin/vii-hook-test.ps1` — 16 cases pinning `vii-careful-check` behaviour:
  real destructive commands block, prose mentioning them does not, and an
  acknowledged session bypasses.
- `bin/vii-setup-test.ps1` — end-to-end test of the `settings.json` merge
  against a throwaway `HOME`: unrelated keys survive, re-running does not
  duplicate hooks, and malformed JSON aborts without rewriting the file.
- CI runs both suites on **PowerShell 5.1 and 7**, since the two bugs above
  were 5.1-only and invisible to a 7-only test.
- `bin/vii-validate.ps1` — validates every `SKILL.md`: frontmatter present,
  `name:` matches its directory, no duplicate leaf names (which `setup.ps1`
  would silently overwrite when it flattens `skills/<stage>/<name>`), and every
  skill registered in both `README.md` and `CLAUDE.md`.
- `.github/workflows/validate.yml` — CI on push and PR to `develop`/`main`:
  runs the validator, a `setup.ps1 -DryRun`, and a parse check over every `.ps1`.
- `/vii-upgrade` — pulls the latest vii-stack and re-runs `setup.ps1`, so
  installed skills can be refreshed without remembering the clone path.
- `VERSION`, `CHANGELOG.md`, and `CONTRIBUTING.md`.

### Fixed
- README claimed the installer syncs 28 skills; it syncs all of them (32 as of
  this release). The validator now fails CI when that count drifts again.

## [0.2.0] — 2026-06-17

### Added
- `/vii-lean` — lean coder mode. Enforces the YAGNI ladder before any code is
  written, at three intensities (`lite`, `full`, `ultra`). Sentinel-based, like
  `/vii-cheap`.
- `/vii-lean-review` — complexity-only diff audit that finds what to delete.
  Separate from `/vii-review`, which stays on correctness.
- `/vii-cheap` — token-saving mode. Routes read-heavy shell commands through
  [RTK](https://github.com/rtk-ai/rtk), compressing output 50-90% before it
  enters context. Per-project, persists across sessions.
- `LICENSE` (MIT), linked from the README.

### Fixed
- `/vii-cheap` now falls back to `~/.rtk/bin/rtk.exe` when `rtk` is not on PATH,
  instead of silently enabling a no-op.

## [0.1.0] — 2026-06

Initial release: the full `Think → Plan → Build → Review → Test → Ship → Reflect`
workflow as 29 slash commands, plus the supporting runtime.

### Added
- **Think** — `/vii-office-hours`.
- **Plan** — `/vii-autoplan`, `/vii-plan-eng`, `/vii-plan-ceo`,
  `/vii-plan-design`, `/vii-plan-devex`.
- **Build** — `/vii-design-consult`, `/vii-design-shotgun`, `/vii-design-html`.
- **Review** — `/vii-review`, `/vii-investigate`, `/vii-design-review`,
  `/vii-devex-review`.
- **Test** — `/vii-browse`, `/vii-qa`, `/vii-qa-only`.
- **Ship** — `/vii-ship`, `/vii-land`, `/vii-canary`, `/vii-benchmark`,
  `/vii-doc-release`.
- **Reflect** — `/vii-learn`, `/vii-retro`.
- **Security** — `/vii-cso`.
- **Safety** — `/vii-careful`, `/vii-freeze`, `/vii-guard`, `/vii-unfreeze`,
  enforced by blocking PreToolUse hooks rather than prompt text alone.
- **vii-brain** — cross-project memory store on PGLite (embedded Postgres) at
  `~/.vii/vii-brain.db`, with a `bin/vii-brain.ps1` CLI.
- `setup.ps1` — idempotent installer: syncs skills to `~/.claude/skills/`,
  merges the command block into `~/.claude/CLAUDE.md`, registers hooks and the
  Playwright MCP server in `~/.claude/settings.json`, and initialises vii-brain.

[Unreleased]: https://github.com/vibhusharma101/vii-stack/compare/v0.2.0...HEAD
[0.2.0]: https://github.com/vibhusharma101/vii-stack/releases/tag/v0.2.0
[0.1.0]: https://github.com/vibhusharma101/vii-stack/releases/tag/v0.1.0
