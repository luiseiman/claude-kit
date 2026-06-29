---
globs: "**/agents/*.md,**/CLAUDE.md"
description: "Model IDs and agent defaults for Claude Code subagent instantiation"
domain: claude-code
last_verified: 2026-06-01
---

# Model IDs (June 2026)

| Tier | Model ID | Context | Max output |
|------|----------|---------|------------|
| fable (Mythos-class, v2.1.170+) | `claude-fable-5` | TBD | TBD |
| opus | `claude-opus-4-8` | 1M | 128K tokens |
| sonnet | `claude-sonnet-4-6` | 1M | 64K tokens |
| haiku | `claude-haiku-4-5-20251001` | 200K | 8K tokens |

Opus 4.7 (`claude-opus-4-7`) still resolvable as legacy pin — choose when reproducing benchmarks predating v2.1.154 (2026-05-27).

**Fable 5 (v2.1.170+)** is a Mythos-class model with capabilities exceeding any prior generally-available Claude. Treat as the top tier for the highest-stakes work (architecture across irreversible blast radius, security audits on production-tier projects, complex novel problems). Cost/context specifics still consolidating — verify via `/model` picker before pinning to a session. Do NOT default agents to fable yet without explicit cost justification.

Default agents: opus → architect, security-auditor. sonnet → implementer, code-reviewer, session-reviewer. haiku → researcher, test-runner.

## Effort levels (v2.1.111+)

Five core tiers + 1 mode tier: `low` < `medium` < `high` < `xhigh` < `max`, plus `ultracode` (v2.1.154+ runtime activator). `xhigh` is Opus-exclusive (4.7 and 4.8) — Sonnet/Haiku fall back to `high` when xhigh is requested. **`ultracode`** is also Opus-only (4.7+4.8) — combines `xhigh` reasoning + automatic workflow orchestration per substantive task. Activated via `/effort ultracode`, session-only, resets on new session. With it on, each substantive request can spawn several workflows in sequence (understand → change → verify). Pairs with dotforge's `workflow-and-ultracode-policy.md` tier system: `production`/`heavy` tier → recommend `/effort ultracode` at session start. Global default is `effort: high` (changed v2.1.94, 2026-04-07, was `medium`). Opus 4.8 defaults to `high` with `xhigh` available out of the box.

- Skills/agents WITHOUT explicit `effort:` consume more tokens and run slower
- Pin `effort: low` in `agents/researcher.md` and `agents/test-runner.md` to keep them cheap
- Consider `xhigh` (not `max`) for `security-auditor`/`architect` on complex tasks — deeper reasoning without the cost jump of max
- Benchmark baselines computed before 2026-04-07 are no longer comparable
- For deterministic transformations (rename, reformat) explicit `effort: low` is recommended

## `/effort` persistence (v2.1.162+)

After picking a level via `/effort`, the picker confirms "this will be the default for new sessions" — the choice persists across new sessions (not just the current one). Pre-v2.1.162 the persistence behavior was silent and confused users into re-setting effort each session. The picker is now explicit about the scope. Use `--effort <level>` per-invocation when you need a one-off override without mutating the persistent default.

## `/model` is per-session by default (v2.1.144+)

- `/model <id>` changes the model **for the current session only**. Previously (pre-v2.1.144) it mutated `~/.claude/settings.json` so the choice persisted.
- To set the persistent default: open the picker with `/model` (no args), select the model, press `d`
- CI implication: prefer `--model <id>` flag on each `claude` invocation rather than expecting `/model` to leak across processes
- Trading workflow implication: switch one bot session to Opus 4.7 for a high-stakes job without affecting the rest

## Fast mode (Opus toggle)

- `/fast` toggles a lower-latency variant of the active Opus model mid-session
- **Default flipped to Opus 4.7** in v2.1.142 (2026-05-14); Opus 4.8 default ships with v2.1.154 (2026-05-27)
- Opus 4.8 fast mode: **2x standard rate for 2.5x speed** — more aggressive cost/latency tradeoff than 4.7 fast mode. Choose explicitly per use case
- `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` env var **removed 2026-06-01** (was deprecated in v2.1.154). No path to pin fast mode to Opus 4.6 anymore — benchmarks predating the v2.1.142 flip (2026-05-14) cannot be reproduced via env var; re-baseline against the current default

> Claude 3 Haiku deprecated — retiring April 19, 2026. Use claude-haiku-4-5 only.
> Update this table when Anthropic releases new model versions.
