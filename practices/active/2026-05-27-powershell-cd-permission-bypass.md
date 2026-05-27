---
id: practice-2026-05-27-powershell-cd-permission-bypass
title: PowerShell cd.. cd\ cd~ X: built-in functions bypassed permission detection (v2.1.149 security fix)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [security, permissions, powershell, windows, breaking-fix, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v391"]
replaced_by: null
---

## Description
**Security vulnerability** in PowerShell tool fixed in v2.1.149: built-in `cd` functions (`cd..`, `cd\`, `cd~`, `X:`) changed the working directory without being detected by the permission analyzer. A subsequent command in the same PowerShell call could then read files outside the workspace boundary.

Affects all Windows users of the PowerShell tool — relevant for `python-fastapi` projects with Windows devs, any project that opts into PowerShell via `CLAUDE_CODE_USE_POWERSHELL_TOOL=1`, and Linux/macOS users running PowerShell scripts.

Related v2.1.149 fix: the parser trusted stale `PWD`/`OLDPWD`/`DIRSTACK` variable-tracking across `cd`/`pushd`/`popd` — same bypass class.

## Evidence
CHANGELOG v2.1.149: "Fixed a PowerShell permission bypass: built-in `cd` functions (`cd..`, `cd\`, `cd~`, `X:`) changed the working directory undetected, letting a later command read outside the workspace" + "Fixed a permission-analysis gap where the parser trusted stale variable-tracking values for `PWD`/`OLDPWD`/`DIRSTACK` across `cd`/`pushd`/`popd`".

## Impact on dotforge
- `.claude/rules/domain/permission-model.md` — Bash prefix detection section: add a "PowerShell parallel" subsection noting the v2.1.149 fix and the implication for projects that ran on older Claude Code versions (any permission audit prior to v2.1.149 may have false negatives)
- `.claude/rules/domain/sandboxing.md` — emphasize that `filesystem.denyRead` covers the kernel-enforced boundary even when permission detection lapses; reinforces the defense-in-depth message
- `CLAUDE_ERRORS.md` candidate entry for projects with Windows devs

## Decision
Pending
