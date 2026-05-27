---
id: practice-2026-05-27-code-review-slash-command
title: /code-review slash command (rename from /simplify) + --fix + --comment (v2.1.147, v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [slash-commands, code-review, github, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
The slash command `/simplify` was renamed to `/code-review` in v2.1.147 and significantly expanded:

- **`/code-review`** — reports correctness bugs at a chosen effort level (e.g., `/code-review high`)
- **`/code-review --comment`** (v2.1.147) — posts findings as inline GitHub PR comments
- **`/code-review --fix`** (v2.1.152) — applies the review findings to the working tree, surfacing reuse, simplification, and efficiency suggestions
- **`/simplify` is now an alias** that invokes `/code-review --fix`

Three independent capabilities under one verb. Different from dotforge's `code-reviewer` subagent (which is a structured-summary code review agent invoked via `Agent(subagent_type="code-reviewer")`). Both can coexist.

## Evidence
CHANGELOG v2.1.147: "Renamed `/simplify` to `/code-review`. It now reports correctness bugs at a chosen effort level (e.g., `/code-review high`); pass `--comment` to post findings as inline GitHub PR comments. The old cleanup-and-fix behavior has been removed".

CHANGELOG v2.1.152: "`/code-review --fix` now applies review findings to your working tree after the review, surfacing reuse, simplification, and efficiency suggestions; `/simplify` now invokes `/code-review --fix`".

## Impact on dotforge
- `docs/claude-vs-forge.md` — slash command tables (EN+ES): `/code-review` joins `/review`/`/security-review` as built-ins
- `.claude/rules/agents.md` — clarify when to delegate to the `code-reviewer` subagent vs invoking `/code-review` directly (subagent for chain-of-review during a complex change; slash command for ad-hoc end-of-PR pass)
- `docs/best-practices.md` — pattern: pre-PR run `/code-review high --comment` to seed inline review before assigning human reviewer

## Decision
Pending
