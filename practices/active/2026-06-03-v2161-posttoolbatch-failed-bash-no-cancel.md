---
id: practice-2026-06-03-v2161-posttoolbatch-failed-bash-no-cancel
title: v2.1.161 PostToolBatch — failed Bash no longer cancels other parallel calls
source: "watch upstream — github.com/anthropics/claude-code/releases/tag/v2.1.161"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [v2.1.161, hooks, PostToolBatch, parallel, behavior-change]
tested_in: null
incorporated_in: [".claude/rules/domain/hook-events.md, .claude/rules/domain/auto-mode.md"]
replaced_by: null
priority: medium
---

## Description

Pre-v2.1.161: when Claude issued multiple Bash tool calls in parallel (single message, multiple tool blocks) and one failed, the remaining calls in the same batch were CANCELLED. Post-fix: the failure is isolated — other calls complete and their results flow through normally.

Direct effect on `PostToolBatch` hooks: the batch now always sees all results from all dispatched tools, not just the survivors before the first failure. Hook logic that assumed "if I see N results, all N succeeded" is no longer valid — the hook must inspect per-tool success/failure.

## Evidence

- Source: https://github.com/anthropics/claude-code/releases/tag/v2.1.161
- Quote: *"Parallel tool calls: failed Bash command no longer cancels other calls in same batch"*

## Implications

1. **`PostToolBatch` hooks that gate on batch atomicity** (e.g., "block if ALL tests passed" assuming all calls succeeded) must be updated to count successes vs failures explicitly
2. **Concurrent-safe Bash assumption changes**: pre-fix, a failed Bash effectively serialized the batch (cancellation = synchronization point). Post-fix, true concurrency. Bash is still listed as "not concurrent-safe" in the tool concurrency table — that classification was about kernel-level concurrency (filesystem race conditions), not batch semantics.
3. **Independent of `continueOnBlock`** — that's a v2.1.139 feature for `PostToolUse` `decision: "block"`. Different mechanism.

## Impact on dotforge

- `domain/hook-events.md` — add note to PostToolBatch section: "Post-v2.1.161, the batch sees ALL dispatched results regardless of individual failures. Inspect per-tool success in the array; don't assume atomicity."
- `domain/auto-mode.md` — Tool concurrency table is still accurate (Bash = not concurrent-safe at filesystem level), but add a parenthetical note that batch-level failure isolation is new in v2.1.161
- `template/hooks/session-report.sh` — if it ever consumes PostToolBatch payloads, validate per-tool inspection (currently only Stop hook, so unaffected)

## Decision
Pending
