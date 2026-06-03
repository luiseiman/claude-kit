---
id: practice-2026-06-03-v2158-v2161-small-additions-bundle
title: v2.1.158-v2.1.161 small additions consolidated
source: "watch upstream — multiple"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [v2.1.158, v2.1.160, v2.1.161, mantle, OTEL, MCP, low-priority-bundle]
tested_in: null
incorporated_in: [".claude/rules/domain/auto-mode.md, .claude/rules/domain/auth.md, .claude/rules/domain/permission-managed-settings.md, .claude/rules/domain/sandboxing.md, .claude/rules/domain/agent-orchestration.md, .claude/rules/domain/parallel-sessions.md"]
replaced_by: null
priority: low
---

## Description

Consolidated low-priority gaps from the 2026-06-03 watch run. Each is small. Process as a batch.

## Items

### 1. `CLAUDE_CODE_ENABLE_AUTO_MODE=1` opt-in for Bedrock/Vertex/Foundry (v2.1.158)
- Auto mode on enterprise platforms requires this env var to opt in (separate from claude.ai/Console where auto mode is always available with tier gate)
- **Update**: `domain/auto-mode.md` — extend "Enterprise platforms (2026)" line with explicit env var requirement

### 2. Mantle as new enterprise provider (v2.1.161 mention)
- v2.1.161 fix mentioned "Bedrock, Vertex, Foundry, Mantle" — first mention of Mantle as supported third-party provider
- Status: unknown if Mantle is a new Anthropic-deployed surface or a third-party reseller; needs follow-up
- **Update**: `domain/auth.md`, `domain/auto-mode.md`, `domain/permission-managed-settings.md`, `domain/cli-flags.md` — add Mantle to enterprise platforms list (with "verify scope" tag until docs confirm)

### 3. Single-file grep satisfies read-before-edit (v2.1.160)
- Pre-fix: grepping a file did NOT count as "having read it" — Edit would prompt for the file to be Read first
- Post-fix: single-file `grep`/`egrep`/`fgrep` now counts. Multi-file searches still don't.
- **Update**: `domain/agent-orchestration.md` — researcher patterns can use grep for single-file lookups; `agents/researcher.md` (no change, just confirms current pattern works)

### 4. OTEL_RESOURCE_ATTRIBUTES + tool_parameters (v2.1.161)
- `OTEL_RESOURCE_ATTRIBUTES` values now included as labels on metric datapoints — enables slicing by team/repo
- `tool_decision` events include `tool_parameters` when `OTEL_LOG_TOOL_DETAILS=1`
- **Update**: `domain/agent-orchestration.md` OpenTelemetry subsection — extend with metric-labels and tool-parameters opt-in

### 5. `claude agents` shows done/total (v2.1.161)
- Background sessions in `claude agents` view now display `done/total` count before detail
- **Update**: `domain/parallel-sessions.md` — background sessions subsection

### 6. `claude mcp` no longer prints ${VAR}-expanded secrets (v2.1.161 fix)
- `claude mcp list/get/add` was printing secrets verbatim, expanding `${VAR}` against subprocess env
- Post-fix: `${VAR}` no longer expanded in CLI output. Safer to dump configs.
- **Update**: `domain/permission-managed-settings.md` — MCP server config security note; `domain/cli-flags.md` — `claude mcp` subcommand note

### 7. Workflow worktree isolation fix (v2.1.161)
- v2.1.149 sandbox scope correction was over-strict for workflow agents — `isolation: "worktree"` agents couldn't write into their own worktree
- v2.1.161 restores correct scope: writes to the agent's own worktree allowed
- **Update**: `domain/sandboxing.md` — "Worktree allowlist scope fix" section: add the v2.1.149 → v2.1.161 regression-and-fix history

## Decision
Pending — process as batch. Split if any single item warrants own practice (e.g., Mantle if it turns out to be more than a name).
