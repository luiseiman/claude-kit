# ADR v4 — Frontera native-first: qué mantiene dotforge y qué cede

**Fecha:** 2026-06-03
**Estado:** Aceptada
**Decisión asociada:** complementa `docs/v3/DECISIONS.md`; criterio permanente en `.claude/rules/domain/native-vs-dotforge-boundary.md`

## Contexto

En los últimos 6 meses Claude Code absorbió nativamente buena parte de la superficie
que dotforge construyó como capa externa: hooks maduros, `hookify`, auto-memory,
`/workflows`, Agent Teams, `/code-review`, `/init`, sandboxing, permission cascade.
El changelog reciente de dotforge es mayormente *reactivo* (sincronizar con
v2.1.144–v2.1.161). Riesgo: gastar energía corriendo detrás de features nativas en vez
de crear valor no-replicable.

## Principio adoptado

**Lo nativo gana por defecto. dotforge solo existe donde lo nativo no llega.**
El scope se reduce a medida que Claude Code crece, y eso es correcto.

## Método (obligatorio)

Toda decisión de frontera exige verificar el estado nativo ACTUAL contra docs oficiales
ANTES de clasificar. Aplicar el principio sobre supuestos viejos produce decisiones
erróneas: en la primera pasada se recomendó "recortar v3 fuerte" apoyándose en un
`COMPETITIVE.md` con semanas de antigüedad; la verificación fresca mostró que el delta
de v3 NO está cubierto nativamente. Por eso `/forge watch` deja de ser meta-trabajo:
es el insumo que hace correctas las decisiones de scope.

## Evidencia verificada (2026-06-03)

- **hookify** ([github.com/anthropics/claude-code/plugins/hookify](https://github.com/anthropics/claude-code/tree/main/plugins/hookify)):
  plugin oficial, wrapper de conveniencia sobre hooks, acciones binarias `warn`/`block`.
  Sin escalación de 5 niveles, sin state compartido, sin override auditable. Anthropic
  no shipeó capa de behavior governance. → delta de v3 **no cubierto**.
- **auto-memory** ([code.claude.com/docs/en/memory](https://code.claude.com/docs/en/memory)):
  estrictamente per-proyecto. NO propaga cross-project (issues #36561, #39195 abiertas
  sin timeline). Para *instrucciones* compartidas sí hay nativo (global CLAUDE.md +
  symlinks en `.claude/rules/`), pero no para *learnings* ni para propagación con merge.

## Decisión

**MANTENER** (sin equivalente nativo):
1. Domain rules — activo principal.
2. Propagación cross-project con merge/customización preservada (`forge:section` + sync).
3. Behaviors v3 (escalación + state + override audit) — sujeto a validar uso real del
   `overrides.log` en proyectos de producción.
4. Registry + audit cross-project — **reorientado** a auditar buen uso de lo nativo.

**CEDER** (nativo lo resuelve):
- Captura individual de learnings → auto-memory.
- Reglas idénticas compartidas (sin merge) → symlinks + global CLAUDE.md.
- Workflows / orquestación → `/workflows`, Agent Teams (ya cedido en v4).
- CLAUDE.md base → `/init`.
- One-shot code review → `/code-review`.
- Model routing como sistema → `/effort` (queda como documentación).

## Consecuencias

- Es un downsizing estratégico, no una expansión. El compilador de behaviors queda
  candidato a retiro si el delta del override log no se sostiene por demanda real.
- No se retira código sin verificación empírica previa de que el nativo cubre el caso.
- El audit reorientado ("¿usás bien lo nativo?") es la pieza de mayor ROI nuevo y no
  envejece con cada release de Claude Code.

## Validación pendiente

- ¿Los proyectos de producción (trading, banca NBCH) consultan `overrides.log`?
  Decide el futuro del compilador de behaviors v3.
