---
id: practice-2026-06-01-stopfailure-matchers
title: StopFailure matcher values for production session-report routing
source: "watch upstream — code.claude.com/docs/en/hooks"
source_type: docs
discovered: 2026-06-01
activated: 2026-06-01
status: active
tags: [hooks, StopFailure, session-report, production, observability, monitoring]
tested_in: null
incorporated_in: [".claude/rules/domain/hook-events.md, template/hooks/session-report.sh"]
replaced_by: null
priority: medium
---

## Description

`StopFailure` hooks accept `error_type` as a matcher with documented values: `rate_limit`, `authentication_failed`, `billing_error`, `server_error`. This enables production-grade routing: e.g. trading bots can page on `billing_error` (subscription expired → bot dies silently otherwise), suppress notifications on `rate_limit` (transient), and route `authentication_failed` to a token-rotation routine.

## Evidence

- Doc: code.claude.com/docs/en/hooks — StopFailure event matcher column lists the four values explicitly
- Current `.claude/rules/domain/hook-architecture.md` line 15: lists `StopFailure` as a Turn-level event but doesn't document the matcher values
- Current `.claude/rules/domain/hook-events.md`: no StopFailure section
- Current `template/hooks/session-report.sh`: probably doesn't differentiate by error type (verify)

## What to document

| error_type | When it fires | Recommended action |
|------------|---------------|--------------------|
| `rate_limit` | API request hit RPM/TPM ceiling | Log only; auto-retry handled by Claude Code; alert if >N/hour |
| `authentication_failed` | OAuth token expired or revoked | Trigger token rotation routine (or page operator) |
| `billing_error` | Subscription quota exhausted or payment failed | PAGE — bot will not recover without intervention |
| `server_error` | Anthropic-side 5xx | Log + degrade gracefully; alert if persistent (>5min) |

## Concrete hook patterns

```json
{
  "StopFailure": [
    {"matcher": "billing_error", "hooks": [{"type": "command", "command": ".claude/hooks/page-operator.sh billing"}]},
    {"matcher": "authentication_failed", "hooks": [{"type": "command", "command": ".claude/hooks/rotate-token.sh"}]},
    {"matcher": "rate_limit", "hooks": [{"type": "command", "command": ".claude/hooks/log-rate-limit.sh"}]},
    {"matcher": "server_error", "hooks": [{"type": "command", "command": ".claude/hooks/log-server-error.sh"}]}
  ]
}
```

## Impact on dotforge

- `.claude/rules/domain/hook-events.md`: add a StopFailure section with matcher table + concrete patterns
- `.claude/rules/domain/hook-architecture.md`: cross-reference matcher table
- `template/hooks/session-report.sh`: extend to read `error_type` from JSON input, route accordingly
- `stacks/trading/` (or future `trading-bots/`): bundled `page-operator.sh` for billing/auth failures
- `audit/checklist.md`: item for production projects ("StopFailure routing configured for billing_error")

## Decision
Pending
