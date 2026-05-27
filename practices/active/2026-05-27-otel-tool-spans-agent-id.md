---
id: practice-2026-05-27-otel-tool-spans-agent-id
title: OTEL claude_code.tool spans now include agent_id + parent_agent_id (v2.1.145)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [otel, tracing, agents, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
Two improvements in v2.1.145 OpenTelemetry instrumentation:

1. **`claude_code.tool` spans** now carry `agent_id` and `parent_agent_id` attributes. Previously these were only on `claude_code.llm_request` spans (added v2.1.139). Tool spans missing the attribution made it impossible to trace which subagent invoked a Bash tool call.
2. **Trace parenting fixed**: background subagent spans now correctly nest under the dispatching `Agent` tool span. Before, background spans were emitted as roots, breaking the agent-tree visualization in trace explorers.

Combined effect: distributed tracing of agent trees is now complete — every span (LLM request and tool call) carries enough attribution to reconstruct the parent-child agent hierarchy.

## Evidence
CHANGELOG v2.1.145: "Added `agent_id` and `parent_agent_id` attributes to `claude_code.tool` OTEL spans, and fixed trace parenting so background subagent spans nest under the dispatching Agent tool span".

## Impact on dotforge
- `.claude/rules/domain/agent-orchestration.md` — there's already a brief mention of OTEL `agent_id` on LLM requests (v3.8.0); extend to cover tool spans and the trace-parenting fix
- `.claude/rules/domain/hook-events.md` — Agent events section mentions subagent header attrs (v2.1.139+); add the v2.1.145 expansion
- Worth documenting somewhere (best-practices?) for teams instrumenting Claude Code with their own OTEL collector — pre-v2.1.145 traces have incomplete attribution and broken parenting for background subagents

## Decision
Pending
