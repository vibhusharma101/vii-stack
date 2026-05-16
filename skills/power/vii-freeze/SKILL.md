---
name: vii-freeze
description: Lock all Edit/Write/NotebookEdit operations to a single directory subtree for the current project. Writes the locked path to .vii/freeze; the vii-freeze-check PreToolUse hook then rejects any file edit outside that subtree. Persists across sessions until /vii-unfreeze runs.
---

# /vii-freeze

You are turning on the **vii-freeze** safety lock. The hook at `bin/vii-freeze-check.ps1` (registered as PreToolUse/Edit|Write|NotebookEdit) reads `.vii/freeze`; if it contains a directory path, edits outside that subtree are blocked. This skill writes that file.

## Inputs

- One argument: the directory to lock edits to. Absolute or relative to the current project root. If the user typed `/vii-freeze` with no argument, ask for the directory once.

## Method

1. **Resolve the path.** Convert to an absolute path. Verify the directory exists; if not, halt and ask the user to fix the path (do not create it — the user typoed something).
2. **Refuse useless freezes.** If the path is the project root or `/`, refuse — that locks nothing meaningful.
3. **Read existing freeze (if any).** If `.vii/freeze` already exists with a different path, tell the user the current lock and ask if they want to relock; do not silently overwrite.
4. **Write `.vii/freeze`.** Single line, absolute path, UTF-8, no BOM. Create `.vii/` if missing.
5. **Confirm to the user.** State:
   - The exact path now locked.
   - That all Edit/Write/NotebookEdit operations outside this path will be blocked by the hook until `/vii-unfreeze`.
   - That the lock survives across Claude Code sessions (unlike `/vii-careful` which is session-scoped).

## What not to do

- **Do not silently overwrite an existing freeze.** Confirm intent first.
- **Do not lock the project root.** Refuse with an explanation.
- **Do not also enable /vii-careful** — that's `/vii-guard`'s job. This skill only sets the freeze.
- **Do not commit `.vii/freeze` to git.** It should already be in `.gitignore` via the `.vii/` rule.
