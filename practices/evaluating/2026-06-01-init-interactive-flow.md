---
id: practice-2026-06-01-init-interactive-flow
title: /init interactive multi-phase flow (CLAUDE_CODE_NEW_INIT=1)
source: "watch upstream — code.claude.com/docs/en/memory"
source_type: docs
discovered: 2026-06-01
status: evaluating
tags: [init, ux, forge-init, subagent, bootstrap, needs-empirical-test]
tested_in: null
incorporated_in: []
replaced_by: null
priority: medium
---

## Description

Setting `CLAUDE_CODE_NEW_INIT=1` enables an interactive multi-phase `/init` flow: asks which artifacts to set up (CLAUDE.md / skills / hooks), explores the codebase via a subagent, fills gaps via follow-up questions, and presents a reviewable proposal **before writing any files**. This is the upstream's answer to dotforge's `/forge init`.

## Evidence

- Doc: code.claude.com/docs/en/memory — "Set `CLAUDE_CODE_NEW_INIT=1` to enable an interactive multi-phase flow"
- Direct UX competition with `/forge init` (the dotforge skill). Either evaluate adoption (use upstream + remove our skill), differentiation (do something upstream doesn't), or hybrid (call upstream + post-process with dotforge stack detection).

## What to evaluate

- Run `CLAUDE_CODE_NEW_INIT=1 claude` on a fresh test project. What does the multi-phase flow look like? Compare against `/forge init`.
- What does it propose for `hooks/` — does it match dotforge's `block-destructive.sh`/`post-compact.sh`/`session-restore.sh` patterns?
- Does it understand stack composition (python-fastapi, react-vite-ts, etc.) like dotforge does, or is it generic?
- Permission model: does it offer a `bootstrap --profile minimal|standard|full` analog?

## Possible outcomes

1. **Upstream covers it**: deprecate `/forge init`, document `CLAUDE_CODE_NEW_INIT=1` as the canonical bootstrap, focus dotforge on stacks + audit + practices
2. **Hybrid**: `/forge init` calls `CLAUDE_CODE_NEW_INIT=1 claude` then overlays dotforge stacks/rules — best of both
3. **Differentiate**: `/forge init` keeps its 4-question UX + stack auto-detection, but adopts the "review proposal before writing" UX pattern

## Impact on dotforge

- `skills/init-project/SKILL.md`: review against upstream flow, decide path
- `audit/checklist.md`: if upstream `/init` covers item N, consider de-emphasizing in our audit
- README: document the relationship with upstream `/init` for new users
- `.claude/rules/domain/`: new rule `init-flow.md` documenting both flows once tested

## Decision
Pending — requires empirical test run before deciding direction
