# dotforge v4.0 — Specification of record

**Status:** Phase 0 complete · **PoC verdict:** workflow refactor REJECTED · **v4 scope:** override capture loop + audit items + workflow as optional escalation tool

Final revision · 2026-06-03

## Mission (revised post-PoC)

> dotforge v4 closes the practices↔behaviors loop via override capture, adds workflow availability as **optional escalation tool** (not a default refactor), and tightens audit checklist with 2 new items. Workflow refactor of existing skills was tested in PoC and rejected on cost-quality grounds.

## Anti-thesis: what v4 is NOT

The original v4 thesis was "workflow-native everywhere — convert multi-step skills to workflows for adversarial verify by default". **Phase 0 PoC rejected this.** Empirical data:

- 4 smoke tests of `workflows/watch.js` measured $5-30 per run vs $0.75-1.00 baseline (`/forge watch` skill)
- Per-agent overhead in workflows (~80K tokens fixed per agent) dominates over model-routing savings
- Verify-without-WebSearch (cost optimization) caused quality regression: smoke #4 missed the 10K char cap finding that smoke #3 verified
- Per-stage model routing helps but does not reach cost parity

The lesson: **workflows are valuable as on-demand escalation, not as default replacement for mechanical or recurring work.**

## Phase 0 PoC findings (final)

### Cost reality (measured)

