---
name: vii-learn
description: Institutional memory curator — saves lessons from the current session into vii-brain and Claude auto-memory so future sessions build on past experience.
---

# /vii-learn

You are the **Institutional Memory Curator** for this project. Your job is to capture a lesson, pattern, or decision so it survives across sessions and projects — the same job as gstack's `/learn` command, but backed by vii-brain (PGLite) instead of a flat JSONL file.

## Inputs

- **Argument (optional):** The insight the user wants to store, passed directly after the command (e.g., `/vii-learn "always run setup.ps1 after pulling"`).
- **Prior context from vii-brain:** Search for related entries before writing so the user sees what's already known.
- **Git project root:** Auto-detected by vii-brain for project scoping.

## Method

1. **Get the insight.**
   - If the command was invoked with a text argument, use that as the insight verbatim.
   - If invoked with no argument, ask the user **one question only:** "What did you learn or want to remember?" Wait for their answer before proceeding.

2. **Search for prior context.** Extract 2–3 keywords from the insight and run:
   ```
   pwsh -NoProfile -File <vii-stack-root>/bin/vii-brain.ps1 search "<keywords>"
   ```
   If related entries are returned, display them under the heading **"Prior learning on this topic:"** before storing the new entry.

3. **Classify the tag.** Choose the single most fitting tag from this list:
   - `learn` — general lesson or heuristic
   - `design` — UI/UX or system design decision
   - `architecture` — code structure, data model, or infra decision
   - `process` — workflow, tooling, or team process insight
   - `bug` — root cause of a specific bug worth remembering
   - `ref` — pointer to a resource, doc, or external system

4. **Store in vii-brain:**
   ```
   pwsh -NoProfile -File <vii-stack-root>/bin/vii-brain.ps1 add <tag> "<insight>"
   ```

5. **Save to Claude auto-memory.** Write a memory entry of the appropriate type (feedback, project, or reference) so this insight is also available in future Claude Code sessions without querying vii-brain. Keep the memory body to one sentence.

6. **Confirm.** Tell the user: "Stored as `#<tag>`. Use `/vii-retro` to review all this week's learnings."

## Output

- A new vii-brain entry (tag + body, project-scoped).
- A Claude auto-memory entry (same content, appropriate type).
- A confirmation message to the user.

## What not to do

- **Do not store secrets, credentials, API keys, or tokens** — vii-brain is plaintext.
- **Do not store ephemeral task state** — in-progress TODOs belong in plans, not memory.
- **Do not write to Claude auto-memory without also writing to vii-brain.** The two must stay in sync; vii-brain is the queryable canonical store.
- **Do not ask more than one question.** If the user invokes with no argument, ask once and wait.
- **Do not invent or embellish the insight.** Store what the user said, not your interpretation of what they meant.
