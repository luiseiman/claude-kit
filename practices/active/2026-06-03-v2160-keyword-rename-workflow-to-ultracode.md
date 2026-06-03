---
id: practice-2026-06-03-v2160-keyword-rename-workflow-to-ultracode
title: v2.1.160 renames workflow trigger keyword "workflow" → "ultracode"
source: "watch upstream — code.claude.com/docs/en/workflows"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [v2.1.160, workflows, ultracode, keyword-trigger, anti-confusion]
tested_in: null
incorporated_in: [".claude/rules/domain/workflow-automation.md"]
replaced_by: null
priority: medium
---

## Description

Before v2.1.160 the literal trigger keyword for `/workflows` was `workflow`. From v2.1.160 onwards it is `ultracode`. The setting key `workflowKeywordTriggerEnabled` is unchanged (still works) — only the literal word being matched in the prompt changed.

Natural-language requests ("use a workflow", "run a workflow") still trigger workflow expansion in both versions.

## Evidence

- Source: https://code.claude.com/docs/en/workflows — *"Before v2.1.160 the literal trigger keyword was `workflow`; natural-language requests work in both versions."*
- The rename aligns with `/effort ultracode` and the workflow approval card title

## Anti-confusion implications

1. **Users typing "workflow ..." in v2.1.160+ no longer trigger workflow expansion**. They get a normal turn-by-turn response. May appear as a regression if they relied on the keyword trigger.
2. **Users typing "ultracode" thinking they're invoking the policy POSTURE (v3.12.0 ultracode-tier semantics) WILL trigger a workflow** if `workflowKeywordTriggerEnabled` is on (default). This is the inverse risk: accidental workflow activation when meaning "ultracode tier".
3. **Dismiss keyword**: `Option+W` macOS / `Alt+W` Windows-Linux while cursor is after the highlighted keyword (or backspace).
4. **Disable globally**: `/config` → "Ultracode keyword trigger" toggle (UI label changed from "Workflow keyword trigger").

## Impact on dotforge

- `domain/workflow-automation.md` — Settings section: clarify keyword trigger value rename. Update `workflowKeywordTriggerEnabled` description from "controls whether literal word 'workflow' in prompt triggers expansion" to "controls whether literal word 'ultracode' (v2.1.160+) or 'workflow' (pre-v2.1.160) in prompt triggers expansion. Default `true`."
- `domain/workflow-and-ultracode-policy.md` — add anti-confusion warning: when documenting "this project is ultracode tier", do NOT use the literal word "ultracode" in CLAUDE.md unless intended as a workflow trigger. Prefer "ultracode-tier", "ultracode posture", or "ultracode mode".
- `template/hooks/session-startup.sh` — startup brief currently emits `**Ultracode tier:** heavy — ...`. Verify this string doesn't trigger workflow expansion (it goes to display, not user prompt input, so should be safe — but worth noting).

## Decision
Pending
