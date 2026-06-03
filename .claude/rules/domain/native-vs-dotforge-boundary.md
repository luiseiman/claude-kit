---
globs: docs/v4/*.md, behaviors/*, stacks/*, skills/*, .claude/rules/domain/*.md
description: Native-first boundary — what dotforge keeps vs cedes to native Claude Code, and the method for deciding
domain: dotforge-meta
last_verified: 2026-06-03
---

# Native vs dotforge Boundary

## Governing principle

If Claude Code resolves it natively, ADOPT the native solution. dotforge only owns
what natively has no equivalent. Scope shrinks as Claude Code grows — that is correct.

## Method (mandatory before any scope decision)

Verify the CURRENT native state against official docs (code.claude.com/docs,
anthropics/claude-code) BEFORE classifying. A scope call on stale assumptions is wrong
by default — this is why `/forge watch` (keeping domain rules current) is the INPUT that
makes boundary decisions correct, not meta-work. Never cede a capability without
confirming the native feature actually covers the real case.

## Classification (verified 2026-06-03)

KEEP — no native equivalent:
- **Domain rules** — curated encyclopedia of CC internals + business domain. Core asset.
- **Cross-project propagation with merge** — `forge:section` markers + `/forge sync`.
  Native symlinks/global CLAUDE.md only COPY, never merge per-project customization.
- **Behaviors v3** — 5-level escalation + session state + auditable override.
  `hookify` is a binary warn/block wrapper; no native behavior-governance spec exists.
  KEEP pending validation that production projects actually consult `overrides.log`.
- **Registry + audit cross-project** — REORIENT: audit must measure good use of NATIVE
  features (auto-memory active, sandbox set, deny rules present, /init run), not presence
  of dotforge machinery.

CEDE — native covers it:
- Individual learning capture → native auto-memory (per-project, `~/.claude/projects/<p>/memory/`)
- Identical shared rules (no merge needed) → native symlinks in `.claude/rules/` + global CLAUDE.md
- Workflows / orchestration → `/workflows`, Agent Teams, `/deep-research` (already ceded v4)
- Base CLAUDE.md generation → `/init`
- One-shot code review → `/code-review --comment/--fix`
- Model routing as a system → `/effort` (keep only as documentation)

## Anti-pattern

Building atop native internals that may change (compiled hooks depend on the hook API
shape). Every breaking upstream change forces a re-tune. Keep the native-dependent
surface minimal and validate delta demand before expanding it.
