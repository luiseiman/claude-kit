---
id: practice-2026-05-18-powershell-execution-policy
title: PowerShell tool pasa -ExecutionPolicy Bypass y se habilita por default en Windows (v2.1.143)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: inbox
tags: [windows, powershell, security, bedrock, vertex, foundry, claude-code-v2.1.143, needs-windows-user]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Descripción
Claude Code v2.1.143 hace dos cambios en el PowerShell tool:
1. Pasa `-ExecutionPolicy Bypass` por default. Opt-out via `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1`.
2. Habilitado por default en Windows para usuarios de Bedrock, Vertex, Foundry. Opt-out via `CLAUDE_CODE_USE_POWERSHELL_TOOL=0`.

Implicación security: `-ExecutionPolicy Bypass` permite ejecutar scripts no firmados. Para entornos enterprise con AppLocker o políticas firmadas, esto es un boundary que cruza el modelo de confianza del SO.

## Evidencia
Changelog oficial v2.1.143. Cambio breaking para usuarios Windows enterprise.

## Impacto en dotforge
- `docs/security-checklist.md` — agregar entrada Windows: "Si tu organización exige scripts firmados, set `CLAUDE_CODE_POWERSHELL_RESPECT_EXECUTION_POLICY=1` antes de invocar `claude` en Windows. Considerar deshabilitar el tool entero con `CLAUDE_CODE_USE_POWERSHELL_TOOL=0` si la política PSScriptAnalyzer es estricta."
- `template/settings.json.tmpl` — comentario opt-out para Windows enterprise.
- POSPONER si dotforge actualmente no targetea usuarios Windows (luiseiman es macOS). Reevaluar si surge demanda Windows.

## Decisión
Pendiente
