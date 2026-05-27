---
id: practice-2026-05-27-reload-skills-command
title: /reload-skills slash command — re-scan skills without restart (v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [slash-commands, skills, dx, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
New slash command `/reload-skills`. Re-scans `~/.claude/skills/` and `<project>/.claude/skills/` directories so newly added or modified skills become available in the current session — no restart needed.

Companion to the v2.1.152 `SessionStart` hook output `reloadSkills: true`: the hook can pull skills automatically on startup; the slash command lets the user trigger the same flow on demand mid-session.

Especially useful for dotforge users who:
- Symlink new skills via `global/sync.sh` and don't want to lose context
- Develop skills iteratively (edit SKILL.md, want to test changes immediately)
- Have a `forge:sync` hook that pulls fresh skill versions during the session

## Evidence
CHANGELOG v2.1.152: "Added `/reload-skills` command to re-scan skill directories without restarting the session".

## Impact on dotforge
- `.claude/rules/domain/agent-orchestration.md` or `domain/context-control-patterns.md` — document the command and its pairing with the SessionStart hook field
- `docs/claude-vs-forge.md` — add `/reload-skills` to slash command tables
- `global/sync.sh` — after symlinking new skills, suggest user runs `/reload-skills` (or trigger via the SessionStart hook output if appropriate)

## Decision
Pending
