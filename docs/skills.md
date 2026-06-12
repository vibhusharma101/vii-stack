# vii-stack Skills Reference

Every `/vii-*` slash command, its stage, what it reads, what it writes, and what Claude does when invoked.

Stages: **Think · Plan · Build · Review · Test · Ship · Reflect · Security · Power**

---

## Think

### `/vii-office-hours`
**Purpose:** Interrogate a fuzzy product idea with forcing questions before any planning starts.
**Reads:** user's free-text idea, GBrain entries tagged `product-context`.
**Writes:** `.vii/think/<topic>.md` containing: problem statement, target user, success metric, what we are *not* building, riskiest assumption.
**Behavior:** Claude asks 5–8 sharp questions one at a time (no batching), refuses to advance until each is answered, then synthesizes the brief.

---

## Plan

### `/vii-plan-ceo`
**Purpose:** Strategic scope challenge — is this the right thing to build?
**Reads:** `.vii/think/*.md`.
**Writes:** appends `## CEO Review` to `.vii/plan.md`.
**Modes:** `cut` (force a 50% scope cut), `expand` (what else should ship together), `kill` (is this worth doing at all), `default` (balanced).

### `/vii-plan-eng`
**Purpose:** Architecture + test plan for the chosen scope.
**Reads:** `.vii/think/*.md`, current repo structure.
**Writes:** `.vii/plan.md` with: file-level change list, new modules, test plan (what tests, what level), risk surface, rollback strategy.

### `/vii-plan-design`
**Purpose:** Audit the design dimensions before any pixels are pushed.
**Reads:** `.vii/plan.md`.
**Writes:** appends `## Design Review` with: typography scale, color/contrast targets, spacing system, component inventory, responsive breakpoints.

### `/vii-plan-devex`
**Purpose:** Will a developer onboarding to this 6 months later understand it?
**Reads:** `.vii/plan.md`, existing `README.md` / `CLAUDE.md`.
**Writes:** appends `## DevEx Review` listing missing docs, unclear naming, hidden setup steps.
**Modes:** `cold-start` (assume zero context), `warm` (assume repo familiarity), `default`.

### `/vii-autoplan`
**Purpose:** One-shot — run CEO → eng → design → devex in sequence.
**Behavior:** Calls each plan skill, halts on user request to revise.

---

## Build

### `/vii-design-consult`
**Purpose:** Build a design system from scratch when none exists.
**Writes:** `design-tokens.css` (or framework-specific equivalent), `.vii/design/system.md`.
**Behavior:** Asks for 2–3 reference sites/screenshots, derives tokens, generates a component vocabulary.

### `/vii-design-shotgun`
**Purpose:** Generate 4–6 visually distinct mockup variants for a screen.
**Writes:** `.vii/mockups/v1.html` … `v6.html` (static HTML+CSS, no JS).
**Behavior:** Each variant explores a different visual axis (density, hierarchy, color temperature, motif). User picks one.

### `/vii-design-html`
**Purpose:** Convert a chosen mockup into framework-native production HTML/components.
**Reads:** `.vii/mockups/<chosen>.html`.
**Writes:** components in the project's actual framework dir (auto-detected: React/Svelte/Vue/plain HTML).
**Behavior:** Preserves the design tokens from `/vii-design-consult`; refuses to inline magic numbers.

---

## Review

### `/vii-review`
**Purpose:** Staff-engineer code review of the current diff, with auto-fixes for trivial issues.
**Reads:** `git diff` vs base branch, `.vii/plan.md`.
**Writes:** `.vii/review/<sha>.md` with severity-tagged findings. Auto-applies trivial fixes (formatting, dead code) and reports the rest.

### `/vii-investigate`
**Purpose:** Root-cause debugging methodology — five-whys, hypothesis log, no shortcuts.
**Writes:** `.vii/investigate/<issue>.md` with: symptom, hypotheses tried, evidence, root cause, fix scope.

### `/vii-design-review`
**Purpose:** Live design audit — opens the built page via `/vii-browse`, screenshots, critiques.
**Reads:** running dev server.
**Writes:** `.vii/review/design-<sha>.md` + annotated screenshots.

### `/vii-devex-review`
**Purpose:** Cold-start the project from a clean clone and document every friction point.
**Behavior:** Drives `git clone` → install → first-run in a sandbox; writes a friction log.

---

## Test

### `/vii-qa`
**Purpose:** Find bugs, fix them, verify the fixes.
**Reads:** `.vii/plan.md` (acceptance criteria).
**Writes:** `.vii/qa/<run>.md`, code edits for bugs found.
**Behavior:** Runs the project's tests, exercises the UI via `/vii-browse`, files internal bug reports, fixes, re-runs.

### `/vii-qa-only`
**Purpose:** Same exploration as `/vii-qa` but **report only**, no code changes. For pre-ship sanity check.

### `/vii-browse`
**Purpose:** Real Chromium browsing via Playwright MCP.
**Behavior:** Navigates, takes screenshots, extracts DOM/console logs. Screenshots saved to `.vii/screenshots/<timestamp>.png` so other skills can pick them up.

