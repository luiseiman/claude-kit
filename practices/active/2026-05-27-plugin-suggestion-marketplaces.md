---
id: practice-2026-05-27-plugin-suggestion-marketplaces
title: pluginSuggestionMarketplaces managed setting — allowlist for context-aware tips (v2.1.152)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [managed-settings, plugins, enterprise, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
New managed-settings key `pluginSuggestionMarketplaces`. Admins allowlist org marketplaces whose plugins may be suggested to users via context-aware tips (the "did you know there's a plugin for this?" prompt the harness now shows when it detects relevant context).

Without it, all configured marketplaces are eligible to surface suggestions. With it, only listed marketplaces appear.

```json
{
  "pluginSuggestionMarketplaces": [
    "github://my-org/internal-plugins",
    "https://corp.example.com/plugins"
  ]
}
```

## Evidence
CHANGELOG v2.1.152: "Added `pluginSuggestionMarketplaces` managed setting: admins allowlist org marketplaces whose plugins may be suggested via context-aware tips".

## Impact on dotforge
- `.claude/rules/domain/plugin-distribution.md` — add to the managed-settings governance section alongside `strictKnownMarketplaces` and `blockedMarketplaces`
- `.claude/rules/domain/permission-managed-settings.md` — add to keys list

## Decision
Pending
