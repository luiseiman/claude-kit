---
globs: "**/.claude-plugin/**,**/plugin.json,**/install.sh,**/.mcp.json"
description: "Plugin distribution: persistent state, seed dirs, marketplace policy, reserved names"
domain: claude-code-engineering
last_verified: 2026-05-05
---

# Plugin Distribution

## Persistent state — `${CLAUDE_PLUGIN_DATA}` (v2.1.126+)

- Plugin-scoped directory for state that must survive plugin updates/reinstalls
- Available in hooks, skills, commands as the env var `${CLAUDE_PLUGIN_DATA}`
- Use for: accumulated metrics, last-processed IDs, capture inboxes, manifests of managed projects
- NEVER store secrets here — sandbox env-scrub does NOT cover plugin data dirs
- Distinct from `${CLAUDE_PLUGIN_ROOT}` (read-only plugin install dir)

For dotforge specifically: candidates to migrate are `practices/metrics.yml` (counters), `.forge/manifest.json` (registry), and post-session captures that currently land in `practices/inbox/` (which dirties git status). Migration is a multi-commit project — pilot one (e.g. `inbox/`) before others.

## Multi-seed distribution — `CLAUDE_CODE_PLUGIN_SEED_DIR`

- Accepts multiple directories separated by platform delimiter (`:` Unix, `;` Windows)
- Layered overlay pattern: `seed1` (base) `:` `seed2` (corporate) `:` `seed3` (personal)
- Use for: enterprise overlays on top of public template, personal preferences on top of team config
- Later seeds override earlier ones for files with the same path

## Marketplace governance (managed settings)

- `strictKnownMarketplaces` — allowlist of marketplace sources (exact match, supports github/git/url/npm/file/directory/hostPattern)
- `blockedMarketplaces` — denylist
- `allowedChannelPlugins` — restricts which plugins can listen on `--channels`
- `allowManagedPermissionRulesOnly` — locks projects to managed-only permission rules
- `pluginTrustMessage` — custom warning shown on plugin trust prompts
- `pluginSuggestionMarketplaces` (v2.1.152+) — admins allowlist org marketplaces whose plugins may be suggested via the harness's context-aware tip prompts. Without it, all configured marketplaces are eligible to surface suggestions

## Reserved names

- `workspace` — reserved as MCP server name since v2.1.128. Plugins/projects using this name skipped with warning at startup. Audit `.mcp.json` and `mcp/` configs in dotforge stacks before declaring server names.

## Lifecycle hygiene

- `claude plugin prune` (v2.1.121+) — removes orphaned auto-installed dependencies
- `plugin uninstall --prune` — cascades dependency cleanup
- `--plugin-dir` accepts `.zip` archives (v2.1.128+) — alternative distribution path

## When to plugin vs `.claude/`

| Need | Use |
|------|-----|
| One-project customization, quick experiment | `.claude/` standalone |
| Shared with team, versioned, namespaced skills | Plugin |
| Enterprise governance (marketplace allowlist) | Plugin via managed settings |
| State that must survive updates | Plugin + `${CLAUDE_PLUGIN_DATA}` |
