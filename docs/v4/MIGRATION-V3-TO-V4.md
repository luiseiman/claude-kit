# Migrating dotforge projects from v3 to v4

v4.0.0 is a **minor migration with audit-score implications**. Existing v3 projects continue to work without changes, but to fully adopt v4 you should run the migration script.

## What changes in v4

| Category | v3.x | v4.0 |
|----------|------|------|
| Override capture loop | not present | bash hook auto-captures frequent overrides into `practices/inbox/auto-override-*.md` |
| `workflows/` directory | not standard | reference implementation (`workflows/watch.js`) shipped; user-authored allowed |
| Audit checklist | 15 items | 17 items (16: workflow availability, 17: override loop active) |
| Audit max score | 10/10 unchanged | 10/10 unchanged (normalized) — but 2 new items mean v3-perfect projects score ~9.5/10 until migrated |
| `domain/workflow-economics.md` | not present | new domain rule documenting workflow vs skill decision matrix |

**Breaking?** Only in the audit-score sense. Existing hooks, behaviors, and rules continue to work unchanged. Projects that don't migrate continue functioning — they just lose the new audit items.

## Pre-flight checklist

- [ ] Dotforge repo is at v4.0.0+ (`cat $DOTFORGE_DIR/VERSION` shows `4.0.0` or higher)
- [ ] Project is bootstrapped via dotforge (has `.claude/` directory)
- [ ] Project's git working tree is clean (recommended — migration is atomic but you want clean history)
- [ ] Working with one project at a time (no batch automation in this release)

## Migration steps

### Per-project

```bash
# Dry-run first — always
cd <project>
DOTFORGE_DIR=<dotforge-path> bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh --dry-run

# Inspect the planned actions. Should show:
#   - Install .claude/hooks/session-start-process-overrides.sh
#   - Wire hook in .claude/settings.json SessionStart
#   - Create empty .forge/audit/overrides.log (if not present)
#   - Update .claude/.forge-manifest.json with v4_migrated_at

# If actions look correct, apply:
DOTFORGE_DIR=<dotforge-path> bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh

# Verify
/forge audit  # items 16-17 should appear in the output
```

### Rollback if needed

```bash
DOTFORGE_DIR=<dotforge-path> bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh --rollback
```

The script keeps the latest `.claude.v3-backup-<TS>/` backup. Rollback restores from the most recent. If you want to keep multiple backups, save them with different names before subsequent migrations.

## What the migration does NOT touch

- ❌ `CLAUDE.md` — unchanged
- ❌ `behaviors/` — project-owned
- ❌ `.claude/rules/` — unchanged
- ❌ `.claude/agents/` — unchanged
- ❌ `.claude/commands/` — unchanged
- ❌ Existing hooks — unchanged
- ❌ `.claude/settings.json` allow/deny rules — unchanged (only SessionStart hooks array gets a new entry appended)

## Suggested rollout order (12 managed projects)

Wave 1 — pilot (1 project)
1. **vault-bot** — standard tier, low blast radius. Validate end-to-end.

Wave 2 — heavy/production (5 projects)
2. **dotforge** itself (already migrated by the v4 work)
3. **InviSight-iOS**
4. **TRADINGBOT** — production tier, observe override loop activity for 1 week
5. **cotiza-api-cloud** — production tier
6. **jira-nbch**

Wave 3 — rest (5 projects)
7. cds-dashboard, openclaw, derup, crm, Whassap signals

Optional: SOMA, SOMA2 stay on v3 (archived per `.dotforge-sync-ignore`).

## Verification per project (post-migration)

```bash
cd <project>

# Hook installed and executable
test -x .claude/hooks/session-start-process-overrides.sh && echo "✓ hook installed"

# Hook wired in settings.json
grep -q session-start-process-overrides.sh .claude/settings.json && echo "✓ wired"

# Audit shows new items
/forge audit | grep -E "v4 workflow|v4 override"
```

## Effect on registry score

Projects perfect at 10/10 v3 will report ~9.5/10 v4 until they migrate:
- Item 16 (workflow availability): can be satisfied by symlinking `$DOTFORGE_DIR/workflows/` or auto-pass for v3.x dotforge
- Item 17 (override loop active): satisfied by running the migration script

Once migrated, scores return to 10/10 if all other items pass.

## When NOT to migrate

- Project is archived (has `.dotforge-sync-ignore`) — don't migrate
- Project uses a custom hook framework that conflicts with `SessionStart` — review first
- You're mid-incident on a production project — wait until calm
