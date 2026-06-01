---
id: practice-2026-06-01-lean-system-prompt-default
title: Lean system prompt now default (v2.1.154) except Haiku/Sonnet/Opus 4.7
source: "official changelog + own experience"
source_type: upstream
discovered: 2026-06-01
status: inbox
tags: [prompting, system-prompt, headless, cost, performance, upstream]
tested_in: vps-control
incorporated_in: []
replaced_by: null
---

## Description

v2.1.154 ships a **lean default system prompt** — minimal scaffolding loaded on every invocation. Models excepted (still get full prompt): Haiku, Sonnet, Opus 4.7. New Opus 4.8 gets lean by default.

Implication for `claude -p` / headless invocations: the baseline token cost per call drops meaningfully without the user doing anything. But it ALSO means that anyone relying on the old default behavior (skills that assumed certain implicit context, agents tuned to the verbose default) sees a behavior shift on Opus 4.8.

## Evidence

CHANGELOG v2.1.154: "Lean system prompt now default (except Haiku, Sonnet, Opus 4.7 earlier)".

**Independent confirmation from vps-control** (2026-05-31): the watchdog invoked Claude headless via `claude -p` and was loading **117k tokens of cache_creation per invocation** to return a one-line "OK" response (~$0.15 each). After passing `--system-prompt + --disable-slash-commands + --strict-mcp-config + cd /tmp`, cache_creation dropped to **31k tokens** ($0.04) — and with 5min cache hit, to **$0.004**. The 117k baseline is consistent with full CLAUDE.md + skills + MCP servers being auto-discovered; the 31k floor is the Claude Code runtime minimum.

The lean-default change shifts what `claude -p` looks like out of the box on Opus 4.8 — closer to what we engineered manually for headless invocations.

## Impact on dotforge

- `domain/prompting-patterns.md` — new section "Headless invocation cost profile":
  - Document the per-model baseline: lean default on Opus 4.8/Sonnet/Haiku non-applicable; full default on Opus 4.7 (legacy) and pre-v2.1.154 builds.
  - Document the `--system-prompt + --disable-slash-commands + --strict-mcp-config + cd /tmp` pattern with measured savings (117k → 31k → 0 cached).
  - Note the 5min prompt cache TTL interaction: within-5min repeated calls amortize cache_creation to near-zero.
- `agents/_common.md` — for agents that call out to `claude -p` (none today, but if added) document the lean-prompt assumption.
- `docs/best-practices.md` — surface the cost pattern with the vps-control measurement as the concrete example.
- Consider `skills/headless-call` (new skill) — wrapper that codifies the lean invocation pattern for scripts to consume.

## Cost math

For dotforge users running `claude -p` from CI or scripts:
- Pre-fix (Opus 4.7 default): ~$0.15/call, $4.50/day at one call/minute
- Post-fix (lean params): ~$0.04/call cold, $0.004 warm — $0.12 to $1.20/day same cadence
- 12x to 37x cost reduction on identical workload

## Related

- [[opus-4-8-ga]] — lean default ships with 4.8; the cost profile change is implicit there.
