---
id: practice-2026-05-18-stop-hook-block-cap
title: Stop hooks que bloquean repetidamente ahora terminan tras 8 bloqueos consecutivos (v2.1.143)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [hooks, stop-hook, hook-architecture, claude-code-v2.1.143]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Claude Code v2.1.143 fixea un caso conocido: Stop hooks que retornaban `block` repetidamente entraban en loop infinito (hook bloquea → Claude reintenta → hook bloquea de nuevo). Nuevo cap: tras 8 bloqueos consecutivos, el turn termina con warning. Override via `CLAUDE_CODE_STOP_HOOK_BLOCK_CAP=<n>`.

Cambia el contrato implícito de los Stop hooks: ya no es válido asumir que un block "fuerza siempre" más trabajo. Los hooks que dependen de loops deben rediseñarse para señalizar progreso o aceptar terminación.

## Evidencia
Changelog oficial v2.1.143. Anti-pattern documentado en disler/claude-code-hooks-mastery y observaciones de @bcherny en X sobre Stop hooks que entran en loop.

## Impacto en dotforge
- `template/domain/hook-architecture.md` — sección Stop hook: agregar contrato "block must converge". Ejemplo: hook que valida tests debe contar attempts y dejar pasar tras N retries para evitar loop. Mencionar override env var.
- `template/hooks/*` — si dotforge ship algún Stop hook con potencial de loop, agregar contador de intentos. Revisar `pre-commit-validation.sh` y similares.
- `docs/best-practices.md` — sección hooks: anti-pattern "Stop hook infinite block".

## Decisión
Pendiente
