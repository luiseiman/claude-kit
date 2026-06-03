# dotforge v4.0 — Specification of record

Draft · 2026-06-03 · Phase 0 research output (revised after token-economy reality check)

## Status

**Phase:** 0 (research) · **Go/no-go decision:** ⏳ pending PoC of `workflows/watch.js`

## Mission

> dotforge v4 selectively converts operations where **LLM judgment is the work** from declarative markdown (skills) to orchestration code (workflows). Mechanical work stays as bash skills — workflow refactor of mechanical operations is a **token bomb antipattern**. Adversarial verify is opt-in per workflow, configured by skepticism arg. The practices↔behaviors loop closes via override capture (bash, not workflow).

## Anti-thesis: what v4 is NOT

A common mistake is "workflow-native everywhere" — convert every multi-step skill to a workflow. **This is wrong.** A pure-bash skill like `/forge sync-all` (0 LLM tokens) becomes a $2-5 workflow if naively refactored. The work classifying git state mechanically does not need an LLM.

**Token-economy rule:** if a skill currently spawns 0 subagents and uses 0 LLM calls in its hot path, refactoring it to a workflow is a regression. Keep it as bash.

## Research questions — answered (2026-06-03)

### Q1: ¿Can workflow scripts import or require other .js files?

**Answer: NO.** Workflows are single self-contained `.js` files. The docs describe scripts as singular: *"Every run writes its script to a file under your session's directory"*. No documented `import` / `require` syntax. Helper functions must be **inlined into each workflow**.

**Implication for dotforge:**
- No shared library of helpers across workflows
- Each workflow that needs `timeout()`, `_smart_push()`, etc. carries its own copy
- Workflows in the 200-500 line range are normal
- Mitigation: each workflow's `meta` block can reference a documented shared pattern in `docs/v4/PATTERNS.md` for human reference, but code stays inline

### Q2: ¿Is there a test harness for workflows?

**Answer: NO formal harness.** Doc strategy is *"run the workflow on a small slice first: one directory instead of the whole repo, or a narrow question instead of a broad one"*. No dry-run mode. No unit testing pattern documented.

**Implication for dotforge:**
- Workflows test by running
- Mitigation pattern: each refactored workflow accepts `args.dryRun: true` to skip mutations and emit a plan instead
- Mitigation pattern: each workflow accepts `args.slice: <N>` to process only the first N items in any fan-out for cost-bounded smoke tests
- Decision: **mandatory** for any v4 workflow refactor — dryRun + slice params

### Q3: ¿Can workflows invoke other workflows? Nesting depth?

**Answer: YES, 1 level only.** The `workflow()` primitive: *"workflow(nameOrRef, args?): run another workflow inline as a sub-step. Nesting is one level only: workflow() inside a child throws."*

**Implication for dotforge:**
- A composition like `sync-all → audit-each-repo` is valid (1 level)
- A composition like `sync-all → audit-each-repo → behavior-check-each` is NOT (2 levels)
- Mitigation: deep composition flatten to phase()-grouped sequential calls in parent

### Q4: ¿Can `agent(..., {agentType: 'researcher'})` resolve dotforge's custom agents?

**Answer: YES, when symlinked to `~/.claude/agents/`.** The `agentType` option *"uses a custom subagent type instead of the default workflow subagent — resolved from the same registry as the Agent tool"*. dotforge already symlinks `agents/*.md` to `~/.claude/agents/` via `global/sync.sh`, so they're discoverable.

**Implication for dotforge:**
- Dotforge agents (`researcher`, `architect`, `implementer`, `code-reviewer`, `security-auditor`, `test-runner`, `session-reviewer`) ARE usable from workflows via `agentType`
- Cost: untested. dotforge agents are full markdown specs vs the lighter workflow-default agent. Phase 0 PoC must measure this delta.
- Mitigation: workflows can mix custom agents (for specialized lenses) with default workflow agents (for generic work)

## Architecture — final

