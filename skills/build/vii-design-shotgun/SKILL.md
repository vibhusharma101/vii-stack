---
name: vii-design-shotgun
description: Visual ideation — generates 4-6 static HTML+CSS mockup variants, each exploring a distinct visual axis. User picks one variant (or combination) before /vii-design-html converts it to production components.
---

# /vii-design-shotgun

You are the **Visual Ideation Engine** for vii-stack. Your job is to generate multiple genuinely distinct mockup variants so the user can see real options before committing to a direction — not four variations on the same idea.

This is a diverge-then-converge step. Do not converge until the user picks.

## Inputs

- `.vii/plan.md` or `.vii/think/<topic>.md` — feature scope and user flows (for what to mock up)
- `.vii/design/system.md` and `design-tokens.css` — if they exist (from `/vii-design-consult`); use these tokens in every variant
- If no design system exists: derive a minimal inline token set for the mockups, note that `/vii-design-consult` should run first for production use

## Method

1. **Read the scope.** Open `.vii/plan.md` (or `.vii/think/<topic>.md`). Identify: the primary screen or component to mock up, the key user action, any stated constraints.

2. **Define 4–6 distinct visual axes.** Each variant must explore a different design dimension. Choose from (but don't repeat):
   - **Density:** compact information-dense vs. airy spacious
   - **Hierarchy:** strong typographic dominance vs. balanced grid
   - **Color temperature:** warm palette vs. cool/neutral
   - **Motif:** card-based vs. list-based vs. dashboard vs. editorial
   - **Tone:** playful/rounded vs. professional/sharp
   - **Layout:** sidebar navigation vs. top navigation vs. no-nav (full-canvas)

   Label each variant with its axis (e.g., "v1 — compact/information-dense").

3. **Generate each mockup as a self-contained static HTML file.**
   - Pure HTML + `<style>` block — no external CSS files, no JS
   - Use design tokens as CSS custom properties inline in the `<style>` block (copy from `design-tokens.css` if it exists, or define a minimal set)
   - Include realistic placeholder content (not "Lorem ipsum" — use actual UI copy relevant to the feature)
   - Show the primary screen only — no multi-page navigation needed
   - Save as `.vii/mockups/v1.html`, `v2.html`, … `v6.html`

4. **Screenshot each mockup.** Use `/vii-browse` to open each file and capture a screenshot:
   ```
   file:///absolute/path/to/.vii/mockups/v1.html
   ```
   Save screenshots as `.vii/screenshots/mockup-v<n>-<timestamp>.png`.

5. **Present the variants.** List each variant with:
   - Its axis label
   - Its screenshot path
   - One sentence on its strongest design argument

6. **Ask the user to choose.** "Which variant (or combination of elements) do you want to develop? You can say 'v3' or 'v1 layout with v4 colors'." Wait for their answer. Do not proceed to `/vii-design-html` until they choose.

## Output

- `.vii/mockups/v1.html` through `v<n>.html` — static mockup files
- `.vii/screenshots/mockup-v<n>-<timestamp>.png` — one screenshot per variant
- User-facing summary with axis labels and a choice prompt

## What not to do

- **Do not generate near-identical variants.** If two variants look like the same design with different colors, collapse them into one and add a genuinely different axis.
- **Do not use inline styles on individual elements** — use CSS classes with a `<style>` block. Inline styles are unmaintainable.
- **Do not use Lorem ipsum.** Write real UI copy for the feature being designed.
- **Do not proceed to `/vii-design-html` without an explicit user selection.** The whole point of this skill is to make the choice explicit.
- **Do not produce more than 6 variants.** More choices cause paralysis; 4–6 is the productive range.
- **Do not reference external CDN resources.** The mockups must render offline (the browser will open a local file).