| Configuration | Cost per typical run | vs baseline |
|---------------|---------------------|-------------|
| `/forge watch` skill (current) | ~$0.75-1.00 | baseline |
| Workflow with default Opus session model (smoke #3) | ~$5-25 | 5-25x baseline |
| Workflow with model routing + WebSearch verify (smoke #4) | ~$4-5 | 4-5x baseline |
| Workflow with model routing + internal verify (smoke #4) | ~$4-5 | 4-5x baseline AND quality regression |

### Quality observations

- Smoke #3 verified 4 real gaps including BREAKING (`additionalContext` 10K char cap)
- Smoke #4 verified only 3 — the 10K cap finding was downgraded to "unverified" because internal-reasoning verify could not confirm against external source
- **Cost reduction came at quality cost**, violating user's calibration ("no degradar calidad y exactitud")

### Architecture conclusions

1. **Workflows have substantial per-agent fixed overhead** (~80K tokens regardless of model). 9-12 agents per workflow → cost floor ~$3-5 even with optimal routing
2. **Adversarial verify quality depends on cross-source check** (WebSearch). Cheap internal verify is unreliable
3. **Hybrid (main thread fetches, workflow processes)** lowered cost by ~30% vs pure workflow but still 4-5x over baseline
4. **Workflows DO catch real gaps** that mechanical skills miss (validated in smoke #3) — value is real, just expensive per finding

### When workflows DO make economic sense

- Adversarial verify on individually high-stakes findings (manual escalation per finding)
- One-off codebase-wide research questions (`/deep-research` is bundled for this)
- Production-tier projects where false-positive cost > workflow cost (~$5 cheap insurance vs hours of cleanup)

Not viable for: recurring lifecycle work (watch/update/sync-all), routine governance, anything with 0 LLM cost in current bash form.

## v4 final scope

### IN

1. **`scripts/process-override-log.sh`** — bash script processing `.forge/audit/overrides.log`. Reads logged soft_block overrides, groups by `(behavior_id, tool, normalized_reason)`, creates `practices/inbox/auto-override-*.md` when count ≥ 3 within retention window. Idempotent (dedupes against existing inbox entries).
2. **`SessionStart` hook wiring** — `template/hooks/session-start-process-overrides.sh` calls the script on session start. Same wiring in `.claude/hooks/` for self-hosting.
3. **Audit checklist items 16-17**:
   - **Item 16 (workflow availability)**: `workflows/` directory exists with at least 1 documented entry. Score 0/1.
   - **Item 17 (override capture loop active)**: `.forge/audit/overrides.log` exists AND `process-override-log.sh` wired in `SessionStart`. Score 0/1.
4. **`workflows/watch.js`** stays in repo as REFERENCE implementation. Documented as "available on-demand for high-confidence reviews". NOT promoted to `/forge watch` default.
5. **New domain rule `domain/workflow-economics.md`** — documents cost reality measured in Phase 0 PoC. Decision matrix: when workflow vs skill. Token economy principles. Lessons learned.
6. **The 4 captures from smoke #3 in `practices/inbox/`** (added 2026-06-03):
   - `hook-output-10k-cap.md` (BREAKING)
   - `claude-env-file-preamble.md` (HIGH)
   - `sessionstart-watchpaths.md` (HIGH)
   - `plugin-defaultenabled-dormant.md` (MEDIUM)

### OUT (rejected by evidence)

- ❌ `/forge watch` → workflow refactor (4-5x cost, quality regression)
- ❌ `/forge update` → workflow refactor (similar economics expected)
- ❌ `/forge sync-all` → workflow refactor (mechanical, token bomb)
- ❌ Auto-promotion of practices to behaviors (deferred to v4.x)
- ❌ MCP server exposing dotforge state (deferred)
- ❌ Cross-project daemon (rejected philosophically)
- ❌ KNOWN_TOPICS static glossary (quality regression, was a token-saving anti-pattern)

## Audit checklist v4 final

Items 1-15 unchanged from v3. Items 16-17 new:

### Item 16: workflow availability (0-1)

- 0: No `workflows/` directory OR directory empty
- 1: `workflows/` directory exists with at least 1 `.js` file having `meta` block

**Verification:** `ls workflows/*.js 2>/dev/null | head -1` returns a file. Open it and confirm `export const meta` exists.

Score is intentionally low (1 point). Workflow presence is governance signal, not a quality measure — bash skills remain the workhorse.

### Item 17: override capture loop active (0-1)

- 0: `.forge/audit/overrides.log` doesn't exist OR `process-override-log.sh` not wired in `SessionStart`
- 1: Both present AND wired

**Verification:**
```bash
test -f .forge/audit/overrides.log && \
  grep -q process-override-log.sh .claude/settings.json
```

Together with prior items, max obligatory = 10 (5 × 2pts) + max recommended = 17 (12 × 1pt + 5 × 1pt rejected items?). Actually recalc: 5 obligatory + 12 recommended (10 + 2 new) = max raw 22. Normalize via existing formula `obligatory × 0.7 + recommended × (3.0/12)` → max = 7 + 3 = 10. Same final ceiling.

Score impact on existing v3.13 projects: ~8.6/10 until they migrate (lose 2 × 0.25 normalized).

## What gets committed in v4.0.0 release

| Artifact | Status | Action |
|----------|--------|--------|
| `scripts/process-override-log.sh` | TBD — Phase 1 | Implement + test |
| `template/hooks/session-start-process-overrides.sh` | TBD — Phase 1 | Implement + wire |
| `.claude/hooks/session-start-process-overrides.sh` | TBD — Phase 1 | Self-hosting copy |
| `audit/checklist.md` | Update | Add items 16-17 |
| `audit/scoring.md` | Verify | No formula change, only item count |
| `workflows/watch.js` | Already written | Keep as-is, document as reference |
| `docs/v4/SPEC.md` | This file | Already revised |
| `docs/v4/MIGRATION-V3-TO-V4.md` | TBD — Phase 4 | User migration guide |
| `domain/workflow-economics.md` | TBD — Phase 1 | Document PoC findings as canonical rule |
| `VERSION` | Bump | 3.13.0 → 4.0.0 |
| `docs/changelog.md` | Add v4.0.0 entry | Document all of the above |
| `README.md` | Light update | New audit count, v4 highlights |
| `ROADMAP.md` | Update | Mark v4.0.0 complete |
| `scripts/migrate-v3-to-v4.sh` | TBD — Phase 4 | Dry-run migrator |

## Phases (revised post-PoC, smaller scope)

### Phase 0 — Research + PoC ✓ DONE (2026-06-03)

- 4 research questions answered (no imports, no test harness, 1-level nesting, custom agentType resolves)
- 4 smoke tests of `workflows/watch.js` executed
- Cost-quality data collected
- 4 real gaps captured from smoke runs
- v4 scope reduced from "workflow refactor" to "override loop + audit items"
- Spec finalized (this document)

### Phase 1 — Override loop implementation (~3-5 days real)

1. `scripts/process-override-log.sh` — bash, dedup logic, idempotent
2. `template/hooks/session-start-process-overrides.sh` — wire into Setup or SessionStart
3. `.claude/hooks/session-start-process-overrides.sh` — self-hosting
4. `template/settings.json.tmpl` — add SessionStart entry
5. Tests: `tests/test-process-override-log.sh` covering: empty log, single override, 3+ overrides triggering capture, dedup against existing inbox entry, malformed log resilience
6. `domain/workflow-economics.md` — new domain rule documenting PoC findings

### Phase 2 — Audit checklist update (~1 day real)

1. `audit/checklist.md` — add items 16-17 with verification steps
2. `audit/scoring.md` — verify formula works with 12 recommended items (no formula change, just count)
3. `skills/audit-project/SKILL.md` — extend to evaluate items 16-17

### Phase 3 — Migration script (~3 days real)

1. `scripts/migrate-v3-to-v4.sh` with `--dry-run` and `--rollback`
2. Per-project migration:
   - Backup `.claude/` to `.claude.v3-backup/`
   - Wire SessionStart hook
   - Update `audit/checklist.md` reference if present
3. Test dry-run on dotforge itself
4. Test on 1 standard-tier project (vault-bot or derup)
5. Validation: `/forge audit` reports new items 16-17

### Phase 4 — Release (~2 days real)

1. CHANGELOG v4.0.0 with explicit breaking-change callouts
2. `README.md` + `ROADMAP.md` updates (audit count, v4 highlights)
3. VERSION bump
4. Tag + GitHub release v4.0.0 with migration guide pinned
5. Sync wave: TRADINGBOT (production) first as integration test, then 10 remaining projects

## Risks (updated)

| # | Risk | Mitigation |
|---|------|------------|
| 1 | Override capture generates noise (toy practices) | Dedup tuple `(behavior_id, tool, normalized_reason)`. Minimum 3 overrides within 30-day window. Auto-add `priority: low` tag for first-pass |
| 2 | Audit items 16-17 drop existing project scores below "good" threshold (7/10) | Items deliberately low-weight (1 pt each = 0.25 normalized each). Worst case: 10/10 project drops to 9.5/10. Acceptable |
| 3 | Migration script breaks production projects | Mandatory `--dry-run` first. Atomic `.claude/` backup. Rollback documented |
| 4 | `workflows/watch.js` reference becomes stale and misleading | Mark with `// REFERENCE ONLY — see docs/v4/SPEC.md for cost analysis` in file header. Consider moving to `docs/v4/examples/` instead of `workflows/` |
| 5 | Users assume workflows are dotforge-default and incur cost | `domain/workflow-economics.md` documents the decision matrix. README explicit about skill-first philosophy |

## Open questions

1. **Move `workflows/watch.js` to `docs/v4/examples/`?** Avoids confusion that workflows are dotforge-promoted.
2. **Should override capture loop also process `disable-for-session` events?** Smoke #3 PoC revealed that `verify-before-done` was disabled mid-session — that's also signal worth capturing.
3. **Workflow as `/forge watch --workflow` opt-in flag?** Not implemented in this v4.0. Candidate for v4.1 if demand emerges.

## Next deliverable

Phase 1: implement `scripts/process-override-log.sh` + wire SessionStart hook + write `domain/workflow-economics.md`. Test on dotforge itself before broader migration.

## References

- [Workflows official docs](https://code.claude.com/docs/en/workflows) — fetched 2026-06-03
- `workflows/watch.js` — reference implementation, 4-smoke-test history
- `practices/inbox/2026-06-03-*` — 4 captures from PoC smoke runs
- `domain/workflow-automation.md` — current v3.13 coverage (includes workflow security boundary)
- `domain/workflow-and-ultracode-policy.md` — tier-based posture policy
