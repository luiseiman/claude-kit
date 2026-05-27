---
id: practice-2026-05-27-stop-hook-background-tasks-crons
title: Stop and SubagentStop hooks receive background_tasks + session_crons fields (v2.1.145)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [hooks, stop, telemetry, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
`Stop` and `SubagentStop` hook input JSON now includes two new fields:

- **`background_tasks`** — list of `claude --bg` sessions still running when the foreground turn stops
- **`session_crons`** — list of `/schedule`-created crons active in this session

Enables exit-time reporting of pending background work without external probing of state files or `claude agents` JSON.

## Evidence
CHANGELOG v2.1.145: "Stop and SubagentStop hook input now includes `background_tasks` and `session_crons` fields".

`template/hooks/session-report.sh` currently emits per-session metrics on Stop but has no visibility into background work that survives the turn. These fields close that gap.

## Impact on dotforge
- `.claude/rules/domain/hook-events.md` — document the new fields under Stop/SubagentStop
- `template/hooks/session-report.sh` — read both fields, emit `pending_bg_tasks` and `active_crons` counts in the JSON metrics file
- `domain/parallel-sessions.md` — note that Stop hook can observe `--bg` sessions

## Decision
Pending
