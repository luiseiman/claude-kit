---
id: practice-2026-06-29-cc-v2195-hook-matcher-breaking
title: "BREAKING — Hook matchers with hyphens now exact-match (v2.1.195)"
source: "/forge watch — github.com/anthropics/claude-code CHANGELOG.md (verified verbatim)"
source_type: changelog
discovered: 2026-06-29
status: active
tags: [claude-code-v2.1.195, breaking, hook-architecture, agent-orchestration]
tested_in: null
incorporated_in: ["v4.1.0"]
replaced_by: null
priority: high
---

## Description

**BREAKING change.** v2.1.195 changelog (verbatim):
> "Fixed hook matchers with hyphenated identifiers (e.g. `code-reviewer`, `mcp__brave-search`) accidentally substring-matching — they now exact-match."

Pre-v2.1.195, a hook with `matcher: "code-reviewer"` would also fire on `code-reviewers`, `my-code-reviewer`, etc. Post-fix, only exact `code-reviewer` matches.

## Why this matters for dotforge

- `agents/code-reviewer.md` — name contains hyphen. Any hook config keying off this matcher needs verification
- `agents/security-auditor.md`, `agents/session-reviewer.md`, `agents/test-runner.md` — same pattern
- MCP server names with hyphens (e.g. `mcp__brave-search`) — any hooks gating on those matchers
- Stack-level hooks that use wildcarded matchers may have silently relied on substring behavior

## Impact on dotforge files

- `domain/hook-architecture.md` — document the exact-match semantics for matchers
- `agents/agent-orchestration.md` — note implications for hyphenated agent names
- Audit `.claude/settings.json.tmpl` and `stacks/*/settings.json.partial` for hook matchers using hyphens — verify each is intentional exact-match, not substring

## Decision

Pending — incorporate at next `/forge update`. **High priority** because BREAKING. Audit hook configs before propagating template change.
