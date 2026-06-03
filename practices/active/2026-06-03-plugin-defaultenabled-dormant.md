---
id: practice-2026-06-03-plugin-defaultenabled-dormant
title: Plugin defaultEnabled false (v2.1.154) — install dormant pattern
source: "v4 workflow PoC smoke #3 — detected by adversarial verify"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [plugin-distribution, v2.1.154, opt-in, marketplace]
tested_in: null
incorporated_in: [".claude/rules/domain/plugin-distribution.md"]
replaced_by: null
priority: medium
---

## Description

Plugin manifests (and marketplace entries) can declare `defaultEnabled: false`. When set, the plugin installs **dormant** — present on disk but inactive until the user explicitly runs `/plugin` or `claude plugin enable`. Dependencies of an explicitly-enabled plugin still auto-enable. User settings persist across updates (flipping `defaultEnabled` later does not override user's choice).

## Evidence

- Source: code.claude.com/docs/en/changelog (smoke #3 fetch 2026-06-03)
- Quote: *"Plugin Installation Improvements: Plugins can declare defaultEnabled: false; enable via /plugin or claude plugin enable"*
- Version: v2.1.154

## Why this matters for dotforge

dotforge has marketplace submission in flight (per global MEMORY.md: "Plugin submitted 2026-04-05, awaiting review"). When dotforge ships skills via marketplace, the user installs the whole package. Some skills:

- **Have ambient cost** (e.g., periodic hooks, large rule injections)
- **Touch external services** (MCP server connectors, cloud APIs)
- **Are opinionated behaviors** the user may not want by default (e.g., `verify-before-done` strict mode)

For these, opt-in is the right default. The user installs the plugin, opts in to specific skills via `/plugin`.

## Current dotforge coverage

`domain/plugin-distribution.md` covers `${CLAUDE_PLUGIN_DATA}`, multi-seed `CLAUDE_CODE_PLUGIN_SEED_DIR`, marketplace governance, `claude plugin prune`. NO mention of `defaultEnabled: false`. The `plugin-generator` skill does not consider this field.

## Impact on dotforge

- `domain/plugin-distribution.md` — new "Dormant by default" subsection: when to use `defaultEnabled: false`, semantics, dependencies behavior, user-settings persistence
- `skills/plugin-generator/SKILL.md` — when generating plugin manifests, recommend `defaultEnabled: false` by default for:
  - Skills with `${CLAUDE_PLUGIN_DATA}` writes (have state)
  - Skills with MCP server config
  - Opinionated behavior hooks
- Decision tree: opt-out for `init`, `audit`, `sync`, `capture` (core lifecycle, user expects to use). Opt-in for `behavior on/off`, `mcp add`, others

## Decision
Pending
