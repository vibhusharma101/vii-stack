---
name: vii-landing-report
description: >
  Read-only dashboard of what is ready to land — open PRs with CI and review
  state, unpushed branches, how far each sits behind the base, and what is
  blocking each one. Use when the user says "landing report", "ship queue",
  "what's ready to merge", "what's in flight", "status of my PRs", or invokes
  /vii-landing-report. Args: mine (default) | all.
---

# /vii-landing-report

You are answering one question: **what can land right now, and what is stopping
the rest?** Everything in the output serves that. This is a dashboard, not a
release — it changes nothing.

Order by readiness, not by date. The user wants to know what to do next, and
the top of the list should be the thing to do.

## Arguments

- `mine` (default) — PRs authored by the current user.
- `all` — every open PR on the repo.

## Inputs

```powershell
gh pr list --json number,title,headRefName,isDraft,mergeable,reviewDecision,statusCheckRollup,updatedAt
git branch -vv                      # local branches and their tracking state
git log --oneline origin/<base>..<branch>
```

If `gh` is missing or unauthenticated, say so plainly and fall back to the
local-only half of the report. Do not present a local-only view as complete.

## Method

1. **Collect open PRs** for the requested scope, with CI rollup and review
   decision.

2. **Find work not yet in a PR**: local branches ahead of their upstream, and
   branches with no upstream at all. These are the easiest things to lose, so
   they belong in the report even though they are not PRs.

3. **Compute staleness** — commits behind the base branch. A PR far behind is a
   merge conflict that has not happened yet.

4. **Classify each item by what is blocking it**, in this order. The first
   match wins, because it is what must be dealt with first:

   | State | Meaning |
   |-------|---------|
   | `READY` | CI green, approved, mergeable, not draft |
   | `CI-RED` | Checks failing |
   | `CI-PENDING` | Checks still running |
   | `NEEDS-REVIEW` | Green but unreviewed |
   | `CHANGES-REQ` | Review requested changes |
   | `CONFLICT` | Not mergeable |
   | `DRAFT` | Explicitly a draft |
   | `UNPUSHED` | Local commits with no PR |

5. **Sort `READY` first**, then by how cheap the block is to clear.

6. **Report inline.** Do not write an artifact — this is a live view and a
   stale copy on disk is worse than none.

## Output format

```
landing report: <repo>  (base: <base>)

READY
  #18  register vii-stack hooks first          green, approved, 0 behind
       -> gh pr merge 18 --squash --delete-branch

BLOCKED
  #21  add context skills                      CI-RED: installer (5.1)
       -> gh run view <id> --log-failed
  #19  design token pass                       NEEDS-REVIEW, 4 behind
       -> gh pr merge is fine once reviewed; rebase if conflicts appear

UNPUSHED
  feature/spike-cache    3 commits, no upstream
       -> git push -u origin feature/spike-cache

nothing else in flight.
```

Every line gets the next command. A dashboard that reports state without the
action is a status page, and the user already has one of those on GitHub.

## Integration with vii-stack

- Upstream of `/vii-ship` (which pushes and opens a PR) and `/vii-land` (which
  merges and deploys). This one decides *which* PR to hand to `/vii-land`.
- `READY` here is necessary but not sufficient for `/vii-land` — that skill
  runs its own checks and can still refuse.
- Pairs with `/vii-canary` after a land.

## What not to do

- **Do not merge, push, rebase, or close anything.** Read-only, without
  exception. The user reads the report and decides.
- **Do not call a PR `READY` on green CI alone.** Approval, mergeability and
  draft state all count.
- **Do not hide the unpushed branches.** Work that exists only on this machine
  is the most fragile thing in the report.
- **Do not present a local-only report as complete** when `gh` is unavailable.
  Say which half is missing.
- **Do not write the report to `.vii/`.** It goes stale within minutes.
