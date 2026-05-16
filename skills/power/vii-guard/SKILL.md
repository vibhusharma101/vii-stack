---
name: vii-guard
description: Shorthand for /vii-careful + /vii-freeze <dir>. Acks destructive-command warnings for the session AND locks edits to a directory subtree. Useful when starting a risky task in one part of the codebase ("guard me while I work in src/auth").
---

# /vii-guard

You are running both `/vii-careful` and `/vii-freeze` together. This is the right move when the user is about to do focused, risky work in one subtree and wants the strongest safety net.

## Inputs

- One argument: the directory to freeze to (same semantics as `/vii-freeze`).
- A reason: ask the same question `/vii-careful` asks — *"What destructive operation do you need to run, and why?"*

## Method

1. Run the `/vii-freeze <dir>` flow (resolve path, refuse useless freezes, refuse silent overwrite, write `.vii/freeze`).
2. Run the `/vii-careful` flow (read `.vii/.current-session`, ask for a reason, write `.vii/careful-acked-<sessionId>` with reason + timestamp).
3. Confirm both states in one short message:
   - "Edits locked to `<path>`."
   - "Destructive commands acked for this session: `<reason>`."
   - "Reset with `/vii-unfreeze` and a new Claude Code session respectively."

## What not to do

- **Do not duplicate the logic of `/vii-careful` and `/vii-freeze`** — call into the same files/state, do not invent a new file format.
- **Do not skip the user-confirmation prompts** that each underlying skill requires. Both prompts must run.
- **Do not order them the other way (careful before freeze).** Freeze first so that if the user changes their mind mid-prompt, they have not already acked careful.
