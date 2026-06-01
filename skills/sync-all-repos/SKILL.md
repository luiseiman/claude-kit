---
name: sync-all-repos
description: Sync all GitHub-backed git repos on this machine with origin. Pulls behind repos, pushes ahead repos, reports dirty/non-main/conflict cases for Claude to resolve.
---

# Sync All Repos

Discover every GitHub-backed git repo on the current machine, classify each by sync state, auto-execute the obvious cases (clean repo behind/ahead/diverged from origin), and report the ambiguous cases (uncommitted changes, non-main branches, rebase conflicts) for Claude to resolve case by case.

Use this when:
- You sit down at the Mac or VPS and want to catch up with whatever the OTHER machine pushed to GitHub since last session
- You're about to walk away and want to ensure all committed-but-not-pushed work is on GitHub
- You suspect drift between machines and want a single-shot reconciliation

This skill does NOT:
- Coordinate Mac↔VPS directly (each machine syncs with GitHub independently)
- Auto-stash, auto-commit, or auto-resolve conflicts (Claude decides per case)
- Touch non-GitHub repos (gitlab, bitbucket, self-hosted git all skipped)
- Run on a timer (explicit invocation only)

## Step 1: Discover repos

Search roots:
- `~/Documents/GitHub/` (depth ≤2)
- `~/Documents/jira nbch/` (cds-dashboard, jira-nbch)
- `~/Documents/crm/`
- Any additional path in `$DOTFORGE_DIR/registry/projects.local.yml` not covered above

For each candidate directory at depth ≤2 with a `.git/` subdirectory:

```bash
REMOTE=$(git -C "$dir" config --get remote.origin.url 2>/dev/null)
case "$REMOTE" in
  *github.com*) echo "$dir" ;;
  *) ;;  # skip non-GitHub repos silently
esac
```

Skip silently:
- Directories without `.git/`
- Repos with no `origin` remote
- Repos with `origin` not pointing at GitHub

## Step 2: Classify each repo

For each discovered repo, gather state (all read-only — safe to run in parallel):

```bash
cd "$repo"
BRANCH=$(git branch --show-current)
DIRTY=$(git status --porcelain | wc -l | tr -d ' ')
git fetch origin --quiet 2>/dev/null || FETCH_FAIL=1
BEHIND=$(git rev-list --count HEAD..@{u} 2>/dev/null || echo "?")
AHEAD=$(git rev-list --count @{u}..HEAD 2>/dev/null || echo "?")
LAST_COMMIT=$(git log -1 --format='%h %s' 2>/dev/null)
```

Classification table:

| State | Trigger | Action |
|-------|---------|--------|
| `unreachable` | `FETCH_FAIL` set | Skip with warning. GitHub down or no network. Don't fail the rest. |
| `non-main` | `BRANCH` is not `main`/`master` | Report only. User may be on a feature branch deliberately. |
| `dirty` | `DIRTY > 0` | Report with branch + `git diff --stat` + last commit. **NO automatic action.** Defer to Claude. |
| `in-sync` | `DIRTY==0 && BEHIND==0 && AHEAD==0` | No-op. Report as clean. |
| `behind` | `DIRTY==0 && BEHIND>0 && AHEAD==0` | Auto: `git pull --rebase` |
| `ahead` | `DIRTY==0 && BEHIND==0 && AHEAD>0` | Auto: `git push` |
| `diverged` | `DIRTY==0 && BEHIND>0 && AHEAD>0` | Auto: `git pull --rebase` then `git push`. If rebase fails, `git rebase --abort` and report. |
| `conflict` | rebase failed | Already aborted in `diverged` flow. Report and let Claude decide. |

## Step 3: Execute auto-actions

For each repo classified as `behind`, `ahead`, or `diverged`, execute the action.