```
dotforge/
├── workflows/                       # NEW v4 — small, justified set only
│   ├── README.md                    # Authoring conventions + token economy
│   ├── watch.js                     # Replaces skills/watch-upstream/ — LLM-research justifies
│   └── _shared/                     # Reference-only; copy-paste into workflows
│       └── PATTERNS.md              # timeout, parallel xargs, dryRun pattern
├── skills/                          # MOST skills stay — they're mechanical work
├── docs/v4/                         # NEW v4
│   ├── SPEC.md                      # This file
│   ├── PATTERNS.md                  # Inline-reference patterns library
│   ├── MIGRATION-V3-TO-V4.md        # User migration guide
│   └── WORKFLOW-CONVENTIONS.md      # dotforge-specific authoring rules
├── scripts/
│   ├── migrate-v3-to-v4.sh          # NEW — migrator with dry-run
│   └── process-override-log.sh      # NEW — periodic override→practice capture
└── .claude/hooks/
    └── session-start-process-overrides.sh  # NEW — calls process-override-log.sh
```

## Decision matrix: workflow vs skill

Apply this matrix BEFORE proposing any v4 workflow refactor:

| Question | Skill (stay) | Workflow (refactor) |
|----------|--------------|---------------------|
| Is the hot path LLM-driven? | No (bash/git/grep/file checks) | Yes (research, synthesis, evaluation) |
| Does adversarial verify add value? | No (deterministic output) | Yes (catches LLM hallucinations) |
| Wall-clock currently > 2 min? | Either | Yes — parallel agents help |
| Token cost currently > $0.30? | Either | Maybe — but workflow can be cheaper if parallel structure helps |
| Is the work fan-out shaped? | No (linear) | Yes (10+ independent items) |
| Does main thread need to retain context? | Yes | No — context isolation helps |

**If 4+ questions point to "Skill (stay)" → DO NOT REFACTOR.**

Applied to dotforge skills (2026-06-03):
- ✅ `/forge sync-all` → SKILL forever (0 hot-path LLM calls, mechanical)
- ✅ `/forge audit` → SKILL forever (file/grep checks)
- ✅ `/forge capture` → SKILL forever (single LLM query)
- ✅ `/forge bootstrap/init/sync` → SKILL forever (file ops)
- ⚖️ `/forge update` → CONDITIONAL (workflow only if adversarial verify atrapa real bad decisions; otherwise skill with stricter prompts)
- ✅ `/forge watch` → WORKFLOW (research IS LLM, multiple sources, parallel fetch+verify helps)
- ⚖️ `/forge scout` → CANDIDATE for workflow (multi-source like watch)
- ⚖️ `/forge insights` → CANDIDATE for workflow (pattern detection across history)

## Token economy principles (mandatory)

Every dotforge workflow MUST follow:

1. **Bash-first triage at workflow start**: filter work mechanically before spawning subagents. If a workflow's first phase is "classify candidates", do it in a bash command outside the workflow, then pass only the interesting subset as `args`.

2. **Default skepticism = single-pass**: `args.skepticism: 'normal'` (default) = 1 verify call per finding. `'high'` = 2-3 verify calls. `'low'` = 0 (skip verify). Production-tier projects can override. **Never multi-pass by default.**

3. **Custom `agentType` only when role matters**: default workflow agent is lighter than dotforge custom agents (which carry full markdown spec). Use `agentType: 'security-auditor'` only when the role's specific instructions change output materially.

4. **Schema validation = 0 token cost**: ALWAYS use `opts.schema` for structured output. Validation is at tool layer, doesn't add tokens, prevents retries from malformed responses.

5. **Minimal prompts per `agent()` call**: ONLY the context needed for that specific decision. No "here's the full session" dumps. No history of prior agent results unless that agent's job is synthesis.

6. **Declare `budget.total` in every workflow**: hard ceiling per run. Default `budget.total: 100_000` tokens (≈$0.30 at Sonnet 4.6 rates). Critical workflows can set higher with justification in `meta.description`.

7. **Resume cache via `resumeFromRunId`**: same script + same `args` → 100% cache hit. Use for iterate-test cycles during workflow development.

8. **Phase boundaries are FREE**: use `phase('Verify')` liberally for progress visibility. Costs 0 tokens.

