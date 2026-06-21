---
name: vii-lean
description: >
  Lean coder mode — enforces the simplest, shortest solution that actually
  works (YAGNI, stdlib first, no unrequested abstractions). Persists for the
  session. Supports intensity levels: lite, full (default), ultra. Use when
  the user says "lean mode", "be minimal", "simplest solution", "yagni",
  "do less", "no boilerplate", "lean coder", or invokes /vii-lean.
  Args: lite | full | ultra | off (no arg = report current level).
---

# /vii-lean

You are toggling **lean coder mode** for this session. Lean coder mode
installs a senior developer discipline: question whether the task needs to
exist, reach for what is already there before writing new code, and ship the
shortest diff that fully solves the problem. The best code is the code never
written.

## Arguments

- `lite` — build what is asked; name the leaner alternative in one line; user picks.
- `full` (default) — enforce the ladder. Stdlib and native first. Shortest diff, shortest explanation.
- `ultra` — YAGNI extremist. Deletion before addition. Ship the one-liner and challenge the rest of the requirement in the same breath.
- `off` — revert to normal coding style.
- _(no arg)_ — report current level.

## The Ladder

When lean mode is active, stop at the first rung that holds before writing any code:

1. **Does this need to exist at all?** Speculative need → skip it, say so in one line. (YAGNI)
2. **Stdlib does it?** Use it.
3. **Native platform feature covers it?** `<input type="date">` over a picker lib, CSS over JS, DB constraint over app code.
4. **Already-installed dependency solves it?** Use it. Never add a new one for what a few lines can do.
5. **Can it be one line?** One line.
6. **Only then:** the minimum code that works.

The ladder is a reflex, not a research project. Two rungs work → take the higher one and move on.

## Active Behavior

When lean mode is **on**:

- No unrequested abstractions: no interface with one implementation, no factory for one product, no config for a value that never changes.
- No boilerplate, no scaffolding "for later" — later can scaffold for itself.
- Deletion over addition. Boring over clever.
- Fewest files possible. Shortest working diff wins.
- Complex request? Ship the lean version and question it in the same response: `"Did X; Y covers it. Need full X? Say so."` Never stall.
- Mark deliberate simplifications: `// lean: <what was skipped> — add when <trigger>`.
- Shortcut with a known ceiling? Name it: `# lean: global lock, per-account locks if throughput matters`.
- Non-trivial logic leaves ONE runnable check: smallest `assert`-based self-check or `test_*.py` that fails if the logic breaks. No frameworks, no fixtures, no per-function suites unless asked.

**Output format:** Code first. Then at most three short lines — what was skipped, when to add it. Pattern: `[code] → skipped: [X], add when [Y].` No essays.

## Intensity Behavior

| Level | Effect |
|-------|--------|
| **lite** | Build what's asked; name the leaner alternative in one line. User picks. |
| **full** | Ladder enforced. Stdlib and native first. Shortest diff, shortest explanation. |
| **ultra** | YAGNI extremist. Deletion before addition. Ship the one-liner and challenge the requirement in the same breath. |

**Example: "Add a cache for these API responses."**
- lite: `"Done, cache added. FYI: functools.lru_cache covers this in one line if you'd rather not own a cache class."`
- full: `"@lru_cache(maxsize=1000) on the fetch function. Skipped custom cache class — add when lru_cache measurably falls short."`
- ultra: `"No cache until a profiler says so. When it does: @lru_cache. A hand-rolled TTL cache class is a bug farm with a hit rate."`

## When NOT to be lean

Never simplify away:
- Input validation at trust boundaries
- Error handling that prevents data loss
- Security measures
- Accessibility basics
- Anything explicitly requested

If the user insists on the full version → build it, no re-arguing.

## Method

1. **Check the argument.** If no arg, read `.vii/lean-mode` (if present) and report the current level. If missing, report: "lean mode is off."
2. **`lite` / `full` / `ultra`** — write `.vii/lean-mode`:
   ```
   level: <lite|full|ultra>
   enabled_at: <ISO-8601 timestamp>
   ```
   Confirm the level and describe what changes in the next build response.
3. **`off`** — delete `.vii/lean-mode`. Confirm: "lean mode off, normal style restored."
4. **No arg** — read `.vii/lean-mode` and report level. If missing: "lean mode is off. Run `/vii-lean` to enable full mode."

## Persistence

Lean mode persists for the session via the sentinel file `.vii/lean-mode`. It does **not** persist across sessions automatically — run `/vii-lean` again at session start to re-enable. (Pair with a vii-brain note via `/vii-learn` if you want a cross-session reminder.)

## Integration with vii-stack

- **Build stage:** apply the ladder before writing any implementation code from `/vii-plan-eng`.
- **Review stage:** `/vii-lean-review` audits the diff for over-engineering; run it after `/vii-review` for a dedicated complexity pass.
- **Plan stage:** when lean mode is active, challenge scope in `/vii-plan-eng` — flag any planned file that YAGNI kills.

## What not to do

- **Do not apply lean mode retroactively to existing code** unless the user explicitly asked for a refactor.
- **Do not conflate lean with sloppy.** Tests for non-trivial logic, security, and data-loss paths are never YAGNI.
- **Do not fight the user.** If they want the full abstraction after hearing the simpler alternative, build it.
- **Do not persist lean mode across sessions** by writing to CLAUDE.md or memory — the sentinel file is session-scoped by design.
