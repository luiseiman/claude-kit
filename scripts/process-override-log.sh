#!/usr/bin/env bash
# dotforge v4 override capture loop
#
# Process .forge/audit/overrides.log → create practices/inbox/auto-override-*.md
# for behavior+tool combinations overridden ≥ MIN_OVERRIDES times in WINDOW_DAYS.
#
# Idempotent: same input produces same output. Already-captured (in inbox/active/
# evaluating/deprecated) groups are skipped.
#
# Per-project log (.forge/audit/overrides.log under PWD) → dotforge inbox.
# Practices flow up to dotforge for centralized review via /forge update.
#
# Environment variables:
#   DOTFORGE_DIR     dotforge root (where practices/ lives) — required
#   FORGE_ROOT       defaults to .forge (per-project log location)
#   MIN_OVERRIDES    default 3 — minimum count to trigger capture
#   WINDOW_DAYS      default 30 — only consider overrides in last N days
#
# Exit codes:
#   0 — success (including "nothing to do")
#   1 — config error (DOTFORGE_DIR not set or invalid)
#   2 — log read error

set -uo pipefail

# === Config ===
FORGE_ROOT="${FORGE_ROOT:-.forge}"
LOG="${FORGE_ROOT}/audit/overrides.log"
MIN_OVERRIDES="${MIN_OVERRIDES:-3}"
WINDOW_DAYS="${WINDOW_DAYS:-30}"
DATE_TODAY="$(date +%Y-%m-%d)"

# DOTFORGE_DIR required
if [[ -z "${DOTFORGE_DIR:-}" ]]; then
  echo "process-override-log: DOTFORGE_DIR not set — cannot locate practices/ dir" >&2
  exit 1
fi
if [[ ! -d "${DOTFORGE_DIR}/practices/inbox" ]]; then
  echo "process-override-log: ${DOTFORGE_DIR}/practices/inbox not found" >&2
  exit 1
fi

PRACTICES_INBOX="${DOTFORGE_DIR}/practices/inbox"
PRACTICES_EVALUATING="${DOTFORGE_DIR}/practices/evaluating"
PRACTICES_ACTIVE="${DOTFORGE_DIR}/practices/active"
PRACTICES_DEPRECATED="${DOTFORGE_DIR}/practices/deprecated"

# Project slug: basename of PWD, lowercased, alphanumeric+dash only
PROJECT_SLUG="$(basename "$PWD" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-' | sed 's/-\+/-/g; s/^-\|-$//g')"
PROJECT_SLUG="${PROJECT_SLUG:-unknown}"

# === Early exits ===

# Log doesn't exist or empty
if [[ ! -s "$LOG" ]]; then
  exit 0
fi

# === Compute cutoff timestamp ===
# Portable: try GNU date first (Linux), then BSD date (macOS)
cutoff="$(date -d "${WINDOW_DAYS} days ago" -u +%Y-%m-%dT%H:%M:%SZ 2>/dev/null || \
         date -u -v-"${WINDOW_DAYS}"d +%Y-%m-%dT%H:%M:%SZ 2>/dev/null)"
if [[ -z "$cutoff" ]]; then
  echo "process-override-log: failed to compute cutoff timestamp" >&2
  exit 2
fi

# === Hash helper (portable: md5sum on Linux, md5 -q on macOS) ===
_hash() {
  printf '%s' "$1" | (md5sum 2>/dev/null || md5 -q 2>/dev/null) | cut -c1-8
}

