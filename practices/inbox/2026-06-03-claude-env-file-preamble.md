---
id: practice-2026-06-03-claude-env-file-preamble
title: CLAUDE_ENV_FILE preamble execution across Bash subprocesses
source: "v4 workflow PoC smoke #3 — detected by adversarial verify"
source_type: docs
discovered: 2026-06-03
status: inbox
tags: [hook-events, CLAUDE_ENV_FILE, session-state, direnv-equivalent]
tested_in: null
incorporated_in: []
replaced_by: null
priority: high
---

## Description

`CLAUDE_ENV_FILE` is a session-scoped file that 4 hook events can write to in order to **persist environment variables across all subsequent Bash tool subprocesses** within the session. Claude Code executes the file as a preamble script before each Bash tool invocation. This is the direnv-equivalent built into Claude Code.

The 4 hooks that get access:
- `SessionStart`
- `Setup`
- `CwdChanged`
- `FileChanged`

## Evidence

- Source: code.claude.com/docs/en/hooks (smoke #3 fetch 2026-06-03)
- Mechanism: hook script appends `export FOO=bar` lines to `$CLAUDE_ENV_FILE`
- The file is APPEND-mode — do NOT point it at an existing source script (Claude Code appends to it, would corrupt the source)
- Reference: anthropics/claude-code#19357

## Pattern (direnv-equivalent)

```bash
# SessionStart hook — set baseline env from project
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  if [ -f ".env" ]; then
    grep -v '^#' .env | sed 's/^/export /' >> "$CLAUDE_ENV_FILE"
  fi
fi
```

```bash
# CwdChanged hook — re-source env on directory change
#!/bin/bash
if [ -n "$CLAUDE_ENV_FILE" ]; then
  if [ -f "${new_cwd}/.envrc" ]; then
    cat "${new_cwd}/.envrc" >> "$CLAUDE_ENV_FILE"
  fi
fi
```

## Current dotforge coverage

`domain/hook-events.md` has ONE line under CwdChanged: *"supports CLAUDE_ENV_FILE"*. No mechanics, no scope of which 4 hooks, no append-mode warning, no patterns.

## Impact on dotforge

- `domain/hook-events.md` — expand CLAUDE_ENV_FILE section: 4-hook scope, preamble execution semantics, append-mode warning, SessionStart+CwdChanged direnv pattern
- Project applicability:
  - TRADINGBOT, cotiza-api-cloud (broker credentials per-environment)
  - InviSight-iOS (Supabase tokens per-env)
  - SOMA (Oracle VPS env vars)
  - GCP/AWS projects with cloud creds
- Reduces per-call env injection workarounds in `template/hooks/`

## Decision
Pending
