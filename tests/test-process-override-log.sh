#!/usr/bin/env bash
# Tests for scripts/process-override-log.sh
# Runs in an isolated tmp dir; never touches the real dotforge state.

set -uo pipefail

# === Setup ===
DOTFORGE_REPO="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="${DOTFORGE_REPO}/scripts/process-override-log.sh"

if [[ ! -x "$SCRIPT" ]]; then
  echo "FAIL: ${SCRIPT} not found or not executable"
  exit 1
fi

pass_count=0
fail_count=0

_pass() { pass_count=$((pass_count + 1)); echo "  ✓ $1"; }
_fail() { fail_count=$((fail_count + 1)); echo "  ✗ $1"; }

# === Helper: set up isolated test environment ===
_setup_env() {
  TMPDIR="$(mktemp -d -t process-override-test.XXXXXX)"
  export DOTFORGE_DIR="${TMPDIR}/dotforge"
  mkdir -p "${DOTFORGE_DIR}/practices"/{inbox,evaluating,active,deprecated}
  PROJECT_DIR="${TMPDIR}/sample-project"
  mkdir -p "${PROJECT_DIR}/.forge/audit"
  cd "$PROJECT_DIR"
  export FORGE_ROOT=".forge"
}

_cleanup() {
  cd /
  rm -rf "$TMPDIR"
}

# === Test 1: empty log → no captures ===
echo "Test 1: empty log"
_setup_env
touch "${PROJECT_DIR}/.forge/audit/overrides.log"
"$SCRIPT" >/dev/null 2>&1
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "0" ]]; then
  _pass "empty log produces no captures"
else
  _fail "empty log produced ${inbox_files} captures (expected 0)"
fi
_cleanup

# === Test 2: missing log → no captures, no error ===
echo "Test 2: missing log"
_setup_env
"$SCRIPT" >/dev/null 2>&1
rc=$?
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$rc" == "0" && "$inbox_files" == "0" ]]; then
  _pass "missing log exits 0 with no captures"
else
  _fail "missing log: rc=${rc}, inbox=${inbox_files}"
fi
_cleanup

# === Test 3: 2 overrides (below MIN_OVERRIDES=3) → no capture ===
echo "Test 3: below threshold"
_setup_env
LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
{
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)|abc12345|verify-before-done|Bash|cmd=git push|3|"
  echo "$(date -u +%Y-%m-%dT%H:%M:%SZ)|abc12345|verify-before-done|Bash|cmd=git push|4|hotfix"
} > "$LOG"
"$SCRIPT" >/dev/null 2>&1
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "0" ]]; then
  _pass "2 overrides below MIN_OVERRIDES=3 produce no capture"
else
  _fail "expected 0 captures with 2 overrides; got ${inbox_files}"
fi
_cleanup

# === Test 4: 3 overrides → 1 capture ===
echo "Test 4: at threshold"
_setup_env
LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git push|3|"
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git commit|4|"
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git tag|5|hotfix"
} > "$LOG"
"$SCRIPT" >/dev/null 2>&1
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "1" ]]; then
  _pass "3 overrides at MIN_OVERRIDES produce 1 capture"
  # Verify frontmatter has key fields
  pf="$(ls "${DOTFORGE_DIR}/practices/inbox"/*.md | head -1)"
  if grep -q "source_type: auto-override" "$pf" && \
     grep -q "behavior_id: verify-before-done" "$pf" && \
     grep -q "tool_name: Bash" "$pf" && \
     grep -q "count: 3" "$pf"; then
    _pass "  frontmatter has expected fields"
  else
    _fail "  frontmatter missing key fields"
  fi
else
  _fail "expected 1 capture; got ${inbox_files}"
fi
_cleanup

# === Test 5: re-run on same log → idempotent (no duplicate) ===
echo "Test 5: idempotent re-run"
_setup_env
LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git push|3|"
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git commit|4|"
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git tag|5|hotfix"
} > "$LOG"
"$SCRIPT" >/dev/null 2>&1
"$SCRIPT" >/dev/null 2>&1  # re-run
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "1" ]]; then
  _pass "re-run on same log does not duplicate (idempotent)"
