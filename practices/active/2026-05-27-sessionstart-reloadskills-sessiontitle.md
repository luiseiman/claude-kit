---
id: practice-2026-05-27-sessionstart-reloadskills-sessiontitle
title: SessionStart hooks support reloadSkills + sessionTitle output (v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [hooks, sessionstart, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
Two new fields available in `SessionStart` hook JSON output via `hookSpecificOutput`:

1. **`reloadSkills: true`** — instructs the harness to re-scan skill directories within the same session. A SessionStart hook that installs or generates skills no longer needs the user to restart.
2. **`sessionTitle: "..."`** — sets the session display title. Previously only `UserPromptSubmit` hooks could set it (v2.1.94). Now `SessionStart` can do it on startup AND resume, enabling deterministic naming from project state (branch, CWD, plan file) before the first prompt.

```json
{
  "hookSpecificOutput": {
    "reloadSkills": true,
    "sessionTitle": "feat/auth-refactor"
  }
}
```

## Evidence
CHANGELOG v2.1.152:
- "`SessionStart` hooks can now return `reloadSkills: true` to re-scan skill directories, making skills installed by the hook available in the same session"
- "`SessionStart` hooks can now set the session title via `hookSpecificOutput.sessionTitle` on startup and resume"

## Impact on dotforge
- `.claude/rules/domain/hook-events.md` — update `SessionStart` section with both new output fields
- `template/hooks/session-startup.sh` — candidate to read git branch and set `sessionTitle` automatically (e.g., `<branch>-<short-hash>`)
- `template/hooks/check-updates.sh` — if a dotforge update installs new skills, can pair with `reloadSkills: true` so user doesn't need to restart

## Decision
Pending
