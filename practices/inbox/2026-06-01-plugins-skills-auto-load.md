---
id: practice-2026-06-01-plugins-skills-auto-load
title: Plugins in .claude/skills/ auto-load without marketplace + claude plugin init scaffold (v2.1.157)
source: "official changelog"
source_type: upstream
discovered: 2026-06-01
status: inbox
tags: [plugins, skills, distribution, marketplace, upstream]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Description

v2.1.157 lowers the friction floor for plugin development:

1. **Plugins in `.claude/skills/<plugin-name>/` auto-load** without requiring marketplace registration. Drop the directory in, Claude Code finds it.
2. **`claude plugin init <name>`** scaffolds a new plugin in `.claude/skills/` — entrypoint for plugin authors that bypasses the marketplace bootstrap.

This collapses the boundary between "skill" (project-local, no distribution) and "plugin" (distributable artifact). Previously plugins required marketplace metadata even for local-only use; now they don't.

## Evidence

CHANGELOG v2.1.157:
- "Plugins in `.claude/skills/` auto-load without marketplace requirement"
- "`claude plugin init <name>` scaffolds new plugins in `.claude/skills`"

## Impact on dotforge

- `domain/plugin-distribution.md` — rewrite the "When to plugin vs `.claude/`" table:
  - "Shared with team, versioned, namespaced skills" — STILL plugin, but the threshold dropped: even unshared experiments can be plugins because the marketplace overhead is gone.
  - "One-project customization, quick experiment" — the gap between this row and "plugin" is now thin. Reconsider whether the distinction adds value or should collapse.
- `domain/plugin-distribution.md` "Persistent state" section — `${CLAUDE_PLUGIN_DATA}` now available to auto-loaded `.claude/skills/` plugins. Document as the cheapest path to persistent state for project-local skills (vs the heavier `.forge/runtime/state.json` pattern).
- `skills/plugin-generator` — review the generator output: does it still emit marketplace metadata required for distribution, or can it skip when scaffolding `.claude/skills/` style?
- `template/` — consider whether dotforge's own template should ship `.claude/skills/` example with `plugin.json` to show the pattern.

## Related

- [[plugin-suggestion-marketplaces]] (already incorporated v3.10.0) — managed allowlisting of marketplaces. Becomes less restrictive in practice if local skills bypass marketplace entirely.
