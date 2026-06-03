---
id: practice-2026-06-03-v2160-security-prompts-shell-rc
title: v2.1.160 prompts before writing shell rc + build-tool config in acceptEdits
source: "watch upstream — github.com/anthropics/claude-code/releases/tag/v2.1.160"
source_type: docs
discovered: 2026-06-03
activated: 2026-06-03
status: active
tags: [v2.1.160, security, acceptEdits, shell-rc, build-config]
tested_in: null
incorporated_in: [".claude/rules/domain/permission-model.md, .claude/rules/domain/sandboxing.md"]
replaced_by: null
priority: medium
---

## Description

v2.1.160 added explicit user confirmation prompts before Claude Code writes to two categories of high-blast-radius files:

1. **Shell startup files** (always prompts, regardless of permission mode):
   - `.zshenv`, `.zlogin`, `.bash_login`
   - `~/.config/git/` (any file)

2. **Build-tool config files** (prompts when in `acceptEdits` mode):
   - `.npmrc`, `.yarnrc*`, `bunfig.toml`, `.bazelrc`
   - `.pre-commit-config.yaml`
   - `.devcontainer/` (any file)

## Evidence

- Source: https://github.com/anthropics/claude-code/releases/tag/v2.1.160
- Reason: these files can execute arbitrary commands at shell-startup time or alter the entire toolchain, so even with `acceptEdits` enabled, a single LLM hallucination can compromise the dev environment

## Impact on dotforge

- `domain/permission-model.md` — `acceptEdits` mode semantics changed: it's no longer "approve everything". Specific paths still prompt. Add a "Paths that always prompt regardless of mode" subsection.
- `domain/sandboxing.md` — defense-in-depth note: these prompts are a Claude-Code-level safety; `sandbox.filesystem.denyWrite` is the kernel-level equivalent that can't be bypassed by mode
- `template/settings.json.tmpl` — consider whether to ADD these paths to `deny` for projects where Claude should never touch them at all (vs prompting). Recommended: leave default Claude Code prompt behavior; only add to `deny` if project has stricter policy
- `stacks/python-fastapi/settings.json.partial`, `stacks/node-express/settings.json.partial` — `.pre-commit-config.yaml` is touched routinely; consider explicit `allow` rule for these projects to avoid prompt fatigue while still requiring deliberate config

## Decision
Pending
