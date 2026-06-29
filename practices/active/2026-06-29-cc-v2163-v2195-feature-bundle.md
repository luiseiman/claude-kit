---
id: practice-2026-06-29-cc-v2163-v2195-feature-bundle
title: "v2.1.163-v2.1.195 feature bundle (Fable 5, nesting, post-session, /cd, /rewind, OTel, etc.)"
source: "/forge watch — github.com/anthropics/claude-code CHANGELOG.md (verified verbatim)"
source_type: changelog
discovered: 2026-06-29
status: active
tags: [claude-code-v2.1.163, claude-code-v2.1.170, claude-code-v2.1.195, ux-bundle, model-ids, agent-orchestration]
tested_in: null
incorporated_in: ["v4.1.0"]
replaced_by: null
priority: medium
---

## Description

Bundle of non-breaking features across versions v2.1.163 → v2.1.195. All quotes verbatim from CHANGELOG.md.

### Model / agents

1. **Claude Fable 5** (v2.1.170) — model ID
   > "Introducing Claude Fable 5: a Mythos-class model that we've made safe for general use. Fable's capabilities exceed those of any model we've ever made generally available."
   - Model ID: `claude-fable-5` (per current session system prompt)
   - Impact: `domain/model-ids.md` — add new tier above Opus

2. **Sub-agent 5-level nesting** (v2.1.172)
   > "Sub-agents can now spawn their own sub-agents (up to 5 levels deep)"
   - Impact: `domain/agent-orchestration.md` — replace "no recursive nesting" assumption with 5-level cap

3. **Agent teams implicit team + nested .claude/ resolution** (v2.1.178)
   > "With `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` set, every session now has one implicit team"
   > "Nested `.claude/` directories: the agent, workflow, and output-style closest to the working directory now wins"
   - Impact: `domain/agent-orchestration.md` (implicit team) + `domain/native-vs-dotforge-boundary.md` (nested-dir resolution)

4. **Bedrock reads AWS region from `~/.aws`** (v2.1.172)
   > "Amazon Bedrock now reads the AWS region from `~/.aws` config files"
   - Impact: `domain/auth.md` — Bedrock config section

### CLI / session

5. **`--safe-mode` flag** (v2.1.169)
   > "Added `--safe-mode` flag (and `CLAUDE_CODE_SAFE_MODE`) to start Claude Code with all customizations disabled"
   - Troubleshooting mode — bypass hooks, skills, plugins
   - Impact: `domain/cli-flags.md` — add to automation/troubleshooting section

6. **`/cd` command** (v2.1.169)
   > "Added `/cd` command to move a session to a new working directory without breaking the prompt cache"
   - Cache-preserving working-dir change
   - Impact: `domain/context-control-patterns.md` or `domain/context-window-optimization.md`

7. **`/rewind` post-/clear** (v2.1.191)
   > "Added `/rewind` support for resuming a conversation from before `/clear` was run"
   - Impact: `domain/context-control-patterns.md` — `/rewind` semantics

8. **`disableBundledSkills` setting** (v2.1.169)
   > "Added a `disableBundledSkills` setting and `CLAUDE_CODE_DISABLE_BUNDLED_SKILLS` environment variable"
   - Skip bundled `/deep-research`, etc. when project ships its own
   - Impact: `domain/rule-effectiveness.md` or settings reference

9. **`CLAUDE_CODE_DISABLE_MOUSE_CLICKS`** (v2.1.195)
   > "Added `CLAUDE_CODE_DISABLE_MOUSE_CLICKS` to disable mouse click/drag/hover in fullscreen mode while keeping wheel scroll"
   - Terminal UX env var
   - Impact: `domain/cli-flags.md` (low priority)

### Hooks / observability

10. **`post-session` hook** (v2.1.169)
    > "Self-hosted runner: added a `post-session` lifecycle hook that runs after the session ends and before the workspace is deleted"
    - Self-hosted runner specific — fires after session end pre-cleanup
    - Impact: `domain/hook-events.md` — add to session-level cadence list

11. **`autoMode.classifyAllShell`** (v2.1.193)
    > "Added `autoMode.classifyAllShell` setting to route all Bash/PowerShell commands through the auto-mode classifier"
    - Tighter auto-mode for projects that want every shell call classified (not just unknowns)
    - Impact: `domain/auto-mode.md` — add to settings table

12. **`claude_code.assistant_response` OTel event** (v2.1.193)
    > "Added `claude_code.assistant_response` OpenTelemetry log event containing the model's response text"
    - Observability — full assistant response capture (PII risk, opt-in pattern)
    - Impact: `domain/agent-orchestration.md` OTel section

### Plugins

13. **`/plugin list`** (v2.1.163)
    > "Added `/plugin list` command to list installed plugins"
    - Impact: `domain/plugin-distribution.md` — CLI subcommands section

## Impact on dotforge files (summary)

- `domain/model-ids.md` — Fable 5 tier
- `domain/agent-orchestration.md` — 5-level nesting, implicit teams, OTel assistant_response
- `domain/cli-flags.md` — `--safe-mode`, `CLAUDE_CODE_DISABLE_MOUSE_CLICKS`
- `domain/context-control-patterns.md` — `/cd`, `/rewind`
- `domain/hook-events.md` — `post-session` lifecycle hook
- `domain/auto-mode.md` — `classifyAllShell`
- `domain/auth.md` — Bedrock region from ~/.aws
- `domain/plugin-distribution.md` — `/plugin list`
- `domain/native-vs-dotforge-boundary.md` — nested `.claude/` "closest wins"
- `domain/rule-effectiveness.md` or settings ref — `disableBundledSkills`

## Decision

Pending — incorporate at next `/forge update`. Medium priority. Process as a single bundle to avoid 13 inbox files. Fable 5 + 5-level nesting are the highest-impact items (affect model-ids and agent-orchestration foundations).
