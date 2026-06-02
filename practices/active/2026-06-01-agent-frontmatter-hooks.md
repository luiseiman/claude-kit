---
id: practice-2026-06-01-agent-frontmatter-hooks
title: Subagents can declare PreToolUse/PostToolUse/Stop hooks in frontmatter
source: "watch upstream — github.com/anthropics/claude-code changelog"
source_type: docs
discovered: 2026-06-01
activated: 2026-06-01
status: active
tags: [agents, subagents, hooks, lifecycle, frontmatter]
tested_in: null
incorporated_in: [".claude/rules/domain/agent-orchestration.md"]
replaced_by: null
priority: medium
---

## Description

Agents now support `hooks` field in frontmatter to define PreToolUse, PostToolUse, and Stop hooks scoped to that subagent's lifecycle. Hooks only fire while the subagent is active — not globally — enabling per-role guardrails (e.g., `security-auditor` blocks all writes; `implementer` runs lint after every Edit) without polluting global `.claude/settings.json` hooks.

## Evidence

- GitHub changelog mention: "Hooks support was added to agent frontmatter, allowing agents to define PreToolUse, PostToolUse, and Stop hooks scoped to the agent's lifecycle"
- Complements existing dynamic permissions from hooks (v2.1.84+) — now both runtime mutation AND declarative agent-scoped enforcement available

## What to document

- Frontmatter `hooks` syntax (mirror of `settings.json.hooks` shape, scoped)
- Scope semantics: fires only when this subagent is the active executor, not parent main thread
- Composition rules: do agent hooks merge with global hooks, or replace? Probably merge — verify in docs
- Use cases per dotforge agent:
  - `code-reviewer`: PostToolUse on Edit/Write → run lint/typecheck, block on errors
  - `security-auditor`: PreToolUse blocking Bash + Write (read-only enforcement)
  - `test-runner`: PostToolUse Bash → parse test results, store in agent-memory
  - `implementer`: Stop → require tests passing before exit
  - `researcher`: PreToolUse denying Edit/Write (transactional, read-only)

## Impact on dotforge

- `agents/*.md` (7 files): add `hooks:` frontmatter where it makes sense
- `.claude/rules/domain/agent-orchestration.md`: document the new scope
- `.claude/rules/domain/hook-architecture.md`: cross-reference under "Plugin system" or new "Agent-scoped hooks" subsection
- Possibly update `agents.md` (rules) with delegation criteria — "use agent X because its hooks enforce Y"

## Decision
Pending
