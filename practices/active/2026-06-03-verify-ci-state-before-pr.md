---
id: practice-2026-06-03-verify-ci-state-before-pr
title: Verify CI state on main before opening a PR — preexisting redness blocks unrelated work
source: "feature/audit-two-dimensions (PR #3) — discovered while merging the two-dimension audit"
source_type: process
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [ci, workflow, pre-pr, process, regression-hygiene, fan-out-edit]
tested_in: null
incorporated_in: [".claude/rules/_common.md", "CLAUDE.md"]
replaced_by: null
priority: medium
---

## Description

Two independent, well-scoped lessons from a session that reoriented the audit to a two-dimension model and then hit a wall at merge time.

**1. Check CI health on `main` before opening a PR.** The `validate` job (ci.yml) was red on `main` from two accumulated, unnoticed causes: `test_on_off.sh` asserted `search-first` enabled=true after it was deliberately disabled in v3.6.1, and `plugin.json` stayed at 3.0.4 after `VERSION` bumped to 4.0.0. Because `validate` runs on every PR, *every* PR in the repo was blocked by failures unrelated to its own changes. Separately, `audit.yml` could never post its score comment (missing `permissions: pull-requests/issues write` → 403), so the degraded CI was invisible — no comment, no signal. A green-looking repo can hide a CI that has silently rotted.

**2. Grep ALL consumers before planning a fan-out edit.** Reorienting the audit `checklist.md` touched a system with many coupled consumers: two independent scoring engines (`audit/score.sh` in bash, `scripts/audit_all.py` in Python), the CI workflow (`audit.yml`), and three live docs. The initial plan listed 5 files; the real surface was 9. The consumers were discovered mid-execution, forcing a re-plan. A pre-plan `grep` for every reference to the artifact being changed would have sized the work correctly upfront.

## Evidence

- PR #3 went green only after 3 extra fix commits: `fix(ci)` workflow permissions, `fix` plugin.json version, `fix(test)` self-baseline test_on_off.
- Root cause of test failure: index.yaml change in v3.6.1 was deliberate (flag-consume false positives) but the test was never updated — the test was stale, not the config.
- Two scoring engines (`score.sh`, `audit_all.py`) reimplement the same checklist independently — both had to be migrated in lockstep.

## Derived rule

- **Before opening a PR**: run `gh run list --branch main --limit 5` (or `gh pr checks` on a recent PR) to confirm CI is green on `main`. If red, fix or flag the preexisting failure first — don't stack new work on a blocked pipeline.
- **Before planning any edit to a shared artifact** (checklist, schema, settings partial, template marker): `grep -rl "<artifact>"` across the repo to enumerate every consumer, and include them all in the plan. Treat duplicate engines (bash + python implementing the same logic) as a smell worth flagging.

## How to apply

Candidate homes if validated:
- A pre-PR checklist note in `.claude/rules/_common.md` (Git section) or a `domain/` rule on CI hygiene.
- A planning-discipline line in the audit-related skills that edit `checklist.md`/`scoring.md`, pointing at the dual-engine coupling (`score.sh` + `audit_all.py` must stay in sync).
