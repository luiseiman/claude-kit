---
id: practice-2026-05-27-extra-usage-renamed-usage-credits
title: /extra-usage renamed to /usage-credits (v2.1.144 — old name still works)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [slash-commands, rename, cosmetic, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v3100"]
replaced_by: null
---

## Description
Slash command `/extra-usage` was renamed to `/usage-credits` in v2.1.144. The old name continues to work as an alias. CLI copy across menus and help text updated to the new name.

Mostly cosmetic — small docs sync.

## Evidence
CHANGELOG v2.1.144: "Renamed 'extra usage' to 'usage credits' across CLI copy; `/extra-usage` is now `/usage-credits` (old name still works)".

## Impact on dotforge
- `docs/claude-vs-forge.md` — slash command tables (EN+ES): replace `/extra-usage` with `/usage-credits` if referenced
- Any internal docs that mention "extra usage" — sync to "usage credits"

## Decision
Pending
