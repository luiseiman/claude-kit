---
id: practice-2026-05-27-disallowed-tools-frontmatter
title: Skills and slash commands support disallowed-tools frontmatter (v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [skills, frontmatter, security, scope, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
New frontmatter field `disallowed-tools` for skills and slash commands. Companion to the existing `allowed-tools` field, but removes tools FROM the model's visibility while the skill/command is active.

```markdown
---
name: analyze-codebase
description: Read-only architectural analysis
disallowed-tools: [Bash, Write, Edit]
---
```

Pattern enables read-only analytical skills that can `Read`, `Grep`, `Glob` but cannot execute Bash or write files. Useful for:
- Code review / audit skills
- Security analysis (avoids the analyzer becoming a remediation tool by accident)
- Compliance scanning

## Evidence
CHANGELOG v2.1.152: "Skills and slash commands can now set `disallowed-tools` in frontmatter to remove tools from the model while the skill is active".

## Impact on dotforge
- `.claude/rules/domain/rule-effectiveness.md` — add `disallowed-tools` to the frontmatter fields table
- `skills/audit-project/SKILL.md` — candidate: should be read-only (no Bash/Write), this enforces it
- `skills/rule-effectiveness/SKILL.md` — same
- `skills/diff-project/SKILL.md` — same
- `skills/watch-upstream/SKILL.md` — needs Bash/curl, but could disallow Write/Edit
- New pattern guideline in `docs/best-practices.md` for skill scoping

## Decision
Pending
