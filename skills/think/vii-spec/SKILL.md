---
name: vii-spec
description: >
  Turn a vague intent into a precise, executable spec with acceptance criteria
  sharp enough to test — then optionally file it as a GitHub issue. Use when
  the user says "spec this out", "write up a ticket", "file an issue", "turn
  this into a backlog item", "make this concrete", or invokes /vii-spec.
  Args: an optional one-line intent. Add `issue` to file it via gh.
---

# /vii-spec

You are turning an intent into a spec someone could implement without asking
you a single follow-up question. The test of a finished spec is blunt: **could
a competent stranger build this and could you objectively tell whether they
succeeded?** If either answer is no, the spec is not done.

A spec is smaller than a plan. `/vii-office-hours` interrogates whether an idea
should exist; `/vii-plan-eng` decides which files change. This sits between:
what exactly is being built, and how you will know it works.

## Arguments

- _(no arg)_ — spec the thing under discussion.
- `<intent>` — a one-line description to spec.
- `issue` — after writing the spec, file it as a GitHub issue via `gh`.

## Inputs

- `.vii/brief.md` from `/vii-office-hours`, if it exists — do not re-ask what it
  already answers.
- The repo, for what exists today: current behavior, relevant files, prior art.
- The user, for what only they know.

## Method

1. **State the intent in one sentence**, in the user's terms. If you cannot, you
   do not understand it yet — ask before going further.

2. **Find the ambiguity and resolve it.** Walk the intent looking for every
   place two competent people would build different things. For each, either
   resolve it from the repo, or ask. Ask in one batch, not a drip. Typical
   sources: what happens on the empty case, what happens on failure, who is
   allowed to do this, what happens to existing data, and whether this is
   additive or replaces something.

3. **Write acceptance criteria that can fail.** Each one is a statement that is
   objectively true or false about a built system. This is where specs usually
   go soft:

   | Weak | Strong |
   |------|--------|
   | "Login should be secure" | "Six failed logins from one IP in 60s returns 429; the counter resets after 15 min" |
   | "Fast enough" | "p95 renders under 200ms with 10k rows" |
   | "Handles errors gracefully" | "A 5xx from the API shows the cached value plus a stale badge; it never shows an empty table" |

4. **State what is explicitly out of scope.** A spec without a boundary grows
   one silently during implementation. Name the adjacent things you are *not*
   doing.

5. **Write `.vii/spec/<slug>.md`** in the format below.

6. **If `issue` was passed**, file it:
   ```powershell
   gh issue create --title "<title>" --body-file .vii/spec/<slug>.md
   ```
   Report the URL. Never file an issue unless `issue` was explicitly passed —
   filing is public and hard to take back.

## Output format

```markdown
# <title>

**Intent:** <one sentence, user's terms>

## Today
<what happens now — the behavior being changed, or "does not exist">

## Proposed
<what happens after — behavior, not implementation>

## Acceptance criteria
- [ ] <objectively checkable statement>
- [ ] <objectively checkable statement>

## Out of scope
- <adjacent thing deliberately not being done>

## Open questions
- <anything genuinely unresolved, with the assumption being made meanwhile>

## Notes
<constraints, prior art, links — anything the implementer needs and would not find>
```

## Integration with vii-stack

- Reads `.vii/brief.md` from `/vii-office-hours` when present.
- Feeds `/vii-plan-eng`, which turns the spec into a file-level change list.
  The spec says *what*; the plan says *where*.
- `/vii-review` and `/vii-qa` should check the diff against the acceptance
  criteria — which only works if step 3 produced criteria that can fail.

## What not to do

- **Do not write implementation.** No file names, no function signatures, no
  schema. That is `/vii-plan-eng`. A spec that names files is a plan wearing a
  spec's title.
- **Do not write acceptance criteria that cannot fail.** "Works correctly",
  "is intuitive", "is performant" are not criteria. If you cannot make one
  checkable, move it to Notes and say why.
- **Do not invent answers to resolve ambiguity.** Ask, or state the assumption
  in Open questions where it is visible. A buried guess surfaces as a bug.
- **Do not file an issue without the `issue` argument.**
- **Do not spec what is already obvious and small.** A one-line fix does not
  need acceptance criteria. Say so and move on.
