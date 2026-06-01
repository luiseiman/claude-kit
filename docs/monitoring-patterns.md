# Monitoring Patterns — Avoiding False Positives

Cross-cutting patterns for any monitoring/watchdog system layered on top of services with operational schedules or asynchronous workloads. Discovered through dotforge's own `vps-control` watchdog (May 2026 incident series). Not Claude Code-specific — applicable to Prometheus alerts, Datadog monitors, custom watchdogs, anything that fires on rules.

---

## 1. Suppression symmetry

If a service has an operational schedule (`market_hours_ar`, `business_hours`, batch windows) and the rule for "container running" suppresses alerts outside the window, **every other check on the same service must apply the same gating** — including `healthcheck=unhealthy`, deep_health, OOM, endpoint 5xx.

Asymmetric suppression guarantees false positives outside the window: e.g. the container check is silent on weekends but the endpoint check fires because the service responds 503 to a probe that fires regardless of schedule.

**Rule:** schedule gating is a property of the service, not of the check. Apply it uniformly across all rules touching that service.

## 2. Stuck-detection requires backlog

When a rule measures "time since last successful event" (lag, staleness, freshness), **escalation requires evidence of a backlog** (`pending > 0`, queue depth growing, retries accumulating). Lag alone is ambiguous:

- Lag high + pending = 0 → silent upstream (quiet groups, quiet market, holiday)
- Lag high + pending > 0 → genuinely stuck (worker hung, OAuth expired, dependency down)

Alerting on lag alone fires false positives during legitimately quiet periods (nights, weekends, holidays, upstream maintenance). The metric of time is not the same as the metric of brokenness.

**Rule:** combine lag with a saturation signal (queue, pending, retries) before escalating.

## 3. Throttle by sub-issue, not by aggregate hash

Watchdogs often deduplicate alerts by hashing the full set of active issues (`sha256(issue_set)`). This breaks when issues mutate: every time a secondary issue appears or disappears (a different service entering/exiting its operational window, a transient flap on an unrelated check), the aggregate hash changes — and the throttle counter resets, producing re-alerts on the same underlying incident.

**Rule:** throttle per `(kind, name, severity, stable_signature)` of each issue individually. Each incident has its own cooldown. New issues alert immediately; existing issues respect their own 30-minute (or whatever) re-alert window regardless of what's happening on adjacent services.

Measured impact (vps-control, 2026-05-31): aggregate-hash throttle produced ~10 alerts/3 hours on one persistent incident; sub-issue throttle: 1 alert/30 min (the intended cadence). 6x noise reduction without changing the underlying detection logic.

## 4. On-demand services need a distinct schedule class

Services that the user (or another system) starts on demand and stops when done should not be monitored as "always-on" services. `exited` is the expected state by default; alerting on it is noise.

**Rule:** introduce a schedule class like `on_demand` where `running=false` is suppressed (info, not warn/escalate), but `running=true && unhealthy` still escalates (someone started it, it should work).

Example: `ibeam-live` (Interactive Brokers gateway) is on_demand because each start requires 2FA approval. With `schedule: always`, every shutdown produces 150+ alerts over 3 days. With `schedule: on_demand`, zero alerts during exited periods, full alerting during attempted use.

## 5. Don't auto-restart what requires human interaction

If a service requires human action to come up cleanly (2FA approval, captcha, manual config), **disable container restart policies** (`restart: no` instead of `restart: unless-stopped`). Auto-restart will produce a loop: service dies → restart → asks for 2FA → no one answers → hangs or dies again → restart → repeat.

**Rule:** for services requiring human-loop steps, the orchestration layer (frontend, dashboard, manual command) owns the lifecycle. Docker / systemd should not.

---

## Cross-references

- dotforge implementation: `vps-control` repo (private), files `watchdog/run.sh`, `watchdog/triage.sh`, `registry/projects.yml`
- Related domain rule: `.claude/rules/domain/hook-architecture.md` § Stop hook convergence (similar "don't loop forever" principle, different layer)
- Originating practice: `practices/active/2026-05-19-watchdog-triage-symmetry-and-stuck-detection.md`