9. **One workflow = one concern**: no kitchen-sink workflows. Compose via `workflow()` 1-level when needed. Smaller workflows = better resume caching = cheaper iteration.

10. **Log per-phase token spend**: end every workflow with `log(\`Spent: ${budget.spent()} tokens\`)`. Forces awareness during dev.

## v4 conventions for workflow authoring

Mandatory for every dotforge-owned workflow:

1. **Apply decision matrix first** — if it doesn't pass, stay as skill
2. **Apply token economy principles** (above) — non-negotiable
3. **`meta.phases`** explicit, never elided — progress visibility
4. **`args.dryRun: boolean`** support — for smoke testing without mutations
5. **`args.slice: number`** support — for cost-bounded partial runs in fan-out workflows
6. **`args.skepticism: 'low' | 'normal' | 'high'`** — controls adversarial verify intensity
7. **`args.verbose: boolean`** — noisier log() output during debugging
8. **`budget.total`** declared in script body, default 100k tokens
9. **Header comment** with: purpose, when to use, args contract, expected token cost for typical run, expected wall-clock
10. **Inline timeout helper** (no external deps allowed)
11. **Schema validation** for any structured output (`opts.schema`) — always
12. **Filter null** after `parallel()` — `.filter(Boolean)` always
13. **End with token spend log** — `log(\`Spent: ${budget.spent()} of ${budget.total} tokens\`)`

## Override capture loop spec

### Mechanism

NOT a runtime hook. v3 already writes to `.forge/audit/overrides.log` whenever user overrides a soft_block. v4 processes this log periodically.

### Trigger

`SessionStart` hook (`source: startup`) calls `scripts/process-override-log.sh`.

### Algorithm

```bash
# scripts/process-override-log.sh
# Read .forge/audit/overrides.log
# Group by behavior_id + tool + reason_pattern
# For each group with count >= MIN_OVERRIDES (default: 3):
#   Check if practices/inbox/ already has auto-override-<behavior>-<hash>.md
#   If not: create practice with:
#     - title: "Frequent override of <behavior_id> on <tool> — review trigger"
#     - source_type: auto-override
#     - source: ".forge/audit/overrides.log lines N..M"
#     - tags: [override-capture, <behavior_id>, auto]
#     - priority: medium
#     - status: inbox
```

### Dedup

By `(behavior_id, tool, normalized_reason)` tuple hash. Same group never produces 2 practices unless the source filename and `MIN_OVERRIDES` threshold differ.

### Not in scope (deferred to v4.x)

- Auto-promotion of practice → behavior tightening
- Metric-driven behavior effectiveness scoring
- OTEL integration

## v4.0 Phase plan (revised after Phase 0 findings)

### Phase 1 — Foundation (~1 week real)

1. `workflows/` directory + `workflows/README.md`
2. `docs/v4/PATTERNS.md` (copy-paste reference library)
3. `docs/v4/WORKFLOW-CONVENTIONS.md`
4. `scripts/process-override-log.sh` + tests
5. `.claude/hooks/session-start-process-overrides.sh` wired
6. `scripts/migrate-v3-to-v4.sh` skeleton (dry-run only)
7. `behaviors/` schema extension: `engine: bash | workflow` field added with default `bash`
8. Tests: `tests/test-process-override-log.sh`

Branch: `v4-foundation` · No skill retirement yet.

### Phase 2 — Workflow refactor (~1-2 weeks real, narrower scope)

Only 1 workflow refactor in v4.0. Others are deferred to v4.x pending observed need.

#### 2.1 `workflows/watch.js` (sole v4.0 refactor)

**Baseline measured (`/forge watch` skill, 2026-06-03 estimate):**
- ~200K tokens total (~90K WebFetch fast model + ~95K main thread synthesis + ~15K search)
- ~$0.75-1.00 per run
- ~3-5 min wall-clock

**Target for workflow:**
- ≤ $0.50 per run (workflow refactor must be CHEAPER, not just faster)
- ≤ 60 sec wall-clock (parallel fetches)
- Adversarial verify catches ≥1 false-positive that bash-skill would miss per 3 runs

