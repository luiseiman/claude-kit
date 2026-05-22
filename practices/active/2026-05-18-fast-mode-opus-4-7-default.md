---
id: practice-2026-05-18-fast-mode-opus-4-7-default
title: Fast mode default flipped from Opus 4.6 to 4.7 (v2.1.142)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [model-ids, fast-mode, opus, claude-code-v2.1.142]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Claude Code v2.1.142 (2026-05-14) cambia el default de fast mode: ahora usa Opus 4.7 (antes Opus 4.6). Opt-out via `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` para pinear a 4.6.

Implica: usuarios que dependían del comportamiento/cost profile de 4.6 en fast mode tienen que setear la env var explícitamente o aceptar el upgrade.

## Evidencia
Changelog oficial v2.1.142. Coherente con el flip previo de default model `claude-opus-4-6 → claude-opus-4-7` (v2.1.111) ya capturado en `2026-04-17-opus-4-7-new-model-id.md`. Este es la extensión del flip al fast mode.

## Impacto en dotforge
- `template/domain/model-ids.md` — agregar nota: "Fast mode (toggle `/fast` en Opus 4.6/4.7) default = 4.7 desde v2.1.142. Pin a 4.6 con `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE=1` solo si se requiere reproducibilidad de output."
- `docs/best-practices.md` — sección modelos: actualizar si menciona fast mode.
- `domain/cli-flags.md` — sección env vars: añadir `CLAUDE_CODE_OPUS_4_6_FAST_MODE_OVERRIDE`.

## Decisión
Pendiente
