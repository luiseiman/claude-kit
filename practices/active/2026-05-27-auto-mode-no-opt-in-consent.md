---
id: practice-2026-05-27-auto-mode-no-opt-in-consent
title: Auto mode no longer requires opt-in consent (v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [auto-mode, behavior-change, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
Auto mode now activates directly without prompting for first-use consent. Previously (since GA in v2.1.83), the first time a user enabled auto mode the harness showed a confirmation dialog. As of v2.1.152, that prompt is removed.

Implications:
- Existing settings with `permissions.defaultMode: "auto"` now activate immediately on session start
- CI/headless workflows no longer need to pre-accept the dialog
- A bigger surface for accidental auto-mode if `--permission-mode auto` is in a CI script

## Evidence
CHANGELOG v2.1.152: "Auto mode no longer requires opt-in consent".

## Impact on dotforge
- `.claude/rules/domain/auto-mode.md` — remove any reference to the opt-in prompt; add a note that auto mode now activates immediately
- Verify `permissions.disableAutoMode` is still the canonical way to opt OUT — likely yes, but worth a quick check
- `audit/checklist.md` — possibly elevate auto mode review: if a project sets `defaultMode: "auto"` it now applies without ceremony, so the deny list completeness check (item 13) becomes more critical

## Decision
Pending
