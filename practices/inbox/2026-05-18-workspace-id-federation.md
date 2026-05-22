---
id: practice-2026-05-18-workspace-id-federation
title: ANTHROPIC_WORKSPACE_ID para scopear tokens en workload identity federation (v2.1.141)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: inbox
tags: [auth, federation, enterprise, claude-code-v2.1.141, needs-enterprise-federation]
tested_in: null
incorporated_in: []
replaced_by: null
---

## Descripción
Claude Code v2.1.141 agrega la env var `ANTHROPIC_WORKSPACE_ID`. Cuando la federation rule del usuario cubre más de un workspace (típico en organizaciones enterprise multi-tenant), esta var scopea el token minted a un workspace específico.

Sin ella, el token puede caer en el workspace "default" del federation rule, lo cual es indeterminístico cuando hay >1 workspace elegible.

## Evidencia
Changelog oficial v2.1.141. Pieza nueva del modelo de auth federation (Bedrock/Vertex/Foundry con SAML/OIDC).

## Impacto en dotforge
- `template/domain/auth.md` (creada en v3.8.0) — agregar tabla "Env vars para federation": `ANTHROPIC_WORKSPACE_ID` con caso de uso "multi-workspace federation".
- POSPONER: niche enterprise. Sin valor para single-tenant ni para luiseiman (no usa federation). Revisitar si algún proyecto requiere multi-workspace.

## Decisión
Pendiente
