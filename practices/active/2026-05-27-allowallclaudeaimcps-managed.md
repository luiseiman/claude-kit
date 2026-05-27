---
id: practice-2026-05-27-allowallclaudeaimcps-managed
title: allowAllClaudeAiMcps managed setting — load cloud connectors alongside managed-mcp.json (v2.1.149)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [managed-settings, mcp, enterprise, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
New managed-settings key `allowAllClaudeAiMcps`. When set in `managed-settings.json`, loads ALL claude.ai cloud MCP connectors alongside the entries in `managed-mcp.json`. Without it, only the explicit `managed-mcp.json` allowlist applies.

Enterprise use case: a security team curates `managed-mcp.json` with vetted internal MCP servers but wants to allow ad-hoc claude.ai-managed connectors (Linear, Slack, Notion, etc.) without enumerating each.

## Evidence
CHANGELOG v2.1.149: "Enterprise: added the `allowAllClaudeAiMcps` managed setting to load claude.ai cloud MCP connectors alongside `managed-mcp.json`".

## Impact on dotforge
- `.claude/rules/domain/permission-managed-settings.md` — add to the managed-settings keys list
- `audit/checklist.md` — for enterprise audits, possibly add a check: if both `managed-mcp.json` exists AND `allowAllClaudeAiMcps: true`, that combination should be intentional (verify it's not accidentally loading shadow IT MCPs)

## Decision
Pending
