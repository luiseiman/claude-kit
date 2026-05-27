---
id: practice-2026-05-27-forcelogin-managed-bypass
title: forceLoginOrgUUID and forceLoginMethod did not apply to 3rd-party/API-key sessions (v2.1.147 security fix)
source: "official changelog"
source_type: upstream
discovered: 2026-05-27
status: active
tags: [security, managed-settings, auth, enterprise, breaking-fix, upstream]
tested_in: null
incorporated_in: ["docs/changelog.md#v391"]
replaced_by: null
---

## Description
**Enterprise managed-settings bypass** fixed in v2.1.147: the managed-settings `forceLoginOrgUUID` (restrict login to specific org UUIDs) and `forceLoginMethod` (`claudeai` | `console`) were enforced only against Claude.ai login sessions. **Third-party-provider** (Bedrock, Vertex, Foundry) and **API-key** (`ANTHROPIC_API_KEY`) sessions bypassed both restrictions silently.

An enterprise admin who configured `forceLoginOrgUUID: ["org-uuid"]` expecting all users in their organization to authenticate against that org would still see users on API-key sessions outside that org. Now fixed.

## Evidence
CHANGELOG v2.1.147: "Fixed enterprise login restrictions (`forceLoginOrgUUID` and `forceLoginMethod` managed-settings) not being enforced against third-party-provider and API-key sessions".

Cross-references the v3.8.0 `domain/auth.md` rule, which documents the auth source precedence and the v2.1.139+ behavior of API-key presence disabling Remote Control / `/schedule` / MCP connectors. That feature-gating was correct; the managed-settings enforcement was a separate hole.

## Impact on dotforge
- `.claude/rules/domain/auth.md` — add a "Enterprise enforcement notes" subsection: managed `forceLoginOrgUUID`/`forceLoginMethod` now apply to all session types as of v2.1.147; pre-v2.1.147 audits may have false sense of coverage
- `.claude/rules/domain/permission-managed-settings.md` — note the fix and the version
- Enterprise users (Chaco Digital S.A. context) should verify their managed settings on a current Claude Code build

## Decision
Pending
