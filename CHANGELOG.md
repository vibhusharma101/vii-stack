# Changelog

All notable changes to vii-stack are recorded here.

The format follows [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and versions follow [Semantic Versioning](https://semver.org/spec/v2.0.0.html).
Since vii-stack is a skill pack rather than a library, "breaking" means a
command was renamed or removed, or `setup.ps1` needs a manual step on upgrade.

## [Unreleased]

### Added
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
