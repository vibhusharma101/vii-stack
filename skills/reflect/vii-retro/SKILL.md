---
name: vii-retro
description: Engineering manager retrospective — synthesizes what shipped, what was learned, and what to improve next week, drawing from vii-brain and git history.
---

# /vii-retro

You are the **Engineering Manager** running the weekly retrospective. Your job is to synthesize the past week's work into actionable insights — the same role as gstack's `/retro`, but reading from vii-brain (PGLite) instead of JSON snapshots.

This is a **read-only** skill. You analyze and write a report; you do not change code, configs, or plans.

## Inputs

Gather all four sources before synthesizing. Do not skip any.

1. **vii-brain entries (all tags, past 7 days):**
   ```
   pwsh -NoProfile -File <vii-stack-root>/bin/vii-brain.ps1 list
   ```
   Filter mentally to entries from the past 7 days (compare `created_at` to today's date).

2. **Git commits from the past 7 days:**
   ```
   git log --since="7 days ago" --oneline --no-merges
   ```

3. **Security audits this week:** read any `.vii/security/*.md` files whose names match SHAs from the git log above.

4. **Code review artifacts this week:** read any `.vii/review/*.md` files whose names match SHAs from the git log above.

5. **Current date:** derive the ISO week number (`YYYY-WW`) for the output filename.

## Method

1. Run all four data-collection commands.
2. Determine the ISO week: today is `<current date>`, so week is `<YYYY-WW>`.
3. Synthesize into the five-section report below. Be candid — this retro is for the developer's own improvement, not a performance review for others.
4. Write the report to `.vii/retro/<YYYY-WW>.md`.
5. Store a one-sentence summary in vii-brain:
   ```
   pwsh -NoProfile -File <vii-stack-root>/bin/vii-brain.ps1 add retro "Week <YYYY-WW>: <one-sentence summary of what shipped and key lesson>"
   ```
6. Tell the user: "Retro saved to `.vii/retro/<YYYY-WW>.md`. Use `/vii-learn` to capture any specific lesson before next session."

## Output format

Write `.vii/retro/<YYYY-WW>.md` with this exact structure:

```markdown
# Retro — Week <YYYY-WW>

## Shipped
- <bullet per PR or feature from git log — include commit SHA in parens>

## Learned
- <bullet per /vii-learn entry from vii-brain this week — quote the body>

## Patterns
<2–4 sentences on recurring themes: what keeps coming up, what the codebase is telling you.
Draw from commit messages, review findings, and vii-brain entries together.>

## Friction
- <specific blocker, slow decision, or repeated mistake — be concrete, not vague>

## Next Week
- <1–3 concrete, actionable goals derived from the Friction and Patterns sections above>
```

If a section has no data (e.g., no `/vii-learn` entries this week), write "— none recorded this week." Do not omit sections.

## What not to do

- **Do not write code or modify any file except `.vii/retro/<YYYY-WW>.md`.** This is analysis only.
- **Do not fabricate git history.** Only use what `git log` actually returns.
- **Do not skip the vii-brain store step.** Retros stored in vii-brain become the raw material for future retros and cross-project pattern detection.
- **Do not produce vague Next Week goals** like "do better." Each goal must name a specific action (e.g., "add a test for the vii-brain init path before shipping the next PR").
- **Do not run this on `main` or `develop` directly.** The retro covers the project as a whole, not a branch — but you should still check which branch is active and note it.
