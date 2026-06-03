---
id: practice-2026-06-03-workflow-subagents-bypass-permission-mode
title: Workflow subagents always run in acceptEdits, bypassing session permission mode
source: "watch upstream — code.claude.com/docs/en/workflows"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [workflows, permissions, security, ultracode, acceptEdits, plan-mode]
tested_in: null
incorporated_in: [".claude/rules/domain/workflow-automation.md, .claude/rules/domain/workflow-and-ultracode-policy.md, .claude/rules/domain/permission-model.md"]
replaced_by: null
priority: high
---

## Description

Subagents spawned by `/workflows` always run in `acceptEdits` mode regardless of the parent session's permission mode. File edits are auto-approved. The session's permission mode controls ONLY the per-run launch prompt — once the workflow starts, every subagent it spawns edits files without prompting, even if the session is in `plan` mode.

Quote from docs: *"The subagents the workflow spawns always run in `acceptEdits` mode and inherit your tool allowlist, regardless of your session's mode. File edits are auto-approved. Shell commands, web fetches, and MCP tools that aren't in your allowlist can still prompt you mid-run."*

## Evidence

- Source: https://code.claude.com/docs/en/workflows — "Approve the plan before it runs" section
- Direct contradiction with the v3.12.0 ultracode-as-tier-policy assumption that `production` tier projects can rely on `plan` mode enforcement before edits
- `bypassPermissions`, `claude -p`, and Agent SDK never see the launch prompt either

## Security implications

1. **Production-tier projects with plan-mode-as-gate are NOT protected against workflow file edits**. The policy doc (`domain/workflow-and-ultracode-policy.md`) claims production tier → "plan-mode enforced before edits". This holds for direct Claude actions but NOT for workflow-spawned subagents.
2. **Shell commands, web fetches, and MCP tools still prompt** mid-run if not allowlisted — file edits are the asymmetric carve-out
3. **The launch prompt is the only consent point** — Default + acceptEdits modes prompt every run; Auto mode prompts once per workflow per project, then remembers
4. **Mitigation**: deny rules in `permissions.deny` still apply (kernel-level + permission-cascade). For production projects, ensure `deny` covers sensitive paths even when workflow context is acceptable

## Impact on dotforge

- `domain/workflow-automation.md` — add "Permission model" subsection clarifying subagent edit semantics
- `domain/workflow-and-ultracode-policy.md` — update production-tier line: plan-mode does NOT gate workflow-spawned subagent edits; only direct main-thread edits. Reinforce that `deny` rules are the real backstop for irreversible touches.
- `domain/permission-model.md` — note the workflow carve-out as an exception to the 6-mode cascade (specifically plan mode)
- `audit/checklist.md` — production-tier audit item could verify deny rules cover `.env`/keys/credentials AND key infra paths (e.g., `migrations/`, `infrastructure/`) for projects that use workflows

## Decision
Pending
