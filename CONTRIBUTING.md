# Contributing to vii-stack

vii-stack is a Claude Code skill pack. Almost every change is either a new
`SKILL.md`, a change to a PowerShell hook in `bin/`, or a change to
`setup.ps1`. This file covers what CI expects of each.

---

## Repo layout

```
skills/<stage>/vii-<name>/SKILL.md   the skills themselves
bin/*.ps1                            hooks + CLI helpers
hooks/settings.snippet.json          hook registration merged into ~/.claude/settings.json
setup.ps1                            idempotent installer
docs/                                architecture + full skill reference
```

Stages are `think`, `plan`, `build`, `review`, `test`, `ship`, `reflect`,
`security`, `power`. `power/` holds anything that toggles a mode rather than
advancing the workflow (`/vii-careful`, `/vii-freeze`, `/vii-cheap`,
`/vii-lean`, `/vii-upgrade`).

`setup.ps1` **flattens** `skills/<stage>/vii-<name>` into
`~/.claude/skills/vii-<name>`. The stage directory is organisational only — it
is not part of the installed path, so **skill names must be unique across all
stages**. CI fails on duplicates.

---

## Adding a skill

1. Create `skills/<stage>/vii-<name>/SKILL.md` with YAML frontmatter:

   ```yaml
   ---
   name: vii-<name>
   description: >
     What it does, then the trigger phrases: Use when the user says
     "...", "...", or invokes /vii-<name>.
   ---
   ```

   `name:` must match the directory exactly. The description is the only thing
   Claude sees when deciding whether to invoke the skill — lead with the job,
   end with the trigger phrases. Keep it under 1024 characters.

2. Body starts with `# /vii-<name>`, then the sections the existing skills use:
   **Arguments** (if any), **Inputs**, **Method**, **Output**, and a closing
   **What not to do**. That last section is load-bearing — it is where a skill
   states the failure mode it is guarding against.

3. Register the command in **both** `README.md` (the command table) and
   `CLAUDE.md` (the command list). CI fails if either is missing, because those
   two files are the only places a user or Claude discovers the command.

4. Bump the skill count in the README's `Commands (N total)` heading and its
   `Syncs all N skills` install step. CI checks both against the real count.

5. Add a `### Added` line under `## [Unreleased]` in `CHANGELOG.md`.

---

## Writing style for skills

Skills are prompts, not documentation. What works:

- **Be specific about refusal.** `/vii-ship` refuses on a red test suite;
  `/vii-plan-eng` refuses to write code. A skill that never refuses is advice,
  not a role.
- **Name the artifact.** Each stage reads the previous stage's file under
  `.vii/` and writes its own. State both paths explicitly.
- **Show a weak example and a strong one.** `/vii-lean-review` does this for
  findings, and it is the single biggest driver of output quality.
- **Prompts advise; hooks enforce.** Anything that must not be bypassed needs a
  PreToolUse hook in `bin/`, not a paragraph in a `SKILL.md`.

---

## Validating locally

```powershell
.\bin\vii-validate.ps1     # skill manifests, cross-references, skill count
.\setup.ps1 -DryRun        # installer resolves without touching anything
```

Both run in CI (`.github/workflows/validate.yml`) on every PR, alongside a
parse check over every `.ps1` in the repo. Run them before pushing — they are
fast and catch the drift that is otherwise only visible after install.

To test a skill end to end, run `.\setup.ps1` and invoke the command in a real
project. There is no unit-test harness for prompts; the installer plus a live
invocation is the test.

---

## Branches and PRs

- Branch off `develop`, not `main`. `main` tracks released state.
- Branch names: `feature/<topic>` or `fix/<topic>`.
- One concern per PR. A new skill and an installer change are two PRs.
- Commit subject in the imperative, under ~70 characters, with the affected
  command named: `add /vii-upgrade skill`, `fix(vii-cheap): fall back to ~/.rtk`.
- PRs merge into `develop`. `develop` merges into `main` at a release, with the
  `VERSION` bump and the `CHANGELOG.md` `[Unreleased]` section promoted to a
  version heading in the same commit.

---

## Reporting a problem

Open an issue with the command you ran, what you expected, what happened, and
the output of:

```powershell
.\bin\vii-validate.ps1
$PSVersionTable.PSVersion
```

Hook problems are the common case. `~/.claude/settings.json` holds the
registered hooks — re-running `.\setup.ps1` re-registers them and is safe at
any time.
