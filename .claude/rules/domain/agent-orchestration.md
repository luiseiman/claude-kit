---
globs: "**/agents/*.md,**/rules/agents.md"
description: "Agent delegation patterns and team coordination"
domain: claude-code-engineering
last_verified: 2026-05-27
---

# Agent Orchestration

## Subagent architecture (source-verified)

- Each subagent gets independent context window — genuinely isolated from main thread
- Full tool access: Bash, Edit, Write, Read, Glob, Grep, etc.
- Fork subagents share parent prompt cache (Anthropic caching API) — saves tokens
- Max 10 concurrent tool executions across all agents (`gW5 = 10`)
- `shouldAvoidPermissionPrompts: true` for background agents (auto-deny, no UI)

## Task types

- `local_agent` — sub-agent via AgentTool (standard delegation)
- `remote_agent` — remote execution
- `in_process_teammate` — shared memory (Coordinator mode)
- `dream` — auto-dream background memory consolidation

## Delegation rules

- Decision tree: 1-file fix → direct. Research-heavy → researcher. Code+tests → implementer
- Multi-component (>3 files, >2 concerns) → Agent Team
- Agent Team: Lead (coordinates, does NOT implement) + max 3-4 teammates
- Each teammate MUST use isolation: "worktree" (confirmed by EnterWorktree/ExitWorktree tools)
- Sequential chaining: researcher → architect → implementer → test-runner → code-reviewer
- NEVER spawn new agent for follow-ups — use SendMessage({to: agentId}) to continue
- `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1` env var: enables native Agent Teams (research preview, requires Opus)

## Memory and lifecycle

- Memory agents: architect, implementer, code-reviewer, security-auditor, session-reviewer (persist in .claude/agent-memory/)
- Transactional agents: researcher, test-runner (execute and report, no memory)
- Dynamic loading from `~/.claude/agents/` — custom agent definitions auto-discovered
- Subagent output must not exceed 30% of main context — always structured summaries
- Always verify subagent output (run tests/lint) before declaring task done
- `/reload-skills` slash command (v2.1.152+) re-scans skill directories in the current session without restart — pair with the SessionStart hook field `reloadSkills: true` if a hook installs skills

## Agent-scoped hooks (frontmatter `hooks:`)

Agents can declare `PreToolUse`, `PostToolUse`, and `Stop` hooks in their frontmatter, scoped to that subagent's lifecycle. Hooks fire ONLY while that subagent is the active executor — not globally — enabling per-role guardrails without polluting `.claude/settings.json`.

Use cases per dotforge agent role:

| Agent | Event | Purpose |
|-------|-------|---------|
| `code-reviewer` | PostToolUse on `Edit\|Write` | Run lint/typecheck; block on errors via `decision: "block"` (or `continueOnBlock: true` for self-healing) |
| `security-auditor` | PreToolUse on `Bash\|Write\|Edit` | Read-only enforcement — auto-deny mutations (defense-in-depth atop `allowed-tools:`) |
| `test-runner` | PostToolUse on `Bash` | Parse test results from output; persist failures into agent-memory |
| `implementer` | Stop | Refuse exit unless tests passed for files touched this session |
| `researcher` | PreToolUse on `Edit\|Write` | Belt-and-suspenders deny (already restricted via `allowed-tools:`) |
| `architect` | PreToolUse on `Edit\|Write` | Plan-mode enforcement — block until plan accepted |
| `session-reviewer` | PostToolUse | Capture corrections/patterns for `/forge insights` feeding |

Composition with global hooks: agent hooks **merge** with `.claude/settings.json` hooks — both run. Static deny rules cannot be removed by agent-scoped hooks. Schema mirrors the top-level `hooks` object shape.

**Status in dotforge (2026-06-01)**: documented architecturally here; not yet wired into `agents/*.md` files pending empirical schema verification against upstream docs. When adopting, validate against `code.claude.com/docs/en/sub-agents` and test in `agents/test-runner.md` first (lowest blast radius).

## OpenTelemetry instrumentation (v2.1.139+, v2.1.145+)

- `claude_code.llm_request` spans carry `agent_id` and `parent_agent_id` attributes (v2.1.139+)
- `claude_code.tool` spans carry the same attributes since v2.1.145 — pre-v2.1.145 tool spans lacked agent attribution
- Trace parenting fixed in v2.1.145: background subagent spans correctly nest under the dispatching Agent tool span (before, they were roots — broke the agent-tree visualization)
- Combined effect: distributed tracing of agent trees is now complete

## Related: top-level parallelism

Subagents share the main session's working tree. For independent top-level Claude instances (worktrees, `--fork-session`, `--teleport`, `--bare`, `--add-dir`, `--agents` inline JSON), see `parallel-sessions.md`.

## Slash command priority (collision risk)

bundledSkills > builtinPluginSkills > skillDirCommands > workflowCommands > pluginCommands > pluginSkills > COMMANDS()

Skills installed via dotforge can shadow built-in commands if names collide — be intentional about naming.

## Model self-invocation of slash commands (v2.1.108+)

Since v2.1.108, the model can invoke slash commands directly in its tool-use loop — previously user-only. Implication for skill design:

- Destructive or state-mutating commands (reset, unregister, capture) should set `disable-model-invocation: true` (v2.1.111+) to stay user-gated
- `user-invocable: true` by itself no longer restricts the model — both flags needed for full gating
- Audit `global/commands/` and `skills/*/SKILL.md` when introducing new commands: ask "do I want the model to self-trigger this?"