# === Group overrides within window by (behavior_id, tool_name) ===
# Format of awk output: <count>\t<behavior_id>\t<tool_name>
groups=$(awk -F'|' -v cutoff="$cutoff" '
  $1 >= cutoff { count[$3 "\x1f" $4]++ }
  END {
    for (k in count) {
      n = split(k, parts, "\x1f")
      print count[k] "\t" parts[1] "\t" parts[2]
    }
  }
' "$LOG")

[[ -z "$groups" ]] && exit 0

created_count=0
skipped_count=0

# === Process each group ===
while IFS=$'\t' read -r count behavior_id tool_name; do
  # Skip if below threshold
  if (( count < MIN_OVERRIDES )); then
    continue
  fi

  # Defensive: skip malformed groups
  [[ -n "$behavior_id" && -n "$tool_name" ]] || continue

  # Dedup hash (stable across runs)
  key="${PROJECT_SLUG}|${behavior_id}|${tool_name}"
  hash="$(_hash "$key")"

  # Normalize tool name for filename (lowercase, alphanum+dash)
  tool_slug="$(printf '%s' "$tool_name" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-')"
  behavior_slug="$(printf '%s' "$behavior_id" | tr '[:upper:]' '[:lower:]' | tr -c 'a-z0-9-' '-')"

  filename="auto-override-${PROJECT_SLUG}-${behavior_slug}-${tool_slug}-${hash}.md"

  # Skip if already captured (inbox/evaluating/active/deprecated)
  already_exists=0
  for dir in "$PRACTICES_INBOX" "$PRACTICES_EVALUATING" "$PRACTICES_ACTIVE" "$PRACTICES_DEPRECATED"; do
    if [[ -f "${dir}/${filename}" ]]; then
      already_exists=1
      skipped_count=$((skipped_count + 1))
      break
    fi
  done
  (( already_exists )) && continue

  # Sample last 5 raw log lines for this (behavior, tool) within window
  samples="$(awk -F'|' -v b="$behavior_id" -v t="$tool_name" -v cutoff="$cutoff" '
    $1 >= cutoff && $3 == b && $4 == t
  ' "$LOG" | tail -5)"

  # Write practice file
  cat > "${PRACTICES_INBOX}/${filename}" <<EOF
---
id: practice-${DATE_TODAY}-auto-override-${PROJECT_SLUG}-${behavior_slug}-${tool_slug}-${hash}
title: "Frequent override of ${behavior_id} on ${tool_name} (${count} times in ${PROJECT_SLUG}, ${WINDOW_DAYS}d)"
source: ".forge/audit/overrides.log — ${count} overrides since ${cutoff}"
source_type: auto-override
discovered: ${DATE_TODAY}
status: inbox
tags: [override-capture, auto, ${behavior_slug}, ${PROJECT_SLUG}]
tested_in: ${PROJECT_SLUG}
incorporated_in: []
replaced_by: null
priority: medium
auto_capture:
  project: ${PROJECT_SLUG}
  behavior_id: ${behavior_id}
  tool_name: ${tool_name}
  count: ${count}
  window_days: ${WINDOW_DAYS}
  dedup_hash: ${hash}
---

## Description

The behavior \`${behavior_id}\` was overridden **${count} times** on tool \`${tool_name}\` within the last ${WINDOW_DAYS} days in project \`${PROJECT_SLUG}\`. Auto-captured by \`scripts/process-override-log.sh\` (v4 override loop).

Frequent overrides indicate one of:
- The escalation threshold is too aggressive for this project's workflow
- The trigger patterns produce false positives
- The behavior provides value but generates friction; threshold tuning needed
- The behavior policy genuinely doesn't fit this project (consider \`/forge behavior off\`)

## Override samples (most recent 5)

\`\`\`
${samples}
\`\`\`

## Suggested actions

1. Review \`behaviors/${behavior_id}/behavior.yaml\` triggers and thresholds in dotforge
2. Run \`/forge behavior strict ${behavior_id}\` or \`/forge behavior relaxed ${behavior_id}\` to adjust globally
3. If friction outweighs value in this project: \`/forge behavior off ${behavior_id} --project\`
4. If behavior is wrong for this project: capture lessons in another practice and disable

## Decision
Pending
EOF

  created_count=$((created_count + 1))
done <<< "$groups"

# Final report (only when something happened)
if (( created_count > 0 || skipped_count > 0 )); then
  echo "process-override-log: ${created_count} new, ${skipped_count} skipped (already captured) — project=${PROJECT_SLUG}"
fi

exit 0
