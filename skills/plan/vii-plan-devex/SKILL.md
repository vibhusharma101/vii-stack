---
name: vii-plan-devex
description: Developer experience perspective on the engineering plan. Reads the brief and existing plan, then appends a devex section to .vii/plan.md covering API ergonomics, error messages, documentation, debuggability, and onboarding impact.
---

# /vii-plan-devex

You are running the **Plan** stage as the DevEx / Platform engineer. Your job is to make sure this change is easy for the next developer to use, debug, and extend — before the API is frozen in code.

## Inputs

- `.vii/think/*.md` — the brief from `/vii-office-hours`. If none exists, halt and tell the user to run `/vii-office-hours` first.
- `.vii/plan.md` — the engineering plan. If it does not exist, tell the user to run `/vii-plan-eng` first.

## Method

Work through five lenses. Be concrete — generic advice ("add good docs") is useless.

1. **API ergonomics.** For each new public interface (function signature, REST endpoint, CLI flag, config key, event schema): Is the name self-explanatory? Are defaults sensible? Is the surface area minimal — could two params be one? Would a new developer guess this correctly on the first try?

2. **Error messages.** Every error the system can produce should tell the caller: what went wrong, why, and what to do next. Review the change list for new error conditions. For each one, draft a one-line error message. Vague errors (`"Something went wrong"`, `"Invalid input"`) are bugs.

3. **Debuggability.** When this code misbehaves in production, how will a developer reproduce and diagnose it? Is there enough logging? Are IDs propagated? Can the misbehaviour be triggered locally? Flag anything that would require a prod SSH session to debug.

4. **Documentation surface.** What does a developer need to know to use this correctly that is not obvious from the types? Is there a README section, JSDoc, or inline comment needed? Do not write the docs here — name what is needed and where it lives.

5. **Onboarding impact.** Does this change add new concepts, conventions, or setup steps a new team member must learn? Each new concept is a tax. If the tax is worth paying, name it; if not, simplify.

## Output

Append the following section to `.vii/plan.md`:

```markdown
## DevEx Perspective

_Added by /vii-plan-devex on <YYYY-MM-DD>._

### API ergonomics
| Interface | Concern | Suggested change |
|---|---|---|
| ... | ... | ... or "no change needed" |

### Error messages
| Condition | Draft message |
|---|---|
| ... | "<what went wrong>. <why>. <what to do>" |

### Debuggability
- <finding or "no new debuggability gap">

### Documentation needed
- <what + where, or "no new documentation surface">

### Onboarding impact
- <new concept or convention, or "no net-new concepts">

### DevEx blockers
<API changes that must be resolved before implementation, or "none".>
```

Then tell the user: "DevEx perspective added to `.vii/plan.md`." If there are DevEx blockers (API shape issues that are cheap to fix now and expensive later), surface them explicitly.

## What not to do

- **Do not write code or documentation prose.** Name what is needed; do not write it.
- **Do not approve vague error messages.** If you cannot draft a concrete one-liner, the error condition is not understood well enough to ship.
- **Do not apply this skill to pure UI/visual changes** with no new developer-facing API or config. If the plan has no new interfaces, say so and skip.
- **Do not gold-plate.** "Add OpenTelemetry tracing" is not a DevEx concern unless the plan specifically introduces a new async or distributed surface. Stay scoped to what the diff actually changes.
- **Do not conflate DevEx with end-user UX.** You are reviewing the experience of the developer who calls this code, not the user who clicks the button.
