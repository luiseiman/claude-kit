---
id: practice-2026-06-03-deep-research-bundled-workflow-and-effort-ultracode
title: /deep-research bundled workflow + /effort ultracode runtime activator close the ultracode loop
source: "watch upstream — code.claude.com/docs/en/workflows"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [workflows, ultracode, /deep-research, /effort, runtime-activation, v3.12.0-extension]
tested_in: null
incorporated_in: [".claude/rules/domain/workflow-automation.md, .claude/rules/domain/workflow-and-ultracode-policy.md, .claude/rules/domain/model-ids.md, template/hooks/session-startup.sh"]
replaced_by: null
priority: medium
---

## Description

Two pieces from upstream docs close the loop with v3.12.0 ultracode-as-tier-policy:

1. **`/deep-research <question>`** — Claude Code ships a built-in bundled workflow. Fans out web searches across several angles, fetches and cross-checks sources, votes on each claim, returns a cited report with un-survived claims filtered out. Requires WebSearch tool.

2. **`/effort ultracode`** — runtime activator that combines `xhigh` reasoning effort with automatic workflow orchestration per substantive task. Session-only, resets on new session. Available only on models supporting `xhigh` (Opus 4.7 + 4.8). With it on, Claude plans a workflow for every substantive request — one task can spawn several workflows in sequence (understand → change → verify).

## Evidence

- Source: https://code.claude.com/docs/en/workflows
- v3.12.0 policy doc (`domain/workflow-and-ultracode-policy.md`) defines ultracode as PROJECT POSTURE via registry tier (`light` / `standard` / `heavy` / `production`). Missing: the runtime activation mechanism (`/effort ultracode`) that converts the policy into per-session behavior.
- Approval flow in `Auto` mode: first launch records consent in user settings; later launches skip the prompt. **Skipped entirely when ultracode is on** — consent is implicit.

## Mapping (tier → runtime)

| Tier | Recommended runtime `/effort` | Workflow trigger |
|------|------------------------------|------------------|
| `production` | `ultracode` mandatory | Auto + adversarial verify on every substantive task |
| `heavy` | `ultracode` for architecture/security tasks | Auto for multi-stage |
| `standard` | `high` (default since v2.1.94) | Only when explicitly requested (`ultracode` keyword) |
| `light` | `medium` or `high` | Skip workflows |

## Impact on dotforge

- `domain/workflow-automation.md` — add "Bundled workflows" subsection: document `/deep-research` (the only bundled one as of v2.1.161)
- `domain/workflow-and-ultracode-policy.md` — add "Activation" section: tier (policy) + `/effort ultracode` (runtime) mapping
- `domain/model-ids.md` — effort table: `ultracode` is a tier above `xhigh` that combines xhigh + auto-workflow planning. Available only on Opus 4.7/4.8.
- `template/hooks/session-startup.sh` — for tier `heavy` / `production`, recommend `/effort ultracode` in the startup brief (currently just says "ON for architecture/security tasks"; could be more actionable)

## Decision
Pending
