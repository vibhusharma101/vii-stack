---
name: vii-skillify
description: >
  Turn a workflow you just performed into a permanent vii-stack skill —
  extracts the method, writes skills/<stage>/vii-<name>/SKILL.md, registers it
  in README and CLAUDE.md, and validates. Use when the user says "skillify
  this", "make this a skill", "codify this", "save this workflow", "I keep
  doing this manually", or invokes /vii-skillify. Args: an optional skill name.
---

# /vii-skillify

You are converting something that just worked into a skill that will work
again. The raw material is the session you are in: the commands actually run,
the dead ends hit, the judgment calls made.

The reason to do this is narrow: a workflow earns a skill when it is **repeated
and non-obvious**. Repeated but obvious needs no skill. Non-obvious but done
once is a note, not a skill. Say so plainly rather than manufacturing one.

## Arguments

- _(no arg)_ — infer a name from the workflow.
- `<name>` — use `vii-<name>` (the prefix is added if missing).

## Inputs

- This session: the commands run, their outputs, the corrections made.
- `skills/*/vii-*/SKILL.md` — the house style to match.
- `CONTRIBUTING.md` — the conventions the validator enforces.

## Method

1. **Name the workflow and check it deserves a skill.** State in one line what
   it does and why it is not obvious. If it is a single command, or was done
   once with no judgment involved, say that and stop — offer `/vii-learn`
   instead, which is the right home for a one-off lesson.

2. **Pick the stage directory.** `think`, `plan`, `build`, `review`, `test`,
   `ship`, `reflect`, `security`, or `power` for mode toggles and maintenance.
   Names must be unique across all stages — `setup.ps1` flattens them into
   `~/.claude/skills/<name>`, so a collision silently overwrites. Check first:
   ```powershell
   Get-ChildItem skills -Recurse -Directory -Filter "vii-*" | Select-Object -ExpandProperty Name
   ```

3. **Extract the method from what actually happened**, not from how you would
   describe it afterwards. Walk the session and capture:
   - The commands that worked, with their real flags.
   - The order that mattered, and where order did not matter.
   - **Every correction.** A step you got wrong and fixed is the most valuable
     line in the new skill — it becomes a "What not to do" entry.
   - The judgment calls: what you checked before deciding, not just the decision.

4. **Write the skill** following the house structure: frontmatter (`name`
   matching the directory, `description` ending in trigger phrases), then
   `# /vii-<name>`, Arguments, Inputs, Method, Output format, Integration with
   vii-stack, What not to do.

   Two things separate a skill that works from one that reads well:
   - **Say when it refuses.** A skill that never declines is advice, not a role.
   - **Show a weak example beside a strong one** for any judgment-heavy output.

5. **Register it** in `README.md`'s command table and `CLAUDE.md`'s command
   list, and bump both skill counts in the README. The validator fails without
   this, by design — an unregistered skill is undiscoverable.

6. **Add a `### Added` line** under `## [Unreleased]` in `CHANGELOG.md`.

7. **Validate**:
   ```powershell
   .\bin\vii-validate.ps1
   ```
   Fix anything it reports before handing back.

8. **Tell the user to run `.\setup.ps1`** and restart Claude Code. A skill in
   the repo is not invocable until it is synced to `~/.claude/skills/` and the
   session has restarted.

## Output format

```
skillified: /vii-<name>
  stage:    skills/<stage>/vii-<name>/SKILL.md
  from:     <one line on the workflow it captures>
  refuses:  <what the skill declines to do>

registered in README.md, CLAUDE.md, CHANGELOG.md
validator: PASSED - <N> skills

Run .\setup.ps1, then restart Claude Code to use it.
```

## Integration with vii-stack

- `/vii-learn` is the alternative for anything that does not warrant a skill —
  a lesson, a gotcha, a preference. Reach for it when step 1 says no.
- `/vii-lean` applies here: the shortest skill that captures the workflow beats
  a thorough one nobody finishes reading.
- Run `/vii-devex-review` on a new skill if you want the cold-start check.

## What not to do

- **Do not skillify a single command.** An alias is not a skill.
- **Do not write the idealised version.** The value is in the corrections and
  dead ends from the real run. A skill that describes the happy path teaches
  nothing the model would not already guess.
- **Do not reuse an existing skill name.** Check across every stage, not just
  the one you are writing into.
- **Do not skip registration** to save a step. The validator will fail, and an
  unregistered skill is invisible to both the user and Claude.
- **Do not claim the skill is usable before `setup.ps1` has run.** It lives in
  the repo; it runs from `~/.claude/skills/`.
