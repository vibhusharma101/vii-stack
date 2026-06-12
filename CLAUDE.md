<!--
This block is appended to ~/.claude/CLAUDE.md by setup.ps1.
Everything between BEGIN/END markers is owned by vii-stack and rewritten on re-install.
-->

<!-- BEGIN vii-stack -->
## vii-stack

You have the **vii-stack** skill pack installed. It encodes a `Think → Plan → Build → Review → Test → Ship → Reflect` workflow as slash commands. Prefer these skills over ad-hoc approaches when the task fits a stage.

**Stage artifacts** live under `.vii/` in the current project. Each stage reads the previous stage's artifact.

**Available commands:**

- Think: `/vii-office-hours`
- Plan: `/vii-autoplan`, `/vii-plan-ceo`, `/vii-plan-eng`, `/vii-plan-design`, `/vii-plan-devex`
- Build: `/vii-design-consult`, `/vii-design-shotgun`, `/vii-design-html`
- Review: `/vii-review`, `/vii-investigate`, `/vii-design-review`, `/vii-devex-review`
- Test: `/vii-qa`, `/vii-qa-only`, `/vii-browse`
- Ship: `/vii-ship`, `/vii-land`, `/vii-canary`, `/vii-benchmark`, `/vii-doc-release`
- Reflect: `/vii-retro`, `/vii-learn`
- Security: `/vii-cso`
- Safety: `/vii-careful`, `/vii-freeze`, `/vii-guard`, `/vii-unfreeze`
- Token-saving: `/vii-cheap`

**Browsing:** use `/vii-browse` (Playwright MCP) for any web navigation. Screenshots land in `.vii/screenshots/`.

**Memory:** `/vii-learn` writes to both Claude Code's auto-memory and **vii-brain** (cross-project persistent store at `~/.vii/vii-brain.db/`). Query vii-brain at the start of long sessions to recall prior context.

**Safety hooks are enforced** — `/vii-careful` must be acknowledged before destructive shell commands; `/vii-freeze <dir>` locks edits to a subtree. Hooks block; skill prompts only advise.

**Cheap mode:** `/vii-cheap on` routes read-heavy shell commands (`git status/log/diff`, `cargo test`, `pytest`, `ls`, `grep`, …) through [`rtk`](https://github.com/rtk-ai/rtk) so their output is compressed 50-90% before it enters context. Requires the `rtk` binary (`brew install rtk`). Per-project, persists across sessions; `/vii-cheap off` to disable, `/vii-cheap gain` for savings stats.
<!-- END vii-stack -->
