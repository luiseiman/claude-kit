---
id: practice-2026-05-18-hook-terminal-sequence
title: Hooks pueden emitir terminalSequence para notificaciones desktop, titles, bells (v2.1.141)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [hooks, hook-events, notifications, claude-code-v2.1.141]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Claude Code v2.1.141 agrega el field `terminalSequence` al JSON output de los hooks. Permite que el hook emita escape sequences para:
- Desktop notifications (OSC 9 / iTerm2 / Apple)
- Window titles (`\033]0;<title>\007`)
- Terminal bell (`\a`)

Sin necesidad de controlling terminal (los hooks corren sin acceso directo al TTY desde v2.1.139). Ahora pueden señalizar al usuario sin romper la UI de Claude Code.

## Evidencia
Changelog oficial v2.1.141. Resuelve gap previo: hooks no podían notificar porque correr `osascript`/`notify-send` desde un hook sin terminal fallaba o corrompía la pantalla.

## Impacto en dotforge
- `template/domain/hook-events.md` — sección "Hook JSON output schema": agregar `terminalSequence` field con ejemplos por SO (macOS OSC 9, Linux notify-send equivalent via escape, Windows Terminal title).
- `template/hooks/notify-on-stop.sh` (nuevo posible) — hook ejemplo que dispara bell + title update cuando Claude termina un turn largo. Útil para sessions backgroundeadas.
- `docs/best-practices.md` — patrón "Notify on long-running turn complete".

## Decisión
Pendiente