**Design:**
- `args: {dryRun: false, slice: 6, skepticism: 'normal', verbose: false}`
- `budget.total: 200_000` (matches skill baseline — must come in under)
- Phase 1 (fetch): `parallel()` over 6 doc URLs + 3 web searches. Schema-validated extraction per source via `opts.schema`. Default agent (not custom `agentType`).
- Phase 2 (compare): bash-first cross-reference with current dotforge state via grep — NO agents in this phase. Output: list of candidate gaps.
- Phase 3 (verify): adversarial verify ONLY findings flagged "BREAKING-ISH" or "HIGH-priority" — not every finding. Single-pass at `skepticism: normal`, dual at `high`.
- Phase 4 (synthesize): one final agent composes the delta report from validated findings.

**Architectural note:** Phase 2 is the win. Bash grep is $0 — using LLM to grep for keyword presence is wasteful. Workflow refactor confines LLM to Phase 1 (extraction) and Phases 3-4 (judgment+synthesis).

**Rollback criteria:** if measured cost > $0.50 OR adversarial verify catch rate = 0 across 3 runs, revert to skill with stricter prompts.

#### 2.2 Other refactors — DEFERRED to v4.x

| Skill | v4.0 decision | When to revisit |
|-------|---------------|-----------------|
| `/forge sync-all` | STAY SKILL | Never — mechanical work |
| `/forge update` | STAY SKILL with stricter prompts | After 10+ `/forge update` runs measured, if avg cost > $0.30 |
| `/forge insights` | STAY SKILL for v4.0 | Re-evaluate after 1 `/forge insights` run measured (currently untested) |
| `/forge audit` | STAY SKILL | Never — mechanical |
| `/forge scout` | STAY SKILL for v4.0 | Re-evaluate after `/forge scout` first real use

### Phase 3 — Audit checklist v4 expansion (~3 days real)

Items added:
- **Item 16:** v4 workflow coverage — score 0/1
  - 0: no `workflows/` directory or empty
  - 1: at least 1 workflow + audit-checklist item validated
- **Item 17:** Override capture loop active — score 0/1
  - 0: `.forge/audit/overrides.log` exists but no `process-override-log.sh` wired
  - 1: hook wired + at least 1 entry exists in `practices/inbox/auto-override-*.md` OR log is empty

Recalc: 5 obligatory (0-2) + 12 recommended (0-1) = max 22 raw → normalize via existing formula (×0.7 obligatory + ×3/10 recommended, capped at 10).

Score expectation: projects on v3.13 perfect 10/10 drop to ~8.7/10 until they migrate.

### Phase 4 — Migration + Release (~1 week real)

1. `scripts/migrate-v3-to-v4.sh` validated end-to-end
2. Dry-run on dotforge itself + 1 standard-tier project (vault-bot or derup)
3. Real migration on 1 heavy-tier project (InviSight-iOS) as integration test
4. Release notes prep with explicit breaking-change callouts
5. CHANGELOG v4.0.0 published
6. GitHub release tag v4.0.0 + GitHub Release with migration guide pinned
7. Sync wave to remaining 11 projects (1-by-1, no auto-sync)

## v3 → v4 migration steps (user-facing)

```bash
# 1. From dotforge directory
cd $DOTFORGE_DIR
git fetch && git checkout v4.0.0  # or main if v4 is merged
bash scripts/migrate-v3-to-v4.sh --dry-run

# 2. Per-project, after reviewing dry-run output
cd <project>
bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh

# 3. Migration tasks executed per project:
#    - Backup .claude/ to .claude.v3-backup/
#    - Add workflows/ symlink to $DOTFORGE_DIR/workflows/
#    - Update CLAUDE.md to reference workflows in addition to skills
#    - Wire .claude/hooks/session-start-process-overrides.sh
#    - Extend behaviors/ YAML if v3 behaviors compiled to runtime hooks (add engine: bash)
#    - Validate /forge audit reports new items 16+17

# 4. Rollback if needed
bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh --rollback
```

## Risks tracked