```bash
# behind
git -C "$repo" pull --rebase --quiet

# ahead
git -C "$repo" push --quiet

# diverged
git -C "$repo" pull --rebase --quiet || git -C "$repo" rebase --abort
[ rebase succeeded ] && git -C "$repo" push --quiet
```

Capture exit code per repo. Don't stop the loop on failure — collect all results and report at the end.

## Step 4: Build structured report

Emit a markdown table summarizing every repo touched:

```
═══ SYNC-ALL RESULTS ═══

Pulled (N):
  - <repo> (was behind by N commits)

Pushed (M):
  - <repo> (was ahead by N commits)

Diverged + reconciled (K):
  - <repo> (pulled N, pushed M)

In-sync (J):
  - <repo>, <repo>, ...

Dirty — DEFERRED to Claude (X):
  - <repo>
    branch: <branch>
    last commit: <hash> <msg>
    changes: <diff --stat first 3 lines>

Non-main branches — skipped (Y):
  - <repo> on <branch>

Conflicts — manual intervention (Z):
  - <repo>: rebase aborted; pull and push diverged manually

Unreachable (W):
  - <repo>: fetch failed (GitHub or network)
```

## Step 5: Claude resolves dirty cases

For each repo in the `Dirty` section, Claude decides what to do based on the diff and session context:

1. Run `git -C <repo> diff` to see what's changed
2. Run `git -C <repo> log -5 --oneline` to see recent commits for context
3. Decide:
   - **Skip**: user is mid-edit on something they haven't finished. Leave it alone, note in summary.
   - **Commit WIP**: changes look like a coherent unit. Compose a descriptive commit message and `git add -A && git commit -m "<msg>"`, then push.
   - **Stash**: changes don't fit a clean commit but need to clear the tree to pull. `git stash push -m "sync-all auto-stash <date>"`, pull, optionally `git stash pop`.
   - **Ask user**: if intent is genuinely unclear, surface via AskUserQuestion with the diff.

Apply the decision per repo using Bash directly. Do NOT loop back through the skill — this phase is Claude's orchestration.

## Step 6: Handle non-main branches

For each repo on a non-main branch (reported in step 4), ask one question collectively rather than per-repo:

> Found N repos on non-main branches: <repo1> on <branch1>, <repo2> on <branch2>...
> Want me to sync these branches with their tracking origin (same logic: pull/push/report)?

If yes, re-run steps 2-4 on those repos. If no, skip.

## Step 7: Final summary

After all dirty cases and non-main branches are resolved, emit the final counter:

```
═══ FINAL ═══
Total repos discovered: T
Pulled:    N
Pushed:    M
Synced:    K (in-sync, no action)
Dirty resolved: J (X committed, Y stashed, Z skipped)
Conflicts remaining: C
Unreachable: U
```

## Edge cases

- **`~/Documents/GitHub/dotforge` is included**: sync it LAST, after every other repo is done. If the pull brought new commits, surface:
  > dotforge updated to v<new-version>. The new skills/hooks are on disk but the current Claude session is still using the old version. Restart Claude to pick up the update.
  Do NOT auto-restart.
- **Repo doesn't exist on this machine**: search-roots-based discovery skips it silently. No error.
- **Repo is a submodule**: detect via `.git` being a file (not a directory). Skip submodules — they're managed by their parent.
- **Repo has a non-`origin` GitHub remote**: only `origin` is considered. If you push to multiple GitHubs, you're outside the scope of this skill.

## Constraints

- NEVER `git push --force` from this skill, even after a rebase. If push fails, report and stop on that repo.
- NEVER auto-commit changes to `.env`, `*.key`, `*.pem`, `**/secrets*` files. If a dirty repo's diff includes those paths, force "Skip" or "AskUserQuestion" — never WIP-commit.
- NEVER touch repos under `.claude/worktrees/` — those are dotforge's internal agent worktrees, not real project state.
- Always run `git fetch` BEFORE classifying. Without an up-to-date `@{u}`, behind/ahead counts are stale.
