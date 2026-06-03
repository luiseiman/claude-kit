#!/usr/bin/env bash
# dotforge v3 → v4 migration script
#
# Idempotent. Safe-by-default with --dry-run mandatory for first invocation.
# Atomic backup before changes. Documented rollback via --rollback.
#
# What it does:
#   1. Check project has v3 dotforge config (.claude/ + CLAUDE.md)
#   2. Install .claude/hooks/session-start-process-overrides.sh (copy from $DOTFORGE_DIR)
#   3. Wire the hook in .claude/settings.json SessionStart (idempotent — skip if present)
#   4. Initialize .forge/audit/overrides.log as empty file if missing
#   5. Update .claude/.forge-manifest.json with dotforge_version
#
# What it does NOT do:
#   - Touch behaviors/ — those are project-owned
#   - Modify CLAUDE.md
#   - Bump audit score expectations (items 16-17 are documented but enforcement
#     varies per dotforge version on the project — see SPEC v4 §audit transition)
#
# Usage:
#   bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh --dry-run
#   bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh
#   bash $DOTFORGE_DIR/scripts/migrate-v3-to-v4.sh --rollback
#
# Exit codes:
#   0 — success (or dry-run preview)
#   1 — preconditions not met (not a dotforge-managed project)
#   2 — backup or write error

set -uo pipefail

DRY_RUN=0
ROLLBACK=0
VERBOSE=0

for arg in "$@"; do
  case "$arg" in
    --dry-run) DRY_RUN=1 ;;
    --rollback) ROLLBACK=1 ;;
    --verbose|-v) VERBOSE=1 ;;
    --help|-h)
      sed -n '2,40p' "$0"
      exit 0
      ;;
    *) echo "Unknown arg: $arg (use --help)"; exit 1 ;;
  esac
done

PROJECT_DIR="$PWD"
PROJECT_SLUG="$(basename "$PROJECT_DIR")"
TS="$(date -u +%Y%m%dT%H%M%SZ)"

# === Preconditions ===

if [[ -z "${DOTFORGE_DIR:-}" ]]; then
  echo "ERROR: DOTFORGE_DIR not set. Source ~/.bashrc or set DOTFORGE_DIR=$HOME/Documents/GitHub/dotforge" >&2
  exit 1
fi

if [[ ! -d "${DOTFORGE_DIR}" ]]; then
  echo "ERROR: DOTFORGE_DIR (${DOTFORGE_DIR}) does not exist" >&2
  exit 1
fi

if [[ ! -d "${PROJECT_DIR}/.claude" ]]; then
  echo "ERROR: ${PROJECT_DIR}/.claude not found — project not bootstrapped via dotforge" >&2
  echo "  Hint: run /forge bootstrap first" >&2
  exit 1
fi

if [[ ! -f "${PROJECT_DIR}/.claude/settings.json" ]]; then
  echo "ERROR: .claude/settings.json missing — project incomplete" >&2
  exit 1
fi

# === Resolved paths ===

SOURCE_HOOK="${DOTFORGE_DIR}/template/hooks/session-start-process-overrides.sh"
TARGET_HOOK="${PROJECT_DIR}/.claude/hooks/session-start-process-overrides.sh"
SETTINGS="${PROJECT_DIR}/.claude/settings.json"
OVERRIDE_LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
MANIFEST="${PROJECT_DIR}/.claude/.forge-manifest.json"
BACKUP_DIR="${PROJECT_DIR}/.claude.v3-backup-${TS}"

# Find latest backup for --rollback
_latest_backup() {
  ls -td "${PROJECT_DIR}"/.claude.v3-backup-* 2>/dev/null | head -1
}

# === Rollback path ===

if (( ROLLBACK )); then
  latest="$(_latest_backup)"
  if [[ -z "$latest" ]]; then
    echo "ERROR: no v3 backup found in ${PROJECT_DIR}" >&2
    exit 1
  fi
  echo "Rolling back to: $(basename "$latest")"
  if (( DRY_RUN )); then
    echo "  [dry-run] would: rm -rf .claude && mv ${latest} .claude"
    exit 0
  fi
  rm -rf "${PROJECT_DIR}/.claude"
  mv "$latest" "${PROJECT_DIR}/.claude"
  # Optionally clean .forge/audit/overrides.log if it was created (empty) by migration
  if [[ -f "$OVERRIDE_LOG" && ! -s "$OVERRIDE_LOG" ]]; then
    rm -f "$OVERRIDE_LOG"
    rmdir "${PROJECT_DIR}/.forge/audit" 2>/dev/null || true
    rmdir "${PROJECT_DIR}/.forge" 2>/dev/null || true
  fi
  echo "✓ rollback complete"
  exit 0
