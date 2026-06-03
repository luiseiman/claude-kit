---
id: practice-2026-06-03-sessionstart-watchpaths
title: SessionStart.watchPaths registers persistent FileChanged matchers (drift detection)
source: "v4 workflow PoC smoke #3 — detected by adversarial verify"
source_type: docs
discovered: 2026-06-03
status: inbox
tags: [hook-events, SessionStart, FileChanged, drift-detection, governance]
tested_in: null
incorporated_in: []
replaced_by: null
priority: high
---

## Description

`SessionStart` hooks can return `hookSpecificOutput.watchPaths` (array of file paths). Claude Code registers these paths with the OS-level file watcher (FSEvents on macOS, inotify on Linux). For the rest of the session, modifications to any registered path automatically fire `FileChanged` events — no polling needed, millisecond latency.

## Evidence

- Source: code.claude.com/docs/en/hooks (smoke #3 fetch 2026-06-03)
- Quote: *"watchPaths: Array of paths to monitor for FileChanged events during session"*
- Quote: *"Now supports persistent watch paths via SessionStart hook's watchPaths field"*
- Grep in current dotforge: 0 occurrences of `watchPaths` — completely absent from coverage

## Why this is powerful for governance

dotforge currently validates governance-critical files (`settings.json`, `behaviors/index.yaml`, `.claude/rules/*.md`) ONLY at session boundaries via `template/hooks/pre-session-check.sh` (Setup hook). Mid-session drift is invisible until next session.

`watchPaths` enables real-time drift detection:
- User edits `.claude/settings.json` manually mid-session → FileChanged fires immediately
- A subagent modifies `behaviors/index.yaml` → FileChanged fires before next tool call
- Governance audit can react inline, not days later

## Implementation pattern

```bash
# template/hooks/session-startup.sh — extend existing hook
#!/bin/bash
cat <<EOF
{
  "hookSpecificOutput": {
    "additionalContext": "...",
    "watchPaths": [
      ".claude/settings.json",
      ".claude/rules/_common.md",
      ".claude/rules/agents.md",
      "behaviors/index.yaml"
    ]
  }
}
EOF
```

Then `template/hooks/session-startup.sh` or new `template/hooks/governance-drift.sh` wired to `FileChanged` matchers handles the reaction.

## Current dotforge coverage

ZERO. `domain/hook-events.md` documents FileChanged as a separate event and SessionStart separately. The pairing — and the registration mechanism via `watchPaths` — is not documented anywhere.

## Impact on dotforge

- `domain/hook-events.md` — new section pairing SessionStart.watchPaths ↔ FileChanged. Document FSEvents/inotify, ms latency, no polling
- `template/hooks/session-startup.sh` — extend to emit `watchPaths` for governance-critical files
- `template/hooks/` — new `governance-drift.sh` wired to `FileChanged` matchers that re-run validation when watched files change mid-session
- Audit checklist consideration: new item "uses watchPaths for governance file drift detection"

## Decision
Pending
