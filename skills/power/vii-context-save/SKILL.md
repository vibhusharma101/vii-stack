---
name: vii-context-save
description: >
  Snapshot the working state of this session to .vii/context/ — what you are
  doing, why, what is half-done, and the exact next step — so a future session
  can resume without re-deriving it. Use when the user says "save progress",
  "save my work", "save state", "checkpoint this", "I'm stopping for today",
  "context save", or invokes /vii-context-save. Args: an optional title.
---

# /vii-context-save

You are writing a checkpoint of the current session so a later session can pick
it up cold. The reader is a Claude instance with **no memory of this
conversation** and a user who has forgotten the details. Write for that reader.

The failure mode this guards against is not losing files — git holds those. It
is losing the *reasoning*: which approach was already tried and abandoned, what
the half-finished edit was meant to become, and what the next command should be.

## Arguments

- _(no arg)_ — infer a title from the work in progress.
- `<title>` — use it verbatim as the checkpoint title.

## Inputs

- `git status --porcelain` and `git diff` — what is actually uncommitted.
- `git log --oneline -10` — what landed recently.
- The current branch, and its base.
- `.vii/plan.md`, `.vii/review/`, `.vii/qa/` — whichever stage artifacts exist.
- The conversation itself: decisions made, approaches rejected, open questions.

## Method

1. **Collect the mechanical state** first — branch, uncommitted files, recent
   commits, which stage artifacts exist. This part is cheap and always correct.

2. **Then write down what git cannot show.** This is the whole point of the
   skill, so spend the effort here:
   - What the user was trying to achieve, in their terms.
   - Decisions made *and the reason*, especially ones that look arbitrary from
     the diff alone.
   - Approaches tried and rejected, with why. A future session that re-tries a
     dead end has wasted the checkpoint.
   - What is half-done: a file edited but not wired up, a test written but not
     run, a fix applied but not verified.
   - Open questions the user has not answered yet.

3. **Write the next step as a command, not a sentiment.** `Run
   .\bin\vii-setup-test.ps1 and fix the ordering assertion` is resumable.
   "Continue working on the hooks" is not.

4. **Write to `.vii/context/<timestamp>-<slug>.md`** using the format below,
   and update `.vii/context/latest.md` to point at it (a copy, not a symlink —
   symlinks are unreliable on Windows without developer mode).

5. **Record a one-line pointer in vii-brain** so the checkpoint is findable from
   another project:
   ```powershell
   bin/vii-brain.ps1 add process "context saved: <title> (<branch>)"
   ```

6. Report the path written and the next step, in two lines. Do not restate the
   whole checkpoint back to the user — they were there.

## Output format

```markdown
# <title>

- **Saved:** <ISO-8601>
- **Branch:** <branch> (base: <base>)
- **Stage:** <which vii-stack stage this work is in, if any>

## Goal
<what the user is trying to achieve, in their terms — 1-3 lines>

## State
- **Committed:** <recent relevant commits, one line each>
- **Uncommitted:** <file: what the change is meant to do>
- **Half-done:** <started but not finished, and what "finished" means>

## Decisions
- <decision> — because <reason>

## Rejected
- <approach> — because <reason it failed>

## Open questions
- <question the user has not answered>

## Next step
```
<the exact command or edit to start with>
```
```

Omit any section that has nothing in it. An empty **Rejected** heading teaches
the next session nothing; leaving it out is honest.

## Integration with vii-stack

- Pairs with `/vii-context-restore`, which reads `.vii/context/latest.md`.
- Different from `/vii-learn`: this captures *this task's* transient state and
  is disposable once the work lands. `/vii-learn` captures durable lessons worth
  carrying into unrelated projects. When something learned here is general,
  write it to vii-brain with `/vii-learn` as well — the checkpoint will be
  deleted, the lesson should not be.
- `.vii/` is gitignored by default, so checkpoints stay local. Say so if the
  user seems to expect a teammate to read it.

## What not to do

- **Do not commit, stash, or clean anything.** A checkpoint records the mess; it
  does not tidy it. Tidying is what loses the half-finished state.
- **Do not paste the diff into the checkpoint.** Git has the diff. Record what
  the diff *means* and what is missing from it.
- **Do not write a checkpoint that only restates `git status`.** If the
  Decisions, Rejected, and Half-done sections are all empty, say plainly that
  there was nothing worth checkpointing rather than writing a hollow file.
- **Do not overwrite an existing checkpoint.** Each save is a new timestamped
  file; only `latest.md` is replaced.
