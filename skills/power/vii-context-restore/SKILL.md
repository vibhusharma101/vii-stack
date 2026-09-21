---
name: vii-context-restore
description: >
  Resume from a checkpoint written by /vii-context-save — reload the goal,
  decisions, rejected approaches and next step, then verify the repo still
  matches what was saved. Use when the user says "where was I", "resume",
  "pick up where I left off", "restore context", "what was I doing", or
  invokes /vii-context-restore. Args: latest (default) | list | <file>.
---

# /vii-context-restore

You are resuming work from a checkpoint. Your job is to rebuild enough context
to take the next step correctly — and, critically, to notice when the world has
moved on since the checkpoint was written.

A checkpoint is a claim about the past. The repo is the present. When they
disagree, the repo wins and the user needs to hear about it.

## Arguments

- _(no arg)_ / `latest` — restore `.vii/context/latest.md`.
- `list` — list available checkpoints with title and date. Restore nothing.
- `<file>` — restore a specific checkpoint from `.vii/context/`.

## Inputs

- `.vii/context/latest.md`, or the named checkpoint.
- The live repo: current branch, `git status --porcelain`, `git log --oneline`.

## Method

1. **Read the checkpoint.** If `.vii/context/` is empty or missing, say so and
   offer `/vii-context-save` for next time. Do not invent a reconstruction from
   git history alone and present it as a restored checkpoint.

2. **Verify it against reality before presenting it.** Check each of:
   - Is the branch from the checkpoint still checked out? Does it still exist?
   - Are the files listed as uncommitted still dirty — or were they committed,
     reverted, or stashed since?
   - Has the base branch moved? (`git log --oneline HEAD..origin/<base>`)
   - Do the files the checkpoint refers to still exist?

3. **Report the drift explicitly.** This is the part that earns the skill:
   ```
   drift: auth.ts was uncommitted at save time, now committed in a1b2c3d
   drift: base branch develop has moved 4 commits ahead
   ```
   No drift → say `no drift` in one line and move on.

4. **Present the restored context** compactly: goal, where things stood,
   decisions, rejected approaches, open questions, next step. Keep decisions and
   rejected approaches verbatim — paraphrasing them is how a dead end gets
   retried.

5. **Restate the next step as a command**, adjusted for any drift you found. If
   drift invalidated the next step, say that and propose a corrected one rather
   than reading out a stale instruction.

6. **Do not start the work.** Restoring is a read. End by asking whether to
   proceed, unless the user's message already told you to continue.

## Output format

```
restored: <title>
  saved:   <when> on <branch>
  drift:   <one line per divergence, or "none">

goal:     <1-2 lines>
decided:  <decisions, verbatim>
rejected: <approaches already ruled out, verbatim>
open:     <unanswered questions>

next step:
  <command>
```

## Integration with vii-stack

- Reads what `/vii-context-save` writes.
- If the checkpoint names a stage, point at the right next command —
  a checkpoint mid-review resumes at `/vii-review`, not `/vii-office-hours`.
- For cross-project memory rather than this task's state, query vii-brain:
  `bin/vii-brain.ps1 search "<topic>"`.

## What not to do

- **Do not present a checkpoint as current without verifying it.** A stale
  checkpoint read out confidently is worse than no checkpoint, because it
  sounds authoritative.
- **Do not silently drop the Rejected section.** Those approaches were paid for
  once already.
- **Do not modify the repo** — no checkout, no stash pop, no re-applying a
  half-finished edit. Restore is read-only; the user decides what to resume.
- **Do not delete the checkpoint after restoring.** The work may not finish this
  session either.
