---
id: practice-2026-05-18-worktree-bgisolation-none
title: worktree.bgIsolation "none" para repos donde worktrees son impracticables (v2.1.143)
source: https://code.claude.com/docs/en/changelog
source_type: changelog
discovered: 2026-05-18
status: active
effectiveness: informational
tags: [worktree, parallel-sessions, background-sessions, settings, claude-code-v2.1.143]
tested_in: null
incorporated_in: ['3.9.0']
replaced_by: null
---

## Descripción
Nuevo setting `worktree.bgIsolation: "none"` en settings.json. Permite que las background sessions editen el working copy directamente sin pasar por `EnterWorktree`. Pensado para repos donde worktrees son impracticables (submódulos profundos, build systems que asumen un único working tree, monorepos con symlinks).

Default sigue siendo el comportamiento aislado (cada bg session en su worktree). Opt-in explícito.

## Evidencia
Changelog oficial v2.1.143. Resuelve casos donde `EnterWorktree` fallaba o era inviable (e.g. Bazel, repos con .gitmodules complejos, builds que escriben al directorio raíz).

## Impacto en dotforge
- `template/domain/parallel-sessions.md` — agregar sección "When to disable worktree isolation" con tabla de trade-offs (aislamiento vs simplicidad). Incluir advertencia: sin aislamiento, dos bg sessions concurrentes pueden pisarse mutuamente.
- `template/settings.json.tmpl` — comentario sobre cuándo setear `worktree.bgIsolation: "none"`. Default: NO setear (mantener aislamiento).
- `domain/cli-flags.md` — sección env/settings: mencionar el setting.

## Decisión
Pendiente
