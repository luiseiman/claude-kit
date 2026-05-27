---
id: practice-2026-05-27-sandbox-worktree-allowlist-scope-bug
title: Sandbox write allowlist covered main repo root instead of shared .git in worktrees (v2.1.149 security fix)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [security, sandbox, worktree, scope-bug, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v391"]
replaced_by: null
---

## Description
**Sandbox scope bug** fixed in v2.1.149: when working inside a git worktree, the sandbox's automatic write allowlist for the shared `.git` directory was instead covering the **entire main repository root**. Effectively meant code running in a worktree had sandbox-blessed write access to the main repo's files (with `hooks/` and `config` denied as exceptions).

Affects: any project using `claude --worktree` with `sandbox.enabled: true`. dotforge's Agent Teams pattern uses worktree isolation as standard, so this overlaps with our security story.

Post-fix: sandbox correctly restricts the write allowlist to just the shared `.git` directory (the subset that worktrees legitimately share).

## Evidence
CHANGELOG v2.1.149: "Fixed the sandbox write allowlist in git worktrees covering the entire main repository root instead of only the shared `.git` directory (with `hooks/` and `config` denied)".

## Impact on dotforge
- `.claude/rules/domain/sandboxing.md` — add a note about worktree scope; if the rule recommends sandbox + worktree as a combined defense, verify it doesn't assume the broader (buggy) scope
- `.claude/rules/agents.md` (Agent Teams section) — if teammates with `isolation: "worktree"` rely on write access to main repo, that pattern was wrong; verify and call out
- Pre-v2.1.149 projects auditing sandbox effectiveness should re-test now that scope is correct

## Decision
Pending
