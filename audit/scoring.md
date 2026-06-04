# Scoring de Auditoría

El audit produce **dos números independientes**: `native_health` (0-10, el score principal) y `forge_adoption` (0-4, informativo).

## Dimensión A — Salud Nativa (score principal)

```
native_health_obligatorio = sum(items 1-5)    # máximo 10
native_health_recomendado = sum(items 6-15)   # máximo 10
native_health = native_health_obligatorio * 0.7 + native_health_recomendado * 0.3   # max = 7.0 + 3.0 = 10.0
native_health = min(native_health, 10)
```

**Efecto:** obligatorios perfectos sin recomendados = 7.0 (Bueno). Cada recomendado aporta 0.3 — para llegar a 9+ se necesitan al menos 7 recomendados.

### Cap por seguridad crítica

Si alguno de estos items es **0**, `native_health` tiene un cap máximo de **6.0**:
- Item 2 (settings.json) — sin permisos configurados
- Item 4 (hook block-destructive) — sin protección contra comandos destructivos

**Razón:** Un proyecto sin seguridad básica no puede ser "Excelente" independientemente de cuántos recomendados tenga.

### Interpretación

| native_health | Nivel | Significado |
|-------|-------|-------------|
| 9-10  | Excelente | Configuración nativa completa y madura. Solo ajustes menores. |
| 7-8.9 | Bueno | Sólido pero faltan algunos recomendados. |
| 5-6.9 | Aceptable | Funcional pero con gaps importantes. Necesita sync. |
| 3-4.9 | Deficiente | Faltan obligatorios. Necesita bootstrap parcial. |
| 0-2.9 | Crítico | Casi sin configuración. Necesita bootstrap completo. |

## Dimensión B — Adopción dotforge (informativo)

```
forge_adoption = sum(items B1-B4)   # 0-4
```

**No entra en `native_health` ni lo modifica.** Es un indicador de cuánta gobernanza dotforge adoptó el proyecto.

| forge_adoption | Label | Lectura |
|----|-------|---------|
| 0   | None    | Native-first puro. Válido y sin penalización. |
| 1-2 | Partial | Adopción parcial de la maquinaria. |
| 3   | Most    | Adopción amplia. |
| 4   | Full    | Gobernanza dotforge completa. |

Un `forge_adoption: 0` con `native_health: 10` es un resultado **excelente y deseable** bajo el principio native-first (ver `.claude/rules/domain/native-vs-dotforge-boundary.md`). No recomendar adoptar maquinaria dotforge solo para subir B.

## Prioridad de corrección (dimensión A primero)

1. Hook block-destructive (seguridad)
2. settings.json con deny list (seguridad)
3. CLAUDE.md (contexto para Claude)
4. Rules con globs (calidad de output)
5. Auto-memory bien usado (MEMORY.md como índice)
6. Lint hook (calidad de código)
7. El resto de la dimensión A

La dimensión B solo se aborda cuando el proyecto decide explícitamente adoptar gobernanza dotforge — nunca para "subir el número".
