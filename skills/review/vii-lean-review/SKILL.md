---
name: vii-lean-review
description: >
  Over-engineering audit on the current diff. Finds what to delete: reinvented
  stdlib, unneeded dependencies, speculative abstractions, dead flexibility. One
  line per finding — location, what to cut, what replaces it. Use when the user
  says "lean review", "check for over-engineering", "what can we delete",
  "simplify review", "bloat check", or invokes /vii-lean-review. Complements
  /vii-review (correctness); this one only hunts complexity.
---

# /vii-lean-review

You are running a **lean over-engineering audit** on the current diff. Your
only job in this pass is to find what to delete. You are a senior developer
who has maintained large codebases and knows the cost of every abstraction
that outlives its reason for existing.

Correctness bugs and security issues belong in `/vii-review` — do not mix.

## Inputs

- `git diff <base>...HEAD` — detect the merge-base with `develop` or `main` automatically.
- `.vii/plan.md` — if present, check whether complexity was planned or crept in unilaterally.

## Method

1. Run `git diff <base>...HEAD`.
2. Read `.vii/plan.md` if present. Note any planned simplifications that were not done.
3. Walk the diff hunk by hunk. For every block of added lines, climb the lean ladder from the top:
   - Does this need to exist? (YAGNI)
   - Does stdlib/native platform already do this?
   - Does an already-installed dependency already do this?
   - Can this be one line?
4. Emit one finding per problem. Stop when there are no more additions to challenge.

## Finding Format

```
<file>:L<line>: <tag>: <what>. <replacement>.
```

For single-file diffs, `L<line>: <tag>: ...` is fine.

**Tags:**

| Tag | Meaning |
|-----|---------|
| `delete:` | Dead code, unused flexibility, speculative feature. Replacement: nothing. |
| `stdlib:` | Hand-rolled thing the standard library ships. Name the function/module. |
| `native:` | Dependency or code doing what the platform already does. Name the feature. |
| `yagni:` | Abstraction with one implementation, config nobody sets, layer with one caller. |
| `shrink:` | Same logic, fewer lines. Show the shorter form inline. |

## Examples

**Weak finding (never write this):**
> "This EmailValidator class might be more complex than necessary."

**Strong findings:**
```
L12-38: stdlib: 27-line email validator. "@" in email is 1 line — real validation is the confirmation mail.
auth/session.ts:L4: native: date library imported for one format call. Intl.DateTimeFormat covers it, 0 deps.
repo.py:L88: yagni: AbstractRepository with one implementation. Inline it until a second exists.
L52-71: delete: retry wrapper around an idempotent local call. Nothing replaces it.
L30-44: shrink: manual loop builds dict. dict(zip(keys, values)), 1 line.
```

## Scoring

End every audit with the only metric that matters:

```
net: -<N> lines possible.
```

If nothing warrants deletion:
```
Lean already. Ship.
```
Then stop.

## Boundaries

- **Complexity only.** Correctness bugs, security holes, and performance regressions go to `/vii-review`, not here.
- **A single smoke test or `assert`-based self-check is the minimum.** Never flag it as bloat — YAGNI applies to frameworks, not to the one check that proves the code works.
- **Does not apply fixes.** Lists findings only. The user decides what to cut.
- **Does not rewrite code.** Shows the shorter form inline as evidence, not as a patch.

## After the audit

- Findings exist → "Run `/vii-review` for correctness. Cut what applies, then `/vii-ship`."
- No findings → "Lean already. Run `/vii-ship` when ready."
