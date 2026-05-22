---
id: practice-2026-05-18-claude-agents-cli-flags
title: claude agents acepta 9 flags para configurar dispatched sessions (v2.1.141-143)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [cli-flags, agent-view, background-sessions, parallel-sessions, claude-code-v2.1.141, claude-code-v2.1.142, claude-code-v2.1.143]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Tres versiones consecutivas extienden `claude agents` (agent-view dashboard) con flags que configuran las sesiones background dispatched desde el view:

**v2.1.141**: `--cwd <path>` — scope del session list a un directorio.

**v2.1.142**: `--add-dir`, `--settings`, `--mcp-config`, `--plugin-dir`, `--permission-mode`, `--model`, `--effort`, `--dangerously-skip-permissions`.

**v2.1.143**: además, `/bg` y ←-detach preservan `--mcp-config`, `--settings`, `--add-dir`, `--plugin-dir`, `--strict-mcp-config`, `--fallback-model`, `--allow-dangerously-skip-permissions` al backgroundear sesiones interactivas. Bg sessions dispatched desde `claude agents` honran `permissions.defaultMode` de settings.json (antes lo overrideaban a auto).

Net effect: agent-view ya no es solo un dashboard de monitoreo — es un launcher completo de bg sessions con la misma superficie de configuración que `claude` interactivo.

## Evidencia
Changelog oficial v2.1.141, v2.1.142, v2.1.143. Cierra el gap entre `claude --bg` (sesión única backgroundeada) y `claude agents` (orquestación múltiple).

## Impacto en dotforge
- `template/domain/parallel-sessions.md` — sección "Background sessions" actualmente menciona `claude agents` brevemente. Agregar subsección "Configuring dispatched sessions" con tabla de flags + persistencia en /bg detach.
- `template/domain/cli-flags.md` — agregar entradas para los 9 flags bajo "claude agents" subcommand. Documentar diferencia: `claude agents --model X` setea default para futuros dispatched, no para sesiones ya corriendo.
- `docs/best-practices.md` — patrón "configure once, dispatch many" en agent-view.
- Posible: skill nueva `/forge bg-session` que dispare `claude agents` con flags pre-armados desde settings dotforge.

## Decisión
Pendiente
