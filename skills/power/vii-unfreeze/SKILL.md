---
name: vii-unfreeze
description: Remove the /vii-freeze directory lock. Deletes .vii/freeze so the vii-freeze-check hook stops blocking edits outside the previously-locked subtree.
---

# /vii-unfreeze

You are releasing the **vii-freeze** lock.

## Method

1. Check whether `.vii/freeze` exists.
   - If it does not, tell the user "no freeze active; nothing to do" and stop.
   - If it does, read and display the path that was locked, then delete the file.
2. Confirm to the user that file edits are now unrestricted across the project.

## What not to do

- **Do not also clear `/vii-careful`** — the careful ack is independent and clears itself on next SessionStart.
- **Do not delete anything else under `.vii/`.** Only `.vii/freeze` is in scope.
- **Do not require an argument.** This skill takes no input.
