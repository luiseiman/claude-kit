---
id: practice-2026-06-01-opus-4-6-fast-mode-override-removed
title: CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE removed (v2.1.154 deprecated, dropped 2026-06-01)
source: "official changelog"
source_type: upstream
discovered: 2026-06-01
status: inbox
tags: [models, deprecation, fast-mode, opus, urgent]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Description

`CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` was the documented opt-out path for users who needed to pin `/fast` to Opus 4.6 after the v2.1.142 default flip to Opus 4.7. The override was deprecated in v2.1.154 (2026-05-27) and removed on 2026-06-01.

`domain/model-ids.md` still lists the env var as a live opt-out under the "Fast mode (Opus toggle)" section. As of today, setting that env var is a silent no-op — sessions will run on Opus 4.7/4.8 fast mode regardless.

## Evidence

CHANGELOG v2.1.154: "`CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE` deprecated (removed 06/01)". `domain/model-ids.md` Fast mode section currently reads: "Pin to 4.6 for reproducibility: `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1`".

## Impact on dotforge

- `domain/model-ids.md` — remove or strike the override line. Replace with explicit note: "No path to pin fast mode to Opus 4.6 since 2026-06-01. Benchmarks predating the v2.1.142 flip (2026-05-14) are no longer reproducible via env var — re-baseline against current fast-mode default."
- Audit any project `.claude/settings.json` `env:` block referencing the var (low likelihood given dotforge templates don't ship it, but check `/forge audit` corpus).
- No template/hook changes needed — pure docs delta.

## Why urgent

The deprecation window (2026-05-27 → 2026-06-01) is past. Today is the cliff. Users relying on the override in scripts or env files get silent behavior change today.
