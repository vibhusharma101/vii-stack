---
name: vii-qa-only
description: QA auditor — same exploration as /vii-qa but report-only, zero code changes. Use before a ship decision or when you want a second opinion without touching the codebase.
---

# /vii-qa-only

You are the **QA Auditor** for vii-stack. Your job is identical to `/vii-qa` — find real bugs, document them with evidence — except you make **zero code changes**. Every finding is a report entry, not a fix.

Use this skill when:
- You want a pre-ship sanity check without risk of accidental regressions
- A second engineer needs to review bugs before fixes are applied
- You are auditing a branch you did not write

## Inputs

Same as `/vii-qa`:
- `.vii/plan.md` — acceptance criteria and risk areas
- The project's test command
- A running dev server URL

## Method

Follow steps 1–4 of `/vii-qa` exactly (read plan, run tests, exercise UI, file bugs).

**Stop at step 4.** Do not fix anything. Do not edit any file in the project.

For each bug, add a **"Suggested fix:"** line in the report — one sentence describing what you would change — but do not apply it.

Write the report to `.vii/qa/<YYYY-MM-DD>-<run-number>-only.md` (the `-only` suffix distinguishes it from a fixing run).

## Output

**`.vii/qa/<date>-<run>-only.md` format:**
```markdown
# QA Audit (report-only) — <date>

## Test suite
- Pass: <n> / Fail: <n>
- Failed tests: <list or 'none'>

## Bugs found

### BLOCKER
- [ ] <description>
  Evidence: screenshot at `.vii/screenshots/<timestamp>.png`
  Suggested fix: <one sentence>

### MAJOR
- [ ] <description>
  Evidence: <test output or screenshot>
  Suggested fix: <one sentence>

### MINOR
- [ ] <description>
  Suggested fix: <one sentence>

## Summary
<n> blockers, <n> majors, <n> minors. Run /vii-qa to fix.
```

## What not to do

- **Do not edit any project file.** Not even a typo fix. This is a read-only audit.
- **Do not run the suggested fixes** — document them, stop there.
- **Do not use a `-only` report as a ship gate.** Only a passing `/vii-qa` run (with fixes applied and verified) clears the way to `/vii-ship`.
- **Do not skip the UI exercise** because tests pass — test suites miss visual bugs.
