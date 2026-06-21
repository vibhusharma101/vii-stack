# vii-stack

A Claude Code skill pack that turns Claude into a virtual engineering team — CEO, Designer, Eng Manager, QA Engineer, Release Manager, Security Auditor — for one builder (you).

Inspired by [garrytan/gstack](https://github.com/garrytan/gstack). Built for **Claude Code on Windows** (PowerShell). No extra subscriptions, no cloud services, no Docker.

---

## What it does

Instead of prompting Claude generically, vii-stack gives you slash commands that put Claude into a specific expert role for each stage of building:

```
Think → Plan → Build → Review → Test → Ship → Reflect
```

Each stage reads the previous stage's output. Skipping is allowed but discouraged.

---

## Commands (31 total)

| Stage | Command | What it does |
|-------|---------|-------------|
| **Think** | `/vii-office-hours` | Product manager — grills your idea with forcing questions before any code |
| **Plan** | `/vii-autoplan` | Runs all planning perspectives automatically |
| | `/vii-plan-eng` | Engineering manager — file-level change list, test plan, rollback strategy |
| | `/vii-plan-ceo` | CEO — business value, scope tradeoff, go/no-go |
| | `/vii-plan-design` | Designer — user flows, component inventory, accessibility |
| | `/vii-plan-devex` | DevEx — API ergonomics, error messages, docs gaps |
| **Build** | `/vii-design-consult` | Derives a design token set from 2-3 reference sites |
| | `/vii-design-shotgun` | Generates 4-6 distinct static mockup variants |
| | `/vii-design-html` | Converts chosen mockup to framework components |
| **Review** | `/vii-review` | Staff engineer code review with severity-tagged findings |
| | `/vii-lean-review` | Over-engineering audit — finds what to delete (stdlib, YAGNI, dead flexibility) |
| | `/vii-investigate` | Five-whys root-cause debugger |
| | `/vii-design-review` | Visual audit using live screenshots (WCAG AA) |
| | `/vii-devex-review` | Cold-start friction audit from clean clone |
| **Test** | `/vii-browse` | Real Chromium via Playwright MCP — navigate, screenshot, extract logs |
| | `/vii-qa` | Finds bugs, fixes them, verifies fixes |
| | `/vii-qa-only` | Same as /vii-qa but report-only, no code changes |
| **Ship** | `/vii-ship` | Security audit + push + open PR |
| | `/vii-land` | Merge approved PR + deploy + prod healthcheck |
| | `/vii-canary` | Post-deploy monitor (5 checks × 2 min) |
| | `/vii-benchmark` | Core Web Vitals (LCP/CLS/INP/TTFB) vs baseline |
| | `/vii-doc-release` | Update README + CHANGELOG after shipping |
| **Reflect** | `/vii-learn` | Save a lesson to vii-brain + Claude auto-memory |
| | `/vii-retro` | Weekly retrospective from git log + vii-brain |
| **Security** | `/vii-cso` | OWASP Top 10 + STRIDE audit on current diff |
| **Safety** | `/vii-careful` | Acknowledge destructive commands for the session |
| | `/vii-freeze <dir>` | Lock all edits to one directory subtree |
| | `/vii-guard <dir>` | `/vii-careful` + `/vii-freeze` in one command |
| | `/vii-unfreeze` | Remove the freeze lock |
| **Lean coding** | `/vii-lean` | Toggle lean coder mode — YAGNI ladder, stdlib first, shortest diff (levels: lite / full / ultra) |
| **Token-saving** | `/vii-cheap` | Toggle cheap mode — route read-heavy commands through [RTK](https://github.com/rtk-ai/rtk) to compress output 50-90% before it hits context |

---

## Memory: vii-brain

vii-brain is a persistent, cross-project memory store backed by [PGLite](https://github.com/electric-sql/pglite) (embedded Postgres). It lives at `~/.vii/vii-brain.db` on your machine.

Skills write to it automatically (`/vii-ship` records PR URLs, `/vii-learn` stores lessons, `/vii-retro` stores weekly summaries). You can also query it directly:

```powershell
# See everything stored
bin/vii-brain.ps1 list

# Search across all projects
bin/vii-brain.ps1 search "auth"

# Add a note manually
bin/vii-brain.ps1 add learn "always run setup.ps1 after pulling"
```

Tags: `learn` · `design` · `architecture` · `process` · `bug` · `ref` · `ship` · `retro`

---

## Install

**Requirements:** Windows, PowerShell 5.1+, [Claude Code](https://claude.ai/code), [Node.js 18+](https://nodejs.org), [GitHub CLI](https://cli.github.com)

```powershell
git clone https://github.com/vibhusharma101/vii-stack
cd vii-stack
.\setup.ps1
```

The installer (idempotent — safe to re-run):
1. Syncs all 28 skills to `~/.claude/skills/`
2. Appends the vii-stack command list to `~/.claude/CLAUDE.md`
3. Registers the safety hooks (`/vii-careful`, `/vii-freeze`) in `~/.claude/settings.json`
4. Registers the Playwright MCP server for `/vii-browse`
5. Initializes the vii-brain PGLite database at `~/.vii/vii-brain.db`

After install, open Claude Code in **any project** and type `/vii-office-hours` to start.

---

## How a typical build looks

```
/vii-office-hours          ← define the problem
/vii-autoplan              ← generate the plan
/vii-design-consult        ← extract design tokens from reference sites
/vii-design-shotgun        ← generate mockup variants, pick one
/vii-design-html           ← convert mockup to components
/vii-review                ← code review
/vii-qa                    ← find and fix bugs
/vii-ship                  ← security audit + PR
/vii-land                  ← merge + deploy
/vii-canary                ← watch prod for 10 minutes
/vii-learn "key insight"   ← save what you learned
```

Stage artifacts live under `.vii/` in your project (gitignored by default).

---

## Architecture

See [`docs/ARCHITECTURE.md`](docs/ARCHITECTURE.md) for how the pieces fit together and [`docs/skills.md`](docs/skills.md) for the full skill reference.

---

## License

[MIT](LICENSE) — do whatever you want, just keep the copyright notice.
