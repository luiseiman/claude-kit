---
id: practice-2026-06-01-workflows-fifth-primitive
title: /workflows — 5th workflow automation primitive (v2.1.154)
source: "official changelog"
source_type: upstream
discovered: 2026-06-01
status: active
effectiveness: informational
tags: [workflow-automation, agents, orchestration, primitives, upstream]
tested_in: null
incorporated_in: ['3.12.1 (via 2026-06-01-workflows-v2154-full-coverage)']
replaced_by: null
---

## Description

`/workflows` is a new orchestration primitive introduced in v2.1.154. Designed to coordinate **tens-to-hundreds of agents** as a structured workflow — distinct from `/goal` (condition-driven, single thread), `/loop` (cadence-driven polling), `/schedule` (cron-triggered), and `/batch` (fan-out over independent file changes).

The current domain rule `workflow-automation.md` documents 4 primitives. With `/workflows`, the catalogue is **5**. Conceptual gap: dotforge users picking the wrong primitive for a multi-agent orchestration today will reach for `/batch` (no shared state, no inter-dependency) when `/workflows` is the right shape.

## Evidence

CHANGELOG v2.1.154: "Dynamic workflows introduced: `/workflows` orchestrates tens-to-hundreds agents". v2.1.158: "`settings.json` 'Workflow keyword trigger' setting added to prevent 'workflow' from triggering dynamic workflows" — confirms the trigger is active and broad enough to need an opt-out setting.

## Impact on dotforge

- `domain/workflow-automation.md` — add 5th primitive section after `/batch`. Comparison table needs a row. Anti-patterns section needs: "fan-out via `/batch` when teammates must coordinate → use `/workflows`".
- Picking-by-shape decision tree needs an updated entry for multi-agent orchestration.
- `agents/_common.md` Agent Teams section overlaps conceptually with `/workflows` — clarify when to use Agent Teams (handcrafted, ≤4 teammates) vs `/workflows` (dynamic, 10s-100s). Risk: docs duplication if not delimited clearly.
- `claude_kit` skills that orchestrate multi-agent flows (`/forge update`, `/forge insights` parallel scan) — evaluate migration from sequential subagent calls to `/workflows`.

## Open question

`/workflows` is "dynamic" per the changelog — the workflow shape is decided at runtime, not declared. Need to read the official docs to understand: declarative spec? Inferred from prompt? Settings.json schema? Captured here as gap; resolve before incorporating to the domain rule.
