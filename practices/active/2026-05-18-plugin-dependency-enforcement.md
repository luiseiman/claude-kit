---
id: practice-2026-05-18-plugin-dependency-enforcement
title: Plugin dependency enforcement en claude plugin disable/enable (v2.1.143)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [plugins, dependencies, claude-code-v2.1.143]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Claude Code v2.1.143 (2026-05-15) agrega enforcement de dependencias entre plugins:
- `claude plugin disable <name>`: rechaza la operación si otro plugin habilitado depende del target. Muestra hint copy-pasteable con la disable-chain completa.
- `claude plugin enable <name>`: force-enables transitive dependencies (dependencias en cadena).

Implica que los plugin authors deben declarar dependencias en `plugin.json` explícitamente y los consumidores ya no pueden desinstalar dependencias sin saberlo.

## Evidencia
Changelog oficial v2.1.143 (https://code.claude.com/docs/en/changelog). Cambio breaking para flujos que automatizan disable de plugins sin chequear el grafo de dependencias.

## Impacto en dotforge
- `skills/plugin-generator/SKILL.md` — agregar paso "declarar dependencies en plugin.json si el plugin importa skills/agents/hooks de otro plugin".
- `docs/best-practices.md` — sección plugins: nueva nota sobre disable-chain.
- `docs/claude-vs-forge.md` (sección plugins) — mencionar enforcement como diferencia vs versiones previas.
- Posible: agregar template/plugin.json.tmpl con `dependencies` field si los plugins generados de dotforge consumen otros.

## Decisión
Pendiente
