---
name: vii-careful
description: Acknowledge destructive shell commands for the current session. Creates .vii/careful-acked-<sessionId> so the vii-careful-check PreToolUse hook stops blocking commands like `git reset --hard`, `git push --force`, `rm -rf`. Ack is per-session and is cleared automatically on the next SessionStart.
---

# /vii-careful

You are toggling the **vii-careful** safety hook off for the current session. The hook lives at `bin/vii-careful-check.ps1` (registered as PreToolUse/Bash) and blocks a set of destructive shell patterns. This skill creates the ack sentinel that the hook checks.

## Method

1. **Find the session id.** Read `.vii/.current-session` (written by the SessionStart hook). If it does not exist, halt and tell the user to start a fresh Claude Code session — the SessionStart hook must have run at least once for `.vii/.current-session` to be present.

2. **Read the user's reason.** Ask the user one short question: *"What destructive operation do you need to run, and why?"* Record the answer in a single line. If the user refuses to give a reason, refuse to ack — the whole point of this skill is the friction.

3. **Create the ack file.** Write `.vii/careful-acked-<sessionId>` containing the reason and timestamp:

   ```
   reason: <user's one-line reason>
   acked_at: <ISO-8601 timestamp>
   ```

4. **Confirm to the user.** Tell them:

   - Which destructive patterns are now unblocked (`rm -rf /...`, `git reset --hard`, `git push --force`, `git clean -f`, `git branch -D`, `DROP TABLE`, etc.).
   - That the ack is cleared automatically the next time Claude Code starts a fresh session.
   - The exact command they wanted to run, so they double-check it before running.

## What not to do

- **Do not ack without a reason.** "I just need to" is not a reason. Push back once, then refuse if still nothing concrete.
- **Do not ack pre-emptively** when the user has not yet named a specific command. Ack happens because of a specific need, not as a default-on convenience.
- **Do not modify the hook script** to disable it. The whole safety design depends on the hook being trusted and the ack file being the only escape hatch.
- **Do not write the ack file in the user's home directory or anywhere outside the current project's `.vii/`.** The hook only reads from the project's `.vii/`, so a global ack would be both broken and a leak.
- **Do not chain straight into running the destructive command.** Hand control back so the user explicitly issues it.

## Reference

The hook's blocked patterns (from `bin/vii-careful-check.ps1`):

- `rm -rf /`, `rm -rf ~`, `rm -rf $HOME`
- `git reset --hard`
- `git push ... --force`, `git push ... -f`
- `git clean -[a-z]*f`
- `git branch -D`
- `DROP TABLE`, `DROP DATABASE`, `TRUNCATE TABLE`
- `mkfs.`, `dd if=... of=/dev/`
- `shutdown`, `reboot`
