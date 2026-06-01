---
id: practice-2026-05-19-watchdog-triage-symmetry-and-stuck-detection
title: Watchdog triage debe ser simétrico en suppression y stuck-detection requiere backlog
source: "own experience"
source_type: experience
discovered: 2026-05-19
status: active
tags: [monitoring, alerting, watchdog, false-positives, sre, observability, suppression]
tested_in: vps-control
incorporated_in: ["docs/monitoring-patterns.md", "docs/changelog.md#v3101"]
replaced_by: null
---

## Description

Dos reglas para triages de monitoring que combinan "horario operativo" con detección de problemas:

1. **Simetría en suppression**: si un servicio tiene `schedule` (ej. `market_hours_ar`) y los checks de container-running y endpoint suprimen alertas fuera de ventana, **todos los checks del mismo container deben aplicar el mismo gating** — incluido `healthcheck=unhealthy`, `deep_health`, OOM, etc. Asimetría = falso positivo garantizado fuera de ventana.

2. **Stuck-detection requiere backlog**: cuando una regla mide "tiempo desde último evento exitoso" (lag), **escalar requiere `pending > 0`** (cola con backlog). Lag alto + pending=0 = silencio upstream legítimo, no stuck. La métrica de tiempo sola es ambigua y dispara falsos positivos en períodos genuinamente quietos (noche, finde, feriado, downtime upstream).

## Evidence

Descubierto en vps-control durante un alerta `sev=escalate` por `signals_worker: sin parse hace 545 min (>120)`:

- Diagnóstico real: WAHA estaba sano, signals_api funcionando, worker bloqueado en XREADGROUP sin entries que consumir. Los 4 grupos de WhatsApp simplemente no habían mandado mensajes en 9hs (madrugada AR + mercado cerrado). `pending=0` confirmaba que NO había stuck.
- Regla original: `if lag > 120 → escalate` (ignoraba pending).
- Fix: `if lag > 120 AND pending > 0 → escalate`. Comentario adyacente ya decía "sin pendientes → silencio legítimo" pero la lógica no lo respetaba.

En el mismo triage descubrí asimetría en suppression: `container_running != true`, `endpoint sin respuesta`, y `body_status degraded` todos respetaban `out_of_window` (downgrade a info), pero `health=unhealthy` no — escalaba siempre. cotiza-api unhealthy fuera de market hours disparaba escalate constante.

Fix con mismo patrón:
```bash
if [ "$health" = "unhealthy" ]; then
  if [ "$out_of_window" = "true" ]; then
    add_issue container info "$name" "healthcheck=unhealthy ($suppress_reason)" ...
  else
    add_issue container "$default_sev" "$name" "healthcheck=unhealthy" ...
  fi
fi
```

## Impact on dotforge

- Posible nueva regla en `template/.claude/rules/` para proyectos de tipo "watchdog/monitoring/SRE": checklist de simetría de suppression + corroboración de backlog en stuck-detection.
- Posible adición a `template/CLAUDE.md` sección de "anti-patterns de monitoring" si claude-kit ya tiene una.
- Candidato para `audit/checklist.md`: cuando un proyecto tiene `triage.sh` o equivalente, validar que todos los checks de un mismo container apliquen el mismo gating de schedule.

## Decision

Pending
