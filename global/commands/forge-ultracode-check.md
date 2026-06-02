---
name: forge-ultracode-check
description: Evaluate whether ultracode (high-effort + adversarial verify + workflow-first) should be ON for the current task. Reads project tier from registry, git state, recent edits; applies the 5 canonical criteria.
---

Decide whether ultracode mode is justified RIGHT NOW for this working tree.

1. **Resolve project tier**
   - Read `registry/projects.local.yml` (or `.forge-manifest.json` at repo root, or `$DOTFORGE_DIR/registry/projects.local.yml`)
   - Match entry by `cwd` → extract `ultracode_tier` (`light` | `standard` | `heavy` | `production`)
   - If no match or field absent → default `standard`, note "unregistered project"

2. **Read working state**
   - `git status --short` → count files modified (M) and staged (A/M cached)
   - `git diff --stat HEAD` → lines added/removed
   - Read `.claude/session/last-startup.md` → recent edits + active task hint
   - Note presence of high-risk surfaces: migrations, auth, payments, infra IaC, schema files, `template/hooks/`, `settings.json.partial`

3. **Apply the 5 canonical criteria** (from `domain/workflow-and-ultracode-policy.md`)
   - **C1 Blast radius**: ≥3 files OR >200 LOC changed → +1
   - **C2 Domain risk**: tier ≥ heavy, OR touches auth/payments/migrations/infra/schema/security → +1
   - **C3 Ambiguity**: ≥2 valid approaches with real tradeoffs (infer from task hint) → +1
   - **C4 Reversibility**: hard to undo (prod migration, force-push, schema drop, live trade) → +1
   - **C5 Prior failure**: sonnet attempted and failed, OR `CLAUDE_ERRORS.md` shows repeat in this area → +1

4. **Output verdict**

```
Ultracode recommendation: ON | CONSIDER | OFF
Score: N/5  (tier: <tier>, files: <n>, LOC: ±<n>)
Triggered: C2 (auth touched), C4 (migration irreversible)
Reasoning: <2-3 lines citing which criteria fired and why>
```

**Mapping**: score ≥3 → ON · score 2 → CONSIDER · score ≤1 → OFF.
**Override to ON** if C2+C4 both fire regardless of total — irreversible touch on a risk surface always warrants adversarial verify.
