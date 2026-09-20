---
name: vii-upgrade
description: >
  Upgrade the vii-stack install — locate the clone, pull the latest develop,
  re-run setup.ps1, and report which commands changed. Use when the user says
  "upgrade vii-stack", "update vii-stack", "pull the latest skills", "re-run
  setup", "my vii commands are stale", or invokes /vii-upgrade.
  Args: check (report only, no changes) | force (re-sync even if already current).
---

# /vii-upgrade

You are upgrading this machine's vii-stack install. Skills live in the repo but
*run* from `~/.claude/skills/`, so a `git pull` alone changes nothing — the
install is only refreshed when `setup.ps1` re-syncs. This skill closes that gap
and reports what actually changed, so the user knows which commands are new.

## Arguments

- _(no arg)_ — pull and re-install.
- `check` — report the gap between the clone and the remote. Change nothing.
- `force` — re-run `setup.ps1` even when already at the latest commit. Use when
  `~/.claude/skills/` was edited or deleted by hand.

## Inputs

- The vii-stack clone. Resolve it in this order and stop at the first hit:
  1. `$env:VII_STACK_ROOT`, if set.
  2. The current project, if `setup.ps1` and `skills/` both exist at its root.
  3. The path baked into the registered hook commands in
     `~/.claude/settings.json` — every vii-stack hook points at `<root>/bin/`.
  4. Ask the user for the path. Do not guess a location and do not clone a
     second copy.
- `~/.claude/skills/` — the installed skills, for the before/after comparison.

## Method

1. **Resolve the clone root** by the order above. Report the path you resolved
   and which rule found it.

2. **Snapshot the install** before touching anything:
   ```powershell
   Get-ChildItem ~/.claude/skills -Directory -Filter 'vii-*' | Select-Object -ExpandProperty Name
   ```

3. **Check for local changes** in the clone (`git status --porcelain`). If the
   tree is dirty, stop and show the user what is uncommitted. Never stash or
   discard their work to make the pull succeed.

4. **Fetch and compare**:
   ```powershell
   git -C <root> fetch origin
   git -C <root> log --oneline HEAD..origin/develop
   ```
   Nothing listed → already current. On `check`, report and stop. On no arg,
   report and stop unless `force` was passed.

5. **Pull** with `git -C <root> pull --ff-only origin develop`. If the
   fast-forward is refused, the clone has diverged — report it and stop. Do not
   merge or rebase on the user's behalf.

6. **Validate before installing.** Run `<root>\bin\vii-validate.ps1`. If it
   fails, stop and show the errors — a broken manifest installed is worse than
   an old one left alone.

7. **Re-install**: `<root>\setup.ps1`. Show its step output.

8. **Diff the install** against the step-2 snapshot and report:
   - commands added,
   - commands removed (renamed or retired upstream),
   - the commit range that was pulled, one line per commit.

9. **Read `CHANGELOG.md`** from the clone and summarise the entries newer than
   the user's previous commit in at most three lines.

## Output

```
vii-stack upgrade
  root:     C:\Users\<you>\vibhucoding\vii-stack
  pulled:   903e927..<new>  (N commits)
  skills:   31 -> 32

  added:    /vii-upgrade
  removed:  (none)

  changelog:
    - <one line per notable entry>

Restart Claude Code to pick up the new commands.
```

Always end with the restart line. Claude Code reads `~/.claude/skills/` at
session start, so a skill synced mid-session is not invocable until a restart.

## What not to do

- **Do not clone a fresh copy** when the clone cannot be found. Ask for the
  path. A second clone splits the install and the next upgrade picks the wrong
  one.
- **Do not discard local changes** to make the pull succeed — no stashing, no
  hard resets, no reverting tracked files. A dirty tree stops the upgrade and
  the user resolves it.
- **Do not edit `~/.claude/skills/` directly.** It is a build output.
  `setup.ps1` owns it, and hand edits are erased by the next sync.
- **Do not upgrade to a branch other than `develop`** unless the user names one.
- **Do not claim success from a pull alone.** The upgrade is only real once
  `setup.ps1` has run and the skill list has been re-read.
