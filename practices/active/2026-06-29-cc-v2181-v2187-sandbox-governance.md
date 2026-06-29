---
id: practice-2026-06-29-cc-v2181-v2187-sandbox-governance
title: "v2.1.181-v2.1.187 — sandbox + governance hardening (credentials, AppleEvents, sessionUrl, version-gating)"
source: "/forge watch — github.com/anthropics/claude-code CHANGELOG.md (verified verbatim)"
source_type: changelog
discovered: 2026-06-29
status: active
tags: [claude-code-v2.1.181, claude-code-v2.1.187, security, sandboxing, managed-settings, attribution]
tested_in: null
incorporated_in: ["v4.1.0"]
replaced_by: null
priority: high
---

## Description

Four security/governance features across v2.1.181-v2.1.187. Verbatim quotes from CHANGELOG.md:

### v2.1.187

1. **`sandbox.credentials`**
   > "Added `sandbox.credentials` setting to block sandboxed commands from reading credential files and secret environment variables"
   - Kernel-level read-deny on credential file paths (~/.aws, ~/.ssh, ~/.kube, etc.) + secret env vars
   - Complement to existing `sandbox.filesystem.denyRead` patterns
   - Defense-in-depth for trading bots, cotiza-api-cloud, InviSight (projects with cloud creds in env/home)

2. **`attribution.sessionUrl`**
   > "Added `attribution.sessionUrl` setting to omit the claude.ai session link from commits and PRs"
   - Privacy control — prevents leaking internal session URLs to public GitHub repos
   - Pairs with existing `attribution.commit` and `attribution.pr` settings

3. **`requiredMinimumVersion` / `requiredMaximumVersion`** managed settings
   > "Added `requiredMinimumVersion` and `requiredMaximumVersion` managed settings"
   - Version-gating for enterprise deployments
   - Block startup if Claude Code version is out of range

### v2.1.181

4. **`sandbox.allowAppleEvents`** (macOS)
   > "Added `sandbox.allowAppleEvents` opt-in setting that lets sandboxed commands send Apple Events on macOS"
   - macOS-specific Apple Events permission (Automator, Finder integration, etc.)
   - Default deny — explicit opt-in required

## Impact on dotforge files

- `domain/sandboxing.md` — add `sandbox.credentials` (priority slot — security cap candidate?), add `sandbox.allowAppleEvents` macOS section
- `domain/permission-managed-settings.md` — add `requiredMinimumVersion`/`requiredMaximumVersion` under enterprise section
- `_common.md` (Git section) — add `attribution.sessionUrl` next to existing `attribution.commit`/`attribution.pr` reference
- Audit B6 (sandbox item) in `audit/scoring.md` — consider whether `sandbox.credentials` should be promoted to obligatory for production-tier projects

## Decision

Pending — incorporate at next `/forge update`. **High priority** because security. Consider for next minor bump.
