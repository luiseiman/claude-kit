---
id: practice-2026-05-18-rewind-summarize-partial
title: Rewind menu agrega "Summarize up to here" para compactar contexto previo (v2.1.141)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [rewind, compaction, checkpoint, context-management, claude-code-v2.1.141]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
El rewind menu (Esc-Esc o `/rewind`) agrega una sexta opción: "Summarize up to here". Comprime el contexto desde el inicio del session hasta el checkpoint elegido, manteniendo los turns posteriores intactos. Antes, las opciones de summarize eran: (a) summarize from here (compress recent), no summarize partial mid-history.

Casos de uso: sesión larga donde los primeros 50 turns ya fueron resueltos (exploración inicial) y se quiere mantener solo los últimos 20 intactos para debugging fino.

## Evidencia
Changelog oficial v2.1.141. Extiende la "Política de compactación basada en evidencia" de dotforge v3.7.1 con una tercera modalidad de compactación selectiva.

## Impacto en dotforge
- `template/domain/compaction-strategy.md` — agregar a la tabla `/compact` vs `/clear` vs subagent una cuarta columna: rewind+summarize-up-to-here. Caso de uso: preservar la última fase activa, comprimir la exploración pre-pivot.
- `docs/internal/compaction-strategy.md` — flow chart: incluir branch "fase actual identificable + historial previo descartable → rewind+summarize partial".
- `skills/forge-context-status/SKILL.md` (si existe `/forge context-status`) — recomendar rewind+summarize-up-to-here como opción cuando el bytes/5 detecta una "fase inicial" identificable.

## Decisión
Pendiente