else
  _fail "re-run produced ${inbox_files} files (expected 1)"
fi
_cleanup

# === Test 6: skips if practice exists in active/ ===
echo "Test 6: skip if already in active/"
_setup_env
LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  echo "${ts}|abc12345|search-first|Edit|file_path=/src/utils.ts|3|"
  echo "${ts}|abc12345|search-first|Edit|file_path=/src/main.ts|4|"
  echo "${ts}|abc12345|search-first|Edit|file_path=/src/app.ts|5|"
} > "$LOG"
# Pre-populate active/ with the would-be filename
# Mirror script's normalization exactly: lowercase, non [a-z0-9-] → '-', collapse, trim
project_slug="$(basename "$PROJECT_DIR" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/-\+/-/g; s/^-\|-$//g')"
key="${project_slug}|search-first|Edit"
hash="$(printf '%s' "$key" | (md5sum 2>/dev/null || md5 -q) | cut -c1-8)"
fn="auto-override-${project_slug}-search-first-edit-${hash}.md"
touch "${DOTFORGE_DIR}/practices/active/${fn}"
"$SCRIPT" >/dev/null 2>&1
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "0" ]]; then
  _pass "skip when same practice exists in active/"
else
  _fail "expected 0 captures (already in active); got ${inbox_files}"
fi
_cleanup

# === Test 7: multiple distinct (behavior, tool) groups ===
echo "Test 7: multiple groups"
_setup_env
LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
ts="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
{
  # Group A: verify-before-done on Bash (3 entries)
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git push|3|"
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git commit|4|"
  echo "${ts}|abc12345|verify-before-done|Bash|cmd=git tag|5|"
  # Group B: search-first on Edit (3 entries)
  echo "${ts}|abc12345|search-first|Edit|file=/src/a.ts|3|"
  echo "${ts}|abc12345|search-first|Edit|file=/src/b.ts|4|"
  echo "${ts}|abc12345|search-first|Edit|file=/src/c.ts|5|"
  # Group C: respect-todo-state on TaskUpdate (2 entries, below threshold)
  echo "${ts}|abc12345|respect-todo-state|TaskUpdate|task=foo|2|"
  echo "${ts}|abc12345|respect-todo-state|TaskUpdate|task=bar|3|"
} > "$LOG"
"$SCRIPT" >/dev/null 2>&1
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "2" ]]; then
  _pass "2 groups above threshold produce 2 captures (third group below threshold)"
else
  _fail "expected 2 captures (2 above threshold, 1 below); got ${inbox_files}"
fi
_cleanup

# === Test 8: missing DOTFORGE_DIR exits 1 ===
echo "Test 8: missing DOTFORGE_DIR"
_setup_env
unset DOTFORGE_DIR
"$SCRIPT" >/dev/null 2>&1
rc=$?
if [[ "$rc" == "1" ]]; then
  _pass "missing DOTFORGE_DIR exits 1"
else
  _fail "expected exit 1 with missing DOTFORGE_DIR; got rc=${rc}"
fi
_cleanup

# === Test 9: out-of-window entries ignored ===
echo "Test 9: out-of-window entries"
_setup_env
LOG="${PROJECT_DIR}/.forge/audit/overrides.log"
old_ts="2020-01-01T00:00:00Z"
{
  # All very old — outside default 30-day window
  echo "${old_ts}|abc12345|verify-before-done|Bash|cmd=git push|3|"
  echo "${old_ts}|abc12345|verify-before-done|Bash|cmd=git commit|4|"
  echo "${old_ts}|abc12345|verify-before-done|Bash|cmd=git tag|5|"
} > "$LOG"
"$SCRIPT" >/dev/null 2>&1
inbox_files="$(ls "${DOTFORGE_DIR}/practices/inbox" 2>/dev/null | wc -l | tr -d ' ')"
if [[ "$inbox_files" == "0" ]]; then
  _pass "out-of-window entries are ignored"
else
  _fail "expected 0 captures for out-of-window entries; got ${inbox_files}"
fi
_cleanup

# === Final report ===
echo ""
echo "═══ test-process-override-log: ${pass_count} passed, ${fail_count} failed ═══"
(( fail_count == 0 ))
