---
name: vii-health
description: >
  Whole-repo health dashboard — build and test status, dependency freshness and
  advisories, test coverage of changed areas, doc drift, and vii-stack's own
  install integrity. Ranks findings by what to fix first. Use when the user
  says "health check", "how healthy is this codebase", "quality dashboard",
  "is this repo in good shape", or invokes /vii-health. Args: quick | full.
---

# /vii-health

You are assessing the whole repository, not a diff. `/vii-review` judges what
changed; this judges what is there — including the parts nobody has touched in
months, which is usually where the rot is.

The output is a ranked list of what to fix, not a score. A number invites
gaming; an ordered list invites work.

## Arguments

- `quick` (default) — build, tests, obvious drift. No network calls.
- `full` — adds dependency advisories and freshness, which need network access
  and are slower.

## Inputs

Detect what the repo actually is before running anything. Look for
`package.json`, `Cargo.toml`, `pyproject.toml`, `go.mod`, `*.csproj`, `*.ps1`,
then use that ecosystem's tooling. Never run a command for a stack that is not
present.

## Method

Run the checks that apply and skip the rest loudly — a skipped check reported
as skipped is information; one silently omitted is a false clean bill.

1. **Does it build?** The project's build command. A repo that does not build
   makes every other finding secondary — report it first and say so.

2. **Do the tests pass, and do they exist?** Run the suite. Then check whether
   the code changed most recently has any test covering it at all:
   ```powershell
   git log --format= --name-only -30 | Sort-Object -Unique
   ```
   Untested code that changes often is the highest-value gap in the repo.

3. **Dependencies** (`full` only). Advisories first, then staleness:
   `npm audit`, `cargo audit`, `pip-audit`, `govulncheck` — whichever applies.
   Report a known advisory as its own finding, above ordinary staleness.

4. **Doc drift.** Compare what the docs claim against what exists: commands in
   the README that no longer run, install steps naming files that were removed,
   counts and version numbers that no longer match. In this repo specifically,
   `.\bin\vii-validate.ps1` covers the skill manifests.

   **A filename in a doc is not a claim that this repo contains it.** Grepping
   for filenames and testing each for existence produces mostly false
   positives. Before reporting a missing file, read the line it appears on and
   confirm the doc is asserting *this repository* ships it. These are not
   drift:

   | Looks missing | Actually |
   |---------------|----------|
   | `deploy.ps1` | A file the **user's own project** is expected to provide |
   | `settings.json` | `~/.claude/settings.json`, outside the repo |
   | `.vii/plan.md` | Generated at runtime, gitignored |
   | `package.json` in an example | Illustrative, not a path |
   | A path under `~/`, `$HOME`, or an absolute path | Not repo-relative |

   Report a missing file only when the doc presents it as part of this repo —
   in a directory tree, an install step, or a "this repo contains" list. When
   unsure, quote the line and say you are unsure rather than asserting drift.

   Directory trees drift in the other direction too: check for real stage or
   top-level directories the tree **omits**, not just entries it lists that no
   longer exist.

5. **vii-stack install integrity.** Whether the hooks registered in
   `~/.claude/settings.json` still point at files that exist, whether the skills
   in `~/.claude/skills/` match `skills/` in the repo, and whether
   `~/.vii/vii-brain.db` is reachable. A hook pointing at a moved clone fails
   silently, which is the worst way for a safety hook to fail.

6. **Rank the findings.** Order by what breaks first, not by how easy they are:
   broken build > failing tests > known advisory > untested hot path > stale
   dependency > doc drift.

7. **Write `.vii/health/<date>.md`** and report the top findings inline. If a
   previous report exists, name what changed since — improving or degrading is
   more useful than the absolute state.

## Output format

```
health: <repo> @ <sha>

  build      pass | FAIL | n/a
  tests      <passed>/<total>  (<skipped> skipped)
  deps       <N> advisories, <M> majors behind   [full only]
  docs       <N> drift findings
  vii-stack  hooks ok | <problem>

findings, worst first:
  1. <what> — <why it matters> — <the command that fixes it>
  2. ...

skipped: <check> (<why — no network, no such toolchain>)

since <previous report date>: <what improved, what got worse>
```

If nothing is wrong: `healthy. <N> checks passed, <M> skipped.` Then stop.

## Integration with vii-stack

- Complements `/vii-review` (diff correctness) and `/vii-lean-review` (diff
  complexity). This one is repo-wide and diff-blind.
- Good before `/vii-plan-eng` on unfamiliar code, and after a long gap away
  from a project.
- `/vii-cso` owns security of the current diff; a dependency advisory found
  here should be handed to it rather than triaged inline.

## What not to do

- **Do not fix anything.** This is a report. Findings name the fix command; the
  user runs it. A health check that edits code cannot be run safely on an
  unfamiliar repo, which is exactly when it is most useful.
- **Do not emit a score out of 100.** Rank the findings instead.
- **Do not silently skip a check** because its toolchain is missing. List it
  under `skipped` with the reason.
- **Do not run a full dependency audit on `quick`** — it is slow and needs
  network. That is what `full` is for.
- **Do not report every stale dependency.** Group them, name the count, and
  surface only the ones with advisories or breaking majors.
- **Do not report a missing file from a grep alone.** Read the line first and
  confirm the doc claims this repo ships it. A false finding costs the reader
  more than a missed one, because it teaches them to distrust the report.
