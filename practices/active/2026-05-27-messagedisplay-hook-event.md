---
id: practice-2026-05-27-messagedisplay-hook-event
title: MessageDisplay hook event — 34th in catalogue, first display-time event (v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [hooks, upstream, new-event, display-time]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
New hook event `MessageDisplay` lets hooks transform or hide assistant message text **as it is displayed** to the user. Bumps the catalogue from 33+ to 34+. First event in a new "display-time" cadence — distinct from all prior events which are control-flow (session/turn/tool-loop/async).

Use cases:
- Output redaction (PII, secrets, internal IDs, API keys leaked in tool output)
- Post-processing markdown (custom rendering, code-block highlighting tweaks)
- Compliance overlays (warnings, attribution badges)

## Evidence
CHANGELOG v2.1.152: "Added a `MessageDisplay` hook event that lets hooks transform or hide assistant message text as it is displayed".

## Impact on dotforge
- `.claude/rules/domain/hook-architecture.md` — bump count 33+ → 34+; add new "Display-level" cadence row to the three lifecycle cadences list
- `.claude/rules/domain/hook-events.md` — new section documenting payload, blocking semantics, and rendering rewrite vs hide
- Potential template hook candidate: `template/hooks/redact-secrets.sh` for projects handling credentials (low priority — most stacks already have `block-destructive` + `.env` deny)

## Decision
Pending
