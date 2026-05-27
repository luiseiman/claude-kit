---
id: practice-2026-05-27-model-per-session-default
title: /model is per-session by default; press d to set default for new sessions (v2.1.144)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [model, slash-commands, ux-change, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
UX semantics change in v2.1.144: `/model <id>` now changes the model for the **current session only**. Previously, it mutated `~/.claude/settings.json` so the choice persisted as the default for new sessions.

To set the persistent default, the user must explicitly press `d` in the model picker (`/model` with no args opens the picker).

Implications:
- A trader running multiple bot sessions can switch to Opus 4.7 for the high-stakes one without changing the default for the rest
- CI scripts that do `claude --model X "..." && claude "..."` no longer pick up the first call's choice
- The previous behavior — silent default mutation — was a foot-gun for shared dev machines

## Evidence
CHANGELOG v2.1.144: "`/model` now changes the model for the current session only; press `d` in the model picker to set a default for new sessions".

## Impact on dotforge
- `.claude/rules/domain/model-ids.md` — note the UX semantics and update any examples
- `docs/best-practices.md` — for CI: prefer `--model` flag on each invocation rather than expecting `/model` to leak across processes
- `audit/checklist.md` — if a project pins a model in `settings.json` it remains authoritative; the per-session `/model` change does not override that for the next session

## Decision
Pending
