---
id: practice-2026-06-01-worktree-lifecycle-improvements
title: Worktree auto-unlock on finish + EnterWorktree mid-session switch
source: "watch upstream + lived experience (sync-all normalization)"
source_type: docs+experience
discovered: 2026-06-01
activated: 2026-06-01
status: active
tags: [worktrees, agents, parallel-sessions, sync-all, cleanup]
tested_in: TRADINGBOT
incorporated_in: [".claude/rules/domain/parallel-sessions.md, skills/sync-all-repos/SKILL.md"]
replaced_by: null
priority: medium
---

## Description

Claude-managed worktrees now auto-unlock when the agent finishes, so `git worktree remove`/`prune` can clean them up without manual intervention. `EnterWorktree` can also switch between Claude-managed worktrees mid-session (previously one-shot).

## Evidence

- Changelog: "Worktrees managed by Claude are now left unlocked when the agent finishes, so git worktree remove/prune can clean them up"
- Changelog: "EnterWorktree can now switch between Claude-managed worktrees mid-session"
- **Lived today (2026-06-01)**: during sync-all normalization, TRADINGBOT had `claude/festive-maxwell-a70698` and `heuristic-swartz-65163d` worktrees blocking `git checkout main`:
  ```
  fatal: 'main' is already used by worktree at '.claude/worktrees/heuristic-swartz-65163d'
  ```
  Had to `git worktree remove --force` + `git branch -D` + `git worktree prune` manually. Auto-unlock would have prevented this.
- Currently 3 dotforge-managed projects have stale `.claude/worktrees/` directories: TRADINGBOT, cotiza-api-cloud, tradingview (now gitignored, but the actual worktrees persist on disk)

## What to document

- Auto-unlock behavior: when does "finish" trigger? On SubagentStop hook? On worktree exit?
- Mid-session switching: `EnterWorktree(path)` semantics — can a Lead now coordinate teammates without spawning new sessions per worktree?
- Cleanup pattern: `git worktree list --porcelain | awk '/^worktree/ {print $2}'` to discover, then `git worktree remove` for stale ones
- Interaction with `worktree.bgIsolation: "none"` (v2.1.143) — does auto-unlock still apply?

## Impact on dotforge

- `.claude/rules/domain/parallel-sessions.md`: update worktree lifecycle section
- `.claude/rules/domain/sandboxing.md`: cross-reference the v2.1.149 worktree allowlist scope fix
- `skills/sync-all-repos/SKILL.md`: add worktree-cleanup detection step. When a repo has `.claude/worktrees/*` directories AND `git worktree list` shows them as Claude-managed AND the corresponding branches have no unique commits → offer to prune. Avoids the festive-maxwell-style cleanup mid-sync.
- `agents/agents.md` (rule): update Agent Teams worktree guidance — explicit `worktree remove` after teammate exits is no longer required, but still recommended for disk hygiene

## Decision
Pending
