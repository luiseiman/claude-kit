---
id: practice-2026-06-03-hook-output-10k-cap
title: Hook output 10K char cap on additionalContext/systemMessage/stdout (BREAKING)
source: "v4 workflow PoC smoke #3 — detected by adversarial verify"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [hook-events, breaking, compact, dotforge-hooks-affected]
tested_in: null
incorporated_in: [".claude/rules/domain/hook-events.md, .claude/rules/domain/compaction-strategy.md"]
replaced_by: null
priority: high
---

## Description

The three primary context-injection channels in hooks — `additionalContext`, `systemMessage`, and plain stdout — now have a **10,000-character cap** (separate from the older 50K spill-to-file behavior). When output exceeds 10K chars, it is saved to a file in the session directory and the model receives a pointer-with-preview instead of inline content.

## Evidence

- Source: code.claude.com/docs/en/hooks (smoke #3 fetch 2026-06-03)
- Quote: *"Existing fields now capped at 10,000 characters: additionalContext, systemMessage, plain stdout. Excess output saved to file with preview + path"*
- Differs from the earlier v2.1.89 generic 50K hook-output-to-file rule

## Why this is breaking for dotforge

dotforge's `post-compact.sh` + `scripts/compact-filter.py` were designed against the **50K threshold** for the compact summary inject. With the new 10K cap on `additionalContext`:

- Moderately-filtered compact summaries (between 10K and 50K chars) will SPILL to file
- The model will see `pointer-with-preview` instead of the full summary inline
- `session-restore.sh` and `session-startup.sh` also inject context via `additionalContext` — same risk

## Impact on dotforge

- `domain/hook-events.md` — "Hook JSON output fields (universal)" section: document the dual threshold (10K specific channels vs 50K generic)
- `domain/compaction-strategy.md` — note new effective cap for compact summary injection
- `scripts/compact-filter.py` — re-tune to target ≤10K instead of 50K
- `template/hooks/post-compact.sh` — verify it doesn't emit `additionalContext` > 10K post-filter
- `template/hooks/session-restore.sh` — same audit
- `template/hooks/session-startup.sh` — same audit
- Audit checklist consideration: warn projects with compact-filter targeting old 50K threshold

## Decision
Pending
