---
id: practice-2026-06-01-settings-hardening-v2140-bundle
title: Settings hardening v2.1.140+ — small additions consolidated
source: "watch upstream — multiple docs"
source_type: docs
discovered: 2026-06-01
activated: 2026-06-01
status: active
tags: [settings, hooks, managed, auto-mode, low-priority-bundle]
tested_in: null
incorporated_in: [".claude/rules/domain/permission-managed-settings.md, .claude/rules/domain/hook-architecture.md, .claude/rules/domain/auto-mode.md, .claude/rules/domain/parallel-sessions.md"]
replaced_by: null
priority: low
---

## Description

Consolidated low-priority gaps from the 2026-06-01 watch run. Each is small and doesn't justify its own practice file. Process as a batch.

## Items

### 1. `claudeMd` inline managed key
- Source: code.claude.com/docs/en/memory
- Embeds org-wide CLAUDE.md content directly in `managed-settings.json` instead of deploying a separate file at `/Library/Application Support/ClaudeCode/CLAUDE.md`
- Example: `"claudeMd": "Always run \`make lint\` before committing.\\nNever push directly to main."`
- **Update**: `.claude/rules/domain/permission-managed-settings.md` — add to enterprise managed settings list

### 2. `workflowKeywordTriggerEnabled` (v2.1.157)
- Source: code.claude.com/docs/en/settings
- Controls whether the literal word "workflow" in a prompt triggers `/workflows` expansion. Default `true`.
- **Update**: `.claude/rules/domain/workflow-automation.md` — already brief mention, expand with default + use case (turn off when team uses "workflow" generically and false-positives waste agents)

### 3. `ConfigChange` hook matcher values
- Source: code.claude.com/docs/en/hooks
- Matcher values: `user_settings`, `project_settings`, `policy_settings`, `skills`
- Use case: detect when a managed admin pushes a settings update; refresh local cache; notify
- **Update**: `.claude/rules/domain/hook-events.md` — add matcher table for ConfigChange

### 4. Unrecognized hook event resilience
- Source: github changelog
- Pre-fix: a typo in any event name silently invalidated the entire `hooks` section (cascade failure)
- Post-fix: typo is logged, rest of `hooks` still loads
- **Update**: `.claude/rules/domain/hook-architecture.md` — note in "Exit codes, types, and decisions" section. Explains historical "why aren't my hooks running" mysteries

### 5. Hook `if:` PowerShell pattern fix
- Source: github changelog
- `if: "PowerShell(git push*)"` style patterns now actually match. Pre-fix, only `PowerShell(*)` worked.
- **Update**: `.claude/rules/domain/hook-architecture.md` "Conditional hooks" section
- Audience: Windows users + `CLAUDE_CODE_USE_POWERSHELL_TOOL=1` on Linux/macOS

### 6. Auto mode on Bedrock / Vertex / Foundry for Opus 4.7 + 4.8
- Source: changelog
- Pre: auto mode was claude.ai/Console only
- Post: enterprise platforms (Bedrock, Vertex, Foundry) now have auto mode for Opus 4.7 and 4.8
- **Update**: `.claude/rules/domain/auto-mode.md` — add "Platform availability" subsection
- Audience: enterprise/regulated users using non-Anthropic-direct deployments

### 7. `CLAUDE_CODE_ADDITIONAL_DIRECTORIES_CLAUDE_MD=1`
- Source: code.claude.com/docs/en/memory
- Loads `CLAUDE.md`, `.claude/rules/*.md`, `CLAUDE.local.md` from `--add-dir` paths (off by default)
- **Update**: `.claude/rules/domain/parallel-sessions.md` — `--add-dir` section

## Decision
Pending — process as batch. If any single item warrants its own practice (e.g., StopFailure-style depth), split out.
