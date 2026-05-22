---
id: practice-2026-05-18-plugin-root-skill-md
title: Plugins con SKILL.md root-level (sin skills/) ahora se exponen como skill (v2.1.142)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [plugins, skills, packaging, claude-code-v2.1.142]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Claude Code v2.1.142 detecta plugins con un `SKILL.md` en el root (sin directorio `skills/`) y los surface como skill directamente. Antes, un plugin con SKILL.md root se ignoraba salvo que estuviera bajo `skills/<name>/SKILL.md`.

Implica: plugins single-skill ya no necesitan boilerplate de estructura — basta con `plugin.json` + `SKILL.md` en la raíz. Reduce friction para crear plugins simples.

## Evidencia
Changelog oficial v2.1.142. Confirma además el fix relacionado: "Fixed plugins using `skills: ["./"]` showing a false 'path escapes plugin directory' error" — soporte oficial para skill-en-root.

## Impacto en dotforge
- `skills/plugin-generator/SKILL.md` — agregar opción de generar plugin "flat" (SKILL.md root) vs "structured" (skills/<name>/). Default debería ser flat para plugins single-skill, structured para multi-skill.
- `template/plugin/` (si existe) — incluir ambos templates.
- `docs/creating-stacks.md` o equivalente — sección plugins: documentar las dos shapes.

## Decisión
Pendiente
