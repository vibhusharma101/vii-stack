# elephant-goldfish

See what your Claude Code session is really doing, split the way the
[elephant-goldfish model](https://github.com/google/elephant-goldfish-model)
splits it:

- 🐘 **Elephant**: the main session. It remembers the whole conversation, and it
  fills its context until it gets compacted.
- 🐟 **Goldfish**: each subagent. It knows only the brief it was handed. It
  reads, reports back, and then forgets everything.
- 🗄️ **Long-term memory**: what outlives the session. That means memory files,
  `CLAUDE.md` / `MEMORY.md`, and `vii-brain`.

## What you get

- **A live pane** beside the chat. It opens on session start and updates on
  every prompt, tool call, subagent spawn, subagent return and compaction.
- **`/elephant-goldfish replay`** writes an animated HTML replay of the session
  to `.elephant-goldfish/replay-<time>.html` and opens it in your browser. Press
  play to watch the elephant's context fill up, goldfish swim in and forget,
  and memories drop into the vault. You can scrub, step (← →) and change speed.
  Expand any goldfish to read the exact brief it was given, which is everything
  it knew.
- `/elephant-goldfish` reopens the pane. `/elephant-goldfish reset` clears the
  recording.

Everything stays on your machine. The replay folder gets its own `.gitignore`,
so replays are never committed.

## Install

```
/plugin marketplace add vibhusharma101/vii-stack
/plugin install elephant-goldfish@vii-stack
```

Start a new session after installing.

## How it is classified

| Event | Counted as |
|-------|-----------|
| Tool call with no `agentId` | Elephant activity |
| Tool call with an `agentId` | That goldfish's activity |
| `agent.spawn` | A goldfish is born, or a fork if it inherits context |
| The Agent call returning | The goldfish reports back and forgets |
| Write/Edit to `memory/`, `CLAUDE.md` or `MEMORY.md`, or `vii-brain add` | Stored in long-term memory |
| Reading one of those, or `vii-brain search`/`list` | Recalled from long-term memory |
| `session.compact` on the main loop | The elephant's context is squeezed |

Part of [vii-stack](https://github.com/vibhusharma101/vii-stack). MIT license.
