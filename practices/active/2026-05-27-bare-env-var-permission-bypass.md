---
id: practice-2026-05-27-bare-env-var-permission-bypass
title: Bare env var assignments to non-allowlisted vars auto-approved in Bash (v2.1.145 security fix)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [security, permissions, bash, breaking-fix, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v391"]
replaced_by: null
---

## Description
**Permission bypass** fixed in v2.1.145: bare environment variable assignments to non-allowlisted vars in Bash commands were auto-approved during permission analysis. Concretely, `FOO=bar some-command` (without exporting) would silently bypass permission rules that should have flagged it. The known-safe env-var list (`LANG`, `TZ`, `NO_COLOR`, etc.) was being applied too permissively to any inline assignment.

Affects any project relying on Bash permission rules with env-var prefix detection (most dotforge stacks).

## Evidence
CHANGELOG v2.1.145: "Fixed a permission-prompt bypass where bare variable assignments to non-allowlisted environment variables in Bash commands were auto-approved".

## Impact on dotforge
- `.claude/rules/domain/permission-model.md` — Bash prefix detection section: note that v2.1.145 corrects env-var assignment handling; projects running older Claude Code versions may have had silent auto-approvals
- `.claude/rules/domain/auto-mode.md` — `auto mode` permission stripping section already discusses env-var prefix handling (`env`, `xargs`, etc.); add the bare-assignment case
- Cross-check `template/hooks/block-destructive.sh` regex: if it pattern-matches against the full command string (which it does per v2.1.119 hardening), it should have caught these even when permission detection didn't — confirm with a test case

## Decision
Pending
