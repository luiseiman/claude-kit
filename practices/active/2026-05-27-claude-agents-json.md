---
id: practice-2026-05-27-claude-agents-json
title: claude agents --json + filtering and dispatch flags (v2.1.145)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [cli, agents, scripting, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
`claude agents` subcommand expanded with several scripting-friendly flags:

- **`--json`** — emits live sessions as a JSON array. Drop-in for tmux-resurrect, custom status bars, session pickers, dashboard widgets.
- **`--cwd <path>`** — filters the listing to sessions started under that directory. Useful when working across many repos.
- **`--permission-mode <mode>` / `--model <id>` / `--effort <level>`** — set defaults that apply to sessions dispatched FROM the agent view (not retroactive).

Also accepts `--settings`, `--add-dir`, `--plugin-dir`, `--mcp-config` matching the top-level `claude` command, so the dispatched sessions inherit the same configuration shape.

## Evidence
CHANGELOG v2.1.145: "Added `claude agents --json` to list live Claude sessions as JSON for scripting (tmux-resurrect, status bars, session pickers)".

CLI reference (v3.9.0 cutoff already documents `--json` and `--cwd`; the dispatch flags `--permission-mode/--model/--effort` are accurately documented for the dispatched-session-defaults case).

## Impact on dotforge
- `.claude/rules/domain/parallel-sessions.md` — add `--json` and `--cwd` under the background sessions section; clarify that dispatch flags affect newly dispatched sessions only
- `.claude/rules/domain/cli-flags.md` — document under `claude agents` subcommand row
- Potential new skill: `tools/forge-status-bar` that consumes `claude agents --json` for a tmux/zellij status integration (low priority; backlog)

## Decision
Pending