---

## Ship

### `/vii-ship`
**Purpose:** Pre-push gauntlet — sync with main, run tests, run `/vii-cso`, push, open PR.
**Behavior:** Refuses to push if tests fail or CSO flags HIGH severity. PR title/body drawn from `.vii/plan.md` and the diff.

### `/vii-land`
**Purpose:** Merge the PR, trigger deploy, verify production responds correctly.
**Reads:** PR URL.
**Behavior:** Merges (squash by default), waits for deploy, hits a healthcheck URL, reports.

### `/vii-canary`
**Purpose:** Post-deploy monitoring loop — watches error rates / latency / logs for N minutes.
**Behavior:** Polls the project-configured monitoring endpoint; auto-rolls-back if thresholds breach (if rollback script exists).

### `/vii-benchmark`
**Purpose:** Capture Core Web Vitals + load-time baseline before/after a change.
**Writes:** `.vii/benchmark/<sha>.json`.

### `/vii-doc-release`
**Purpose:** Update README, CHANGELOG, and any release notes to reflect what just shipped.
**Reads:** merged PR, `.vii/plan.md`.

---

## Reflect

### `/vii-retro`
**Purpose:** Weekly retrospective.
**Reads:** GBrain entries for the past 7 days, `.vii/review/*`, `.vii/qa/*`.
**Writes:** `.vii/retro/<YYYY-WW>.md` with: what shipped, what slipped, recurring failure modes, one process change to try next week.

### `/vii-learn`
**Purpose:** Manage persistent memory.
**Behavior:** Reads/writes both Claude's auto-memory (`~/.claude/projects/.../memory/`) AND GBrain. User-facing commands: `add`, `remove`, `list`, `search`.

---

## Security

### `/vii-cso`
**Purpose:** OWASP Top 10 + STRIDE audit on the current diff.
**Reads:** `git diff`, dependency manifest, env-var usage.
**Writes:** `.vii/security/<sha>.md` with severity-tagged findings. Blocks `/vii-ship` if HIGH severity unresolved.

---

## Power (safety)

### `/vii-careful`
**Purpose:** Toggle destructive-command warnings for the session.
**Mechanism:** Sets a sentinel file `.vii/careful-acked-<sessionid>`. The PreToolUse hook (`bin/vii-careful-check.ps1`) blocks `rm -rf`, `git reset --hard`, `git push --force`, `DROP TABLE`, etc. unless this file exists.

### `/vii-freeze <dir>`
**Purpose:** Lock all Edit/Write/NotebookEdit operations to a single directory subtree.
**Mechanism:** Writes `.vii/freeze` containing the locked path. The PreToolUse hook (`bin/vii-freeze-check.ps1`) rejects any file edit outside that subtree.

### `/vii-guard <dir>`
**Purpose:** Shorthand for `/vii-careful` + `/vii-freeze <dir>`.

### `/vii-unfreeze`
**Purpose:** Removes `.vii/freeze`.

---

## Token-saving

### `/vii-cheap`
**Purpose:** Toggle "cheap mode" — route read-heavy shell commands through [RTK](https://github.com/rtk-ai/rtk) so their output is compressed 50-90% before it reaches the context window.
**Mechanism:** Writes the sentinel `.vii/cheap-mode`. The PreToolUse hook (`bin/vii-cheap-rewrite.ps1`) rewrites a conservative allowlist of read-only commands (`git status/log/diff`, `cargo test`, `pytest`, `ls`, `grep`, …) to `rtk <cmd>` via `hookSpecificOutput.updatedInput`, but only when `rtk` is on PATH. Write commands, pipelines, and chains are never wrapped.
**Args:** `on` (default), `off`, `status`, `ultra` (adds `-u`), `gain` (runs `rtk gain` for savings stats).
**Requires:** the `rtk` binary — `brew install rtk`, `cargo install --git https://github.com/rtk-ai/rtk`, or the install script. Per-project; persists across sessions.

---

## Stage → skill cheat sheet

| Stage   | Primary command            | Alt / sub-commands                                       |
|---------|----------------------------|----------------------------------------------------------|
| Think   | `/vii-office-hours`        | —                                                        |
| Plan    | `/vii-autoplan`            | `/vii-plan-ceo`, `/vii-plan-eng`, `/vii-plan-design`, `/vii-plan-devex` |
| Build   | `/vii-design-shotgun`      | `/vii-design-consult`, `/vii-design-html`                |
| Review  | `/vii-review`              | `/vii-investigate`, `/vii-design-review`, `/vii-devex-review`, `/vii-cso` |
| Test    | `/vii-qa`                  | `/vii-qa-only`, `/vii-browse`                            |
| Ship    | `/vii-ship`                | `/vii-land`, `/vii-canary`, `/vii-benchmark`, `/vii-doc-release` |
| Reflect | `/vii-retro`               | `/vii-learn`                                             |
| Safety  | `/vii-guard`               | `/vii-careful`, `/vii-freeze`, `/vii-unfreeze`           |
| Tokens  | `/vii-cheap`               | `/vii-cheap on|off|status|ultra|gain`                   |
