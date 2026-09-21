---
name: vii-plan-tune
description: >
  Tune how hard the planning stage interrogates you — how many clarifying
  questions /vii-office-hours, /vii-spec and the /vii-plan-* skills ask before
  producing output. Persists per project via .vii/question-level. Use when the
  user says "too many questions", "stop asking me that", "tune questions",
  "just build it", "ask me more", or invokes /vii-plan-tune.
  Args: low | normal | high | off (no arg = report current level).
---

# /vii-plan-tune

You are setting how much the planning stage interrogates the user before it
produces anything. The forcing questions in `/vii-office-hours` exist because
vague briefs produce wrong plans — but the right number of questions depends on
the user and the task, and a fixed number is wrong for both.

This is a dial, not a switch. Even at `low`, assumptions are still stated; they
are just stated instead of asked.

## Arguments

- `low` — ask only what would change the output. State every other assumption
  inline and keep moving.
- `normal` (default) — current behavior: ask what is genuinely ambiguous, in
  one batch.
- `high` — interrogate hard. Challenge scope, success metric, and the premise
  itself before producing anything.
- `off` — ask nothing. Produce the artifact entirely from stated assumptions,
  each one flagged so the user can correct it.
- _(no arg)_ — report the current level.

## The levels

| Level | Questions per stage | Behavior |
|-------|--------------------|----------|
| `off` | 0 | Everything inferred. Every assumption marked `assumed:`. |
| `low` | 0-1 | Only a question whose answer changes the artifact materially. |
| `normal` | 1-3, batched | Genuine ambiguity asked; routine judgment calls made. |
| `high` | 3-6, batched | Premise, scope, metric and boundaries all challenged. |

**In every level, including `off`:**
- An assumption that turns out wrong must be cheap to spot. Mark them.
- Never ask a question the repo answers. Read first, ask second.
- Never ask a question the user already answered in this session or in
  `.vii/brief.md`.
- Batch questions into one round. A drip of single questions is worse than
  three at once at any level.

## Method

1. **No arg** — read `.vii/question-level` and report. Missing → report
   `normal (default)`.

2. **`low` / `normal` / `high` / `off`** — write `.vii/question-level`:
   ```
   level: <low|normal|high|off>
   set_at: <ISO-8601 timestamp>
   ```
   Confirm the level and say concretely what changes: at `off`, "I will produce
   the brief from assumptions and mark each one"; at `high`, "I will challenge
   the premise before writing anything."

3. **`normal`** — delete the sentinel rather than writing it, so the default
   stays the default.

## When the level is overridden

Ask anyway, at any level, when:

- Proceeding on a wrong assumption would be **unsafe or destructive** — data
  loss, a public action, anything hard to reverse.
- The work would be **useless if the assumption is wrong**, not merely
  different. A wrong guess you can revise is a `low` question; a wrong guess
  that wastes the whole artifact is not.
- The user is the **only possible source** — a preference, a deadline, an
  external constraint not in the repo.

Say why you are overriding in one line. Do not silently ignore the setting.

## Integration with vii-stack

- Read by `/vii-office-hours`, `/vii-spec`, `/vii-autoplan` and the
  `/vii-plan-*` skills at the start of each run.
- Sibling of `/vii-lean` (how much code) and `/vii-cheap` (how many tokens).
  This one is how much dialogue.
- Per project and persists across sessions, like `/vii-cheap` and unlike
  `/vii-careful`.

## What not to do

- **Do not treat `off` as permission to guess silently.** Fewer questions means
  more *visible* assumptions, not fewer assumptions.
- **Do not apply this outside planning.** It does not license skipping a
  confirmation before a destructive or outward-facing action.
- **Do not ask the user to set a level.** Infer nothing; if they have not set
  one, `normal` applies.
- **Do not re-ask across stages.** `/vii-plan-eng` must not re-litigate what
  `/vii-office-hours` already settled in `.vii/brief.md`, at any level.
