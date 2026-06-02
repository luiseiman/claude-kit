---
id: practice-2026-06-01-workflows-v2154-full-coverage
title: Complete /workflows v2.1.154 domain rule (resolve TODO)
source: "watch upstream — https://code.claude.com/docs/en/workflows"
source_type: docs
discovered: 2026-06-01
activated: 2026-06-01
status: active
tags: [workflows, multi-agent, orchestration, v2.1.154, domain-rule, TODO]
tested_in: null
incorporated_in: [".claude/rules/domain/workflow-automation.md"]
replaced_by: null
priority: high
---

## Description

Replace the literal `TODO` block in `domain/workflow-automation.md` (line 46) with full coverage of `/workflows` v2.1.154+. Dynamic workflows are JavaScript scripts that Claude writes and a runtime executes in the background, orchestrating tens-to-hundreds of subagents while the session stays responsive.

## Evidence

- Doc: https://code.claude.com/docs/en/workflows (published, no longer placeholder)
- Settings: `disableWorkflows` (kill switch), `workflowKeywordTriggerEnabled` (v2.1.157, suppress accidental "workflow" keyword activation)
- Domain rule explicitly says: `**TODO**: read official docs to document the declarative vs dynamic API surface, settings schema, and concrete examples. This primitive is stubbed here to flag its existence; full coverage pending`

## What to document

- **Declarative meta block**: `export const meta = {name, description, phases}` — pure literal, no computed values
- **Core primitives**: `agent(prompt, opts)`, `parallel(thunks)`, `pipeline(items, ...stages)`, `phase(title)`, `log(message)`
- **Schema validation**: `opts.schema` forces StructuredOutput tool, returns validated object
- **Concurrency cap**: `min(16, cpu cores - 2)` per workflow, 1000 agents lifetime backstop
- **Budget integration**: `budget.total`, `budget.spent()`, `budget.remaining()` — hard ceiling, throws when exhausted
- **Resume**: `Workflow({scriptPath, resumeFromRunId})` — cached agent() calls return instantly, first edited/new call runs live
- **Pipeline vs parallel barrier semantics**: pipeline is the default; parallel is a barrier — only when stage N needs cross-item context from all of N-1
- **Quality patterns**: adversarial verify (≥majority refute), perspective-diverse verify, judge panel, loop-until-dry, multi-modal sweep, completeness critic
- **Availability**: requires v2.1.154+, all paid plans + Anthropic API + Bedrock + Vertex + Foundry
- **Use cases**: codebase-wide bug sweep, 500-file migration, multi-source research, multi-angle planning

## Impact on dotforge

- `.claude/rules/domain/workflow-automation.md` — replace TODO section (~50 lines added)
- Possible new skill: `skills/forge-workflow/SKILL.md` if we want a `/forge workflow <name>` wrapper to dispatch saved workflows
- `agents/*.md` — note that workflows complement (don't replace) Agent Teams (≤4 teammates handcrafted vs dynamic at scale)

## Decision
Pending