| # | Risk | Mitigation |
|---|------|------------|
| 1 | Workflow API changes before v4.0 release | Phase 0 PoC validates current API. Postpone v4.0 release if upstream changes during Phase 1-2 |
| 2 | Workflow cost (tokens) exceeds skill cost by >2x per typical run | Phase 2 measures each refactor. Rollback if >2x AND <30% calidad improvement |
| 3 | Adversarial verify generates false positives, increasing user friction | Verify configurable per workflow via `args.skepticism: low|normal|high` |
| 4 | No imports means workflows duplicate utility code → maintenance burden | `docs/v4/PATTERNS.md` as canonical source of truth; new workflows copy from it; lint script flags drift |
| 5 | Custom agents (`agentType: researcher`) cost more than default | Phase 2 measures. If >50% over default cost, use default agents only |
| 6 | Migration script breaks production projects (TRADINGBOT, cotiza-api-cloud, SOMA) | Dry-run mandatory before real run. Atomic backup. Rollback documented. Test on lower-tier first |
| 7 | Workflow keyword trigger ("ultracode") accidentally triggers in v4 docs | Use "ultracode-tier" or "ultracode-mode" in dotforge docs. Anti-confusion already documented in v3.13 |
| 8 | v4 governance changes break existing v3 behaviors | `engine: bash` is default for v3 YAML; explicit migration of behavior to `engine: workflow` only when refactored |

## Go/no-go criteria for Phase 1 (token-aware, strict)

PoC of `workflows/watch.js` must demonstrate ALL of these to greenlight v4 release:

- [ ] **Token cost ≤ $0.50 per run** (baseline is $0.75-1.00 → must be cheaper, not just faster)
- [ ] Token cost < `budget.total: 200_000` (hard ceiling)
- [ ] Wall-clock < 60 sec (vs baseline 3-5 min)
- [ ] Schema validation succeeds for all source extraction (no malformed responses needing retry)
- [ ] Adversarial verify catches ≥1 false-positive across 3 measured runs
- [ ] Custom `agentType` usage costs ≤ +30% over default workflow agent (if used at all)
- [ ] `budget.spent()` log at end shows ≤ 80% of `budget.total` (room for variance)

**If 2+ criteria fail:** abort v4 workflow refactor entirely. Pivot to v4 = override capture loop only + audit checklist item 17. `/forge watch` stays as skill with stricter prompts.

## Open questions

1. **Plugin distribution of workflows**: do workflows in `workflows/` get distributed via dotforge's plugin marketplace path, or only via `.claude/workflows/` in target projects?
2. **Workflow versioning**: dotforge skills are pinned by VERSION file. Workflows have no inherent version. Strategy?
3. **MCP integration**: workflows can call MCP tools. Should dotforge ship MCP server for state queries (`mcp__dotforge__list_projects`, etc.) in v4 or defer to v4.x?
4. **Effort tier**: should `workflows/sync-all.js` set its own model preference (e.g., `model: 'haiku'` for parallel classify), or inherit session model?

## Next deliverable

PoC of `workflows/watch.js` (read-only / report-only mode). Run on dotforge's actual upstream sources, compare against today's `/forge watch` baseline (~$0.75-1.00, ~3-5 min). Report numbers against all 7 go/no-go criteria.

If PoC succeeds → Phase 1 (foundation) starts.
If PoC fails 2+ criteria → v4 thesis pivots to override-loop-only (smaller, lower-risk release).

## References

- [Workflows](https://code.claude.com/docs/en/workflows) — primary doc, fetched 2026-06-03
- [Workflow tool definition](https://code.claude.com/docs/en/workflows#how-a-workflow-runs) — agent/parallel/pipeline/phase
- [Custom subagents](https://code.claude.com/docs/en/sub-agents) — agentType resolution
- [Permissions](https://code.claude.com/docs/en/permission-modes) — workflow subagent behavior in modes
- `domain/workflow-automation.md` — current dotforge v3.13 coverage of /workflows
- `domain/workflow-and-ultracode-policy.md` — tier-based posture policy (v3.12.0)