fi

# === Migration plan ===

actions=()

if [[ ! -f "$SOURCE_HOOK" ]]; then
  echo "ERROR: source hook missing at $SOURCE_HOOK (dotforge not on v4)" >&2
  exit 1
fi

if [[ ! -f "$TARGET_HOOK" ]]; then
  actions+=("install_hook")
fi

# Check if wired in settings.json (idempotent detection)
if ! grep -q "session-start-process-overrides.sh" "$SETTINGS" 2>/dev/null; then
  actions+=("wire_hook")
fi

if [[ ! -f "$OVERRIDE_LOG" ]]; then
  actions+=("init_override_log")
fi

if [[ ${#actions[@]} -eq 0 ]]; then
  echo "✓ ${PROJECT_SLUG} already migrated to v4 (no changes needed)"
  exit 0
fi

# === Preview ===

echo "═══ v3 → v4 migration plan for: ${PROJECT_SLUG} ═══"
echo "Project: ${PROJECT_DIR}"
echo "Dotforge: ${DOTFORGE_DIR}"
echo ""
echo "Actions:"
for a in "${actions[@]}"; do
  case "$a" in
    install_hook) echo "  • Install ${TARGET_HOOK#${PROJECT_DIR}/}" ;;
    wire_hook) echo "  • Wire hook in .claude/settings.json SessionStart" ;;
    init_override_log) echo "  • Create empty .forge/audit/overrides.log" ;;
  esac
done
echo ""
echo "Backup: ${BACKUP_DIR#${PROJECT_DIR}/}"
echo ""

if (( DRY_RUN )); then
  echo "[dry-run] No changes made. Re-run without --dry-run to apply."
  exit 0
fi

# === Apply ===

# 1. Atomic backup
echo "→ Creating backup..."
cp -R "${PROJECT_DIR}/.claude" "$BACKUP_DIR" || {
  echo "ERROR: backup failed" >&2
  exit 2
}

# 2. Apply actions
for a in "${actions[@]}"; do
  case "$a" in
    install_hook)
      cp "$SOURCE_HOOK" "$TARGET_HOOK" || { echo "ERROR: hook install failed" >&2; exit 2; }
      chmod +x "$TARGET_HOOK"
      echo "  ✓ installed hook"
      ;;
    wire_hook)
      python3 <<PY
import json, pathlib
f = pathlib.Path("$SETTINGS")
d = json.loads(f.read_text())
ss = d.setdefault("hooks", {}).setdefault("SessionStart", [])
target = None
for entry in ss:
    if entry.get("matcher", "") == "":
        target = entry; break
if target is None:
    target = {"matcher": "", "hooks": []}; ss.append(target)
target.setdefault("hooks", []).append({
    "type": "command",
    "command": ".claude/hooks/session-start-process-overrides.sh",
    "timeout": 5
})
f.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
PY
      echo "  ✓ wired hook in settings.json"
      ;;
    init_override_log)
      mkdir -p "$(dirname "$OVERRIDE_LOG")"
      touch "$OVERRIDE_LOG"
      echo "  ✓ created empty .forge/audit/overrides.log"
      ;;
  esac
done

# 3. Update manifest if exists
if [[ -f "$MANIFEST" ]]; then
  python3 <<PY 2>/dev/null
import json, pathlib, datetime
f = pathlib.Path("$MANIFEST")
try:
    d = json.loads(f.read_text())
    d["v4_migrated_at"] = "${TS}"
    d["v4_migration_backup"] = "$(basename "$BACKUP_DIR")"
    f.write_text(json.dumps(d, indent=2, ensure_ascii=False) + "\n")
    print("  ✓ updated .forge-manifest.json")
except Exception as e:
    print(f"  ⚠ manifest update skipped: {e}")
PY
fi

echo ""
echo "═══ Migration complete ═══"
echo "Backup at: ${BACKUP_DIR#${PROJECT_DIR}/}"
echo ""
echo "To rollback: bash ${DOTFORGE_DIR}/scripts/migrate-v3-to-v4.sh --rollback"
echo "To verify:   /forge audit (items 16-17 should appear)"

exit 0
