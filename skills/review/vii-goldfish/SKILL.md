---
name: vii-goldfish
description: >
  Elephant-and-goldfish review of a design doc, plan or spec. You (the
  elephant, full context) hand the document to 3-5 fresh zero-context
  subagents (goldfish) who see only the file, never the conversation. They
  report what is missing, ambiguous or unbuildable; the elephant triages each
  finding as FIX or CONTEST, writes .vii/goldfish/<slug>.md, and renders a
  visual HTML report showing what each side knew and found. Use when the user
  says "goldfish review", "elephant and goldfish", "fresh eyes on the plan",
  "is this doc self-contained", "stress-test the spec", or invokes
  /vii-goldfish. Args: an optional doc path (default .vii/plan.md).
---

# /vii-goldfish

You are the **elephant**: you remember everything — the conversation, the
dead ends, the decisions nobody wrote down. That memory is exactly why you are
a bad reviewer of your own document. You read "the cache layer" and know which
one; the next engineer, or the agent that implements it, does not.

So you do not review the document. You hand it to **goldfish** — reviewers
with no memory at all — and let them tell you where it leans on context that
only lives in your head.

The idea comes from Dave Rensin's essay *Elephants, Goldfish, and the New
Golden Age of Software Engineering* and Google's
[elephant-goldfish-model](https://github.com/google/elephant-goldfish-model).
This skill is a compact, vii-stack-native take on it.

## Arguments

- _(no arg)_ — review `.vii/plan.md`; if missing, `.vii/spec.md`; if neither,
  ask which file.
- `<path>` — review that file. Any markdown doc works: a design doc, an ADR, a
  README section, an issue body saved to a file.

## Inputs

- The target document.
- Files the document links to **inside the repo** — goldfish may open those,
  because an implementer would. Nothing else.

## Method

1. **Read the doc yourself first**, then write down — before any goldfish runs
   — the 3 things you most expect a newcomer to stumble on. This is your
   *elephant prediction*; the report compares it to what the goldfish actually
   found. The gap is the most useful number in the report.

2. **Spawn the goldfish.** Use the Agent tool, one subagent per lens, all in
   one message so they run in parallel. Each must be a *fresh* agent — not a
   fork, never `subagent_type: "fork"`, because a fork inherits your memory
   and is no longer a goldfish. If fresh subagents are unavailable, **stop**
   and say so; a review in your own context is not a goldfish review.

   Default lenses (drop any that do not fit; add `security` for anything
   touching auth, secrets or user data):

   | Lens | The goldfish asks |
   |------|-------------------|
   | `comprehension` | Explain the doc back in your own words. Where did you have to guess? |
   | `gaps` | What does an implementer need that is not here — inputs, error cases, limits, owners? |
   | `buildability` | Could you start coding from this tomorrow? List the first question you would have to ask. |
   | `zoom-out` | Is this the right problem? What simpler alternative is not discussed? |

   The prompt to each goldfish contains **only**: the doc's absolute path, its
   lens question, the rules below, and the output format. Never paste
   conversation history, your prediction, or your opinion of the doc.

   ```
   You have never seen this project before. Read <abs path> and any files it
   links to inside the repo. Do not search the rest of the codebase.
   Lens: <lens> — <question>
   Report at most 6 findings, most severe first, each as:
     [HIGH|MED|LOW] <quote or section> — <what is missing/unclear> — <what you would need>
   If the doc is fine through this lens, say so in one line. No praise.
   ```

3. **Triage as the elephant.** For every finding decide:
   - **FIX** — the goldfish is right; the doc depends on context it does not
     contain. Draft the exact edit.
   - **CONTEST** — the answer *is* in the doc (quote where), or the finding is
     out of scope. One line of reasoning.
   Never contest because "everyone knows that". If a goldfish did not know it,
   the implementer will not either.

4. **Write the markdown report** to `.vii/goldfish/<slug>.md`: target doc,
   elephant prediction, each lens's findings with verdict, proposed edits, and
   the prediction-vs-actual line ("predicted 3, goldfish confirmed 1, found 5
   you missed").

5. **Render the visual report.** Copy `report-template.html` from this skill's
   directory (`~/.claude/skills/vii-goldfish/`) to
   `.vii/goldfish/<slug>.html` and replace the JSON inside
   `<script id="egm-data">` with the run's data — the shape is documented in
   the template. Do not edit anything else in the template. Open it:
   `Start-Process .vii/goldfish/<slug>.html`.

6. **Ask before editing the doc.** Show the FIX list and apply only what the
   user approves. Re-run at most once after edits; a second pass that still
   finds HIGHs means the doc needs a rewrite, not patches — say so.

## Output format

```
goldfish review: .vii/plan.md   (4 goldfish, 14 findings)

elephant predicted: auth flow, migration order, rate limits
goldfish confirmed: migration order
goldfish found that you missed: 5

HIGH  gaps          "the queue" (§3) — which queue? not defined   FIX
HIGH  buildability  no error contract for /sync                    FIX
MED   zoom-out      a cron job would do; why a worker?             CONTEST — §1 para 2
...

fixes proposed: 9   contested: 5
report: .vii/goldfish/plan.md   visual: .vii/goldfish/plan.html
```

Weak finding — do not accept from a goldfish or write yourself:
> "Section 3 could be clearer."

Strong finding:
> "[HIGH] §3 'retry with backoff' — no max attempts or what happens after the
> last failure — need: attempt cap and the terminal state of the job."

## Integration with vii-stack

- Run after `/vii-plan-eng` or `/vii-autoplan`, before building: a plan the
  goldfish can follow is a plan the implementing agent can follow.
- Works on `/vii-spec` output to check acceptance criteria are testable by
  someone who was not in the room.
- `/vii-review` reviews code; this reviews the document the code is built
  from.
- Recurring blind spots (the same kind of HIGH across runs) are worth a
  `/vii-learn`.

## What not to do

- **Do not fork.** A forked subagent remembers everything and is an elephant.
- **Do not leak context into goldfish prompts** — no summaries, no "note that
  we decided X". If X matters, it belongs in the doc.
- **Do not run the review in your own context** when subagents are
  unavailable. Stop and say so.
- **Do not auto-apply fixes.** Goldfish are deliberately noisy; the human
  decides.
- **Do not let goldfish roam the codebase.** They read the doc and its links,
  as an implementer starting from the doc would.
