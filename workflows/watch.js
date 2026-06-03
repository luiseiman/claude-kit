// dotforge v4 workflow: forge-watch — HYBRID architecture
//
// PURPOSE: Detect Claude Code upstream changes affecting dotforge. Hybrid
// design: main thread does WebFetches (cheap, ~$0.30), workflow does the
// LLM-judgment work: schema-validated parsing, classification, adversarial
// verify, synthesis.
//
// ARGS (REQUIRED — main thread must pre-fetch upstream sources):
//   sources: Array<{ label, url, content }>   // pre-fetched upstream content
//   skepticism: string = 'normal'  // 'low' (skip verify) | 'normal' (1-pass) | 'high' (2-pass)
//   dryRun: boolean = false        // return after classify, no verify/synth
//   verbose: boolean = false       // extra logging
//   include_covered: boolean = false  // include covered items in synth (default: skip)
//
// EXPECTED COST (hybrid v2 — model-routed):
//   2 sources, smoke #4:          ~$0.05-0.08 at Haiku/Sonnet mixed
//   9 sources, skepticism=normal: ~$0.20-0.30 workflow + ~$0.30 main thread = ~$0.50-0.60 total
//
// CRITICAL: model routing per stage (smoke #3 spent ~$15 by inheriting session
// model Opus 4.7 across all agents). Smoke #4 fix:
//   - Phase 1 parse (mechanical extraction) → Haiku
//   - Phase 2 coverage (file reading + topic listing) → Haiku
//   - Phase 3 verify (judgment) → Sonnet, internal reasoning only (NO WebSearch)
//   - Phase 4 synth (composition) → Sonnet
//
// BUDGET CEILING: 150_000 output tokens (tighter than v1).
//
// CHANGES FROM HYBRID v1:
//   - ADDED explicit model: 'haiku' / 'sonnet' per agent (CRITICAL cost fix)
//   - REMOVED WebSearch from verify prompt (use internal reasoning only)

export const meta = {
  name: 'forge-watch',
  description: 'Watch Claude Code upstream docs for changes. Hybrid: main thread fetches, workflow parses+verifies+synthesizes.',
  whenToUse: 'After main thread has WebFetched upstream sources. Invoke with args.sources containing pre-fetched content.',
  phases: [
    { title: 'Parse sources', detail: 'extract structured findings from pre-fetched content (schema-validated)' },
    { title: 'Compare vs dotforge', detail: 'read RELEVANT domain rules only (based on detected categories)' },
    { title: 'Verify gaps', detail: 'adversarial verify on findings classified as gaps' },
    { title: 'Synthesize', detail: 'final delta report with priorities + capture suggestions' },
  ],
}

// === Defensive args parsing ===
const a = typeof args === 'string' ? JSON.parse(args) : (args || {})
const sources = Array.isArray(a.sources) ? a.sources : []
const skepticism = typeof a.skepticism === 'string' ? a.skepticism : 'normal'
const dryRun = !!a.dryRun
const verbose = !!a.verbose

if (sources.length === 0) {
  return {
    error: 'No sources provided. Main thread must pre-fetch and pass via args.sources = [{label, url, content}, ...]',
    metrics: { budget_spent: budget.spent() },
  }
}

log(`Args parsed: ${sources.length} pre-fetched sources, skepticism=${skepticism}, dryRun=${dryRun}`)

// === Schemas ===
const FINDING_SCHEMA = {
  type: 'object',
  properties: {
    title: { type: 'string', description: 'short feature name' },
    category: { type: 'string', enum: ['hook-event', 'setting', 'cli-flag', 'permission', 'workflow', 'subagent', 'mcp', 'other'] },
    version: { type: 'string', description: 'e.g. v2.1.161 if known, else empty' },
    description: { type: 'string', description: 'one-sentence summary' },
    priority: { type: 'string', enum: ['breaking', 'high', 'medium', 'low'] },
  },
  required: ['title', 'category', 'description', 'priority'],
}

const SOURCE_RESULT_SCHEMA = {
  type: 'object',
  properties: {
    source_label: { type: 'string' },
    findings: { type: 'array', items: FINDING_SCHEMA },
  },
  required: ['source_label', 'findings'],
}

const DOTFORGE_COVERAGE_SCHEMA = {
  type: 'object',
  properties: {
    covered_topics: { type: 'array', items: { type: 'string' } },
    covered_versions: { type: 'array', items: { type: 'string' } },
  },
  required: ['covered_topics', 'covered_versions'],
}

const VERDICT_SCHEMA = {
  type: 'object',
  properties: {
    title: { type: 'string' },
    confirmed: { type: 'boolean' },
    rationale: { type: 'string' },
  },
  required: ['title', 'confirmed', 'rationale'],
}

// === Phase 1: Parse pre-fetched sources (schema-validated) ===

phase('Parse sources')
log(`Parsing ${sources.length} pre-fetched sources`)

const parseResults = await parallel(sources.map((s) => () => {
  const prompt = `Parse this pre-fetched upstream documentation excerpt into structured findings.

SOURCE LABEL: ${s.label}
SOURCE URL: ${s.url || 'unknown'}
CONTENT (excerpt or full):
---
${s.content}
---

Extract material findings relevant to dotforge:
- title (short, one phrase)
- category (one of: hook-event, setting, cli-flag, permission, workflow, subagent, mcp, other)
- version (e.g. v2.1.161 if mentioned, else empty string)
- description (one factual sentence)
- priority (breaking if contract change; high if security or new behavior class; medium for new feature; low for UX/fixes only)

Return up to 8 most material findings. Skip enumeration of trivial items. Set source_label to "${s.label}".`
  return agent(prompt, {
    label: 'parse:' + s.label,
    phase: 'Parse sources',
    schema: SOURCE_RESULT_SCHEMA,
    model: 'haiku',  // mechanical extraction from curated content
  })
}))

const validResults = parseResults.filter(Boolean)
const allFindings = validResults.flatMap(r => (r.findings || []).map(f => ({ ...f, source: r.source_label })))

log(`Parsed: ${validResults.length}/${sources.length} sources, ${allFindings.length} raw findings`)
if (verbose) log(`Budget after parse: ${budget.spent()} tokens`)

if (allFindings.length === 0) {
  return {
    metrics: {
      sources: validResults.length,
      raw_findings: 0,
      budget_spent: budget.spent(),
    },
    report: '# dotforge watch — no findings extracted\n\nLas fuentes pre-fetched no contienen cambios materiales para dotforge.',
  }
}

// === Phase 2: Compare vs dotforge (smart — only relevant files) ===

phase('Compare vs dotforge')

// Determine which domain files are relevant based on detected categories
const detectedCategories = new Set(allFindings.map(f => f.category))
const fileMap = {
  'hook-event': ['hook-events.md', 'hook-architecture.md'],
  'setting': ['permission-managed-settings.md', 'auto-mode.md'],
  'cli-flag': ['cli-flags.md'],
  'permission': ['permission-model.md', 'permission-managed-settings.md', 'sandboxing.md'],
  'workflow': ['workflow-automation.md', 'workflow-and-ultracode-policy.md'],
  'subagent': ['agent-orchestration.md'],
  'mcp': ['permission-managed-settings.md'],
  'other': ['auto-mode.md'],
}
const relevantFiles = new Set()
detectedCategories.forEach(cat => (fileMap[cat] || []).forEach(f => relevantFiles.add(f)))
const filesToRead = Array.from(relevantFiles).map(f => `/Users/luiseiman/Documents/GitHub/dotforge/.claude/rules/domain/${f}`)

log(`Reading ${filesToRead.length} relevant domain files: ${Array.from(relevantFiles).join(', ')}`)

const coverage = await agent(
  `Read these dotforge domain rule files via Read tool and extract:
1. covered_topics: short list of distinct topics/features documented (e.g. "MessageDisplay", "workflowKeywordTriggerEnabled", "claude agents launcher"). Max 40 items.
2. covered_versions: list of upstream Claude Code versions explicitly mentioned (e.g. "v2.1.161"). Max 20 items.

Files to read (absolute paths):
${filesToRead.join('\n')}

Return JSON per schema. Topics should be SHORT (1-5 words each, lowercase).`,
  {
    label: 'coverage',
    phase: 'Compare vs dotforge',
    schema: DOTFORGE_COVERAGE_SCHEMA,
    model: 'haiku',  // file reading + topic enumeration, no judgment needed
  }
)

const coveredTopics = new Set((coverage.covered_topics || []).map(t => t.toLowerCase()))
const coveredVersions = new Set((coverage.covered_versions || []).map(v => v.toLowerCase()))

const classified = allFindings.map(f => {
  const tl = (f.title || '').toLowerCase()
  const dl = (f.description || '').toLowerCase()
  const vl = (f.version || '').toLowerCase()

  // Version-based coverage
  if (vl && coveredVersions.has(vl)) return { ...f, coverage: 'covered' }

  // Topic-based: title or description contains a covered topic
  for (const topic of coveredTopics) {
    if (topic.length < 4) continue  // skip too-short topics that match everything
    if (tl.includes(topic) || dl.includes(topic)) return { ...f, coverage: 'covered' }
  }

  return { ...f, coverage: 'gap' }
})

const gaps = classified.filter(f => f.coverage === 'gap')
const covered = classified.filter(f => f.coverage === 'covered')

log(`Classified: ${gaps.length} gaps, ${covered.length} covered`)
if (verbose) log(`Budget after compare: ${budget.spent()} tokens`)

if (dryRun) {
  return {
    dryRun: true,
    metrics: {
      sources: validResults.length,
      raw_findings: allFindings.length,
      gaps_count: gaps.length,
      covered_count: covered.length,
      coverage_topics_seen: coveredTopics.size,
      coverage_versions_seen: coveredVersions.size,
      budget_spent: budget.spent(),
    },
    gaps,
    covered_summary: covered.map(c => ({ title: c.title, version: c.version, category: c.category })),
  }
}

// === Phase 3: Verify high-priority gaps ===

phase('Verify gaps')

const toVerify = gaps.filter(f => ['breaking', 'high', 'medium'].includes(f.priority))
const verifyPasses = skepticism === 'high' ? 2 : skepticism === 'low' ? 0 : 1
let verified = toVerify

if (verifyPasses > 0 && toVerify.length > 0) {
  log(`Adversarial verify ${toVerify.length} gaps at skepticism=${skepticism}`)

  const verifyOnce = (f, passNum) => agent(
    `Adversarially verify dotforge watch finding using INTERNAL REASONING only.
Default confirmed=false unless the finding is clearly real and material.

Title: "${f.title}"
Category: ${f.category}
Version: ${f.version || 'unspecified'}
Description: ${f.description}
Priority claimed: ${f.priority}
Source: ${f.source}

DO NOT use WebFetch or WebSearch tools — too expensive. Use only your training knowledge + the description above.

Confirm (confirmed: true) only if ALL of:
(a) The description is internally consistent (not a hallucinated/confused entry)
(b) The feature/change is plausible given the version timeline
(c) Priority assignment is justifiable from description alone
(d) It is NOT a trivial UX fix (those should be priority=low and not warrant a gap entry)

When in doubt, set confirmed: false with rationale explaining the doubt.

Pass ${passNum}/${verifyPasses}.`,
    {
      label: 'verify:' + (f.title || '').slice(0, 20) + (passNum > 1 ? ':p' + passNum : ''),
      phase: 'Verify gaps',
      schema: VERDICT_SCHEMA,
      model: 'sonnet',  // judgment work, no fetches
    }
  )

  if (verifyPasses === 1) {
    const verdicts = await parallel(toVerify.map(f => () => verifyOnce(f, 1).then(v => ({ ...f, verdict: v }))))
    verified = verdicts.filter(Boolean).filter(r => r.verdict && r.verdict.confirmed)
  } else {
    const verdicts = await parallel(toVerify.map(f => () =>
      parallel([1, 2].map(p => () => verifyOnce(f, p)))
        .then(passes => {
          const valid = passes.filter(Boolean)
          const allConfirm = valid.length === 2 && valid.every(v => v.confirmed)
          return { ...f, verdict: { ...(valid[0] || {}), confirmed: allConfirm } }
        })
    ))
    verified = verdicts.filter(Boolean).filter(r => r.verdict && r.verdict.confirmed)
  }
}

log(`Verified gaps: ${verified.length} of ${toVerify.length} candidates`)

// === Phase 4: Synthesize ===

phase('Synthesize')

const reportPrompt = `Compose concise dotforge watch-upstream delta report in Spanish (es-AR).

VERIFIED GAPS (${verified.length}):
${JSON.stringify(verified.map(v => ({
  title: v.title, category: v.category, version: v.version, priority: v.priority,
  description: v.description, source: v.source,
  rationale: v.verdict && v.verdict.rationale,
})), null, 2)}

LOWER-PRIORITY UNVERIFIED FINDINGS (${gaps.filter(g => !verified.find(v => v.title === g.title)).length}):
${JSON.stringify(gaps.filter(g => !verified.find(v => v.title === g.title)).slice(0, 8).map(f => ({
  title: f.title, category: f.category, priority: f.priority, source: f.source,
})), null, 2)}

COVERED BY CATEGORY: ${JSON.stringify(
  covered.reduce((acc, f) => { acc[f.category] = (acc[f.category] || 0) + 1; return acc }, {})
)}

Format with sections (omit empty):
1. Header line: verified gaps / lower-priority / covered counts
2. ⚠️ BREAKING (if any verified at priority=breaking)
3. 🆕 NEW GAPS (high priority, verified)
4. 📝 PARTIAL/MEDIUM (medium, verified)
5. Lower-priority list (one-liners)
6. /forge capture suggestions for top 3-5 verified gaps

Spanish output, English for technical identifiers. No filler. Be specific.`

const report = await agent(reportPrompt, {
  label: 'synthesize',
  phase: 'Synthesize',
  model: 'sonnet',  // composition needs quality but not Opus
})

const totalSpent = budget.spent()
log(`✓ Workflow complete. Spent: ${totalSpent} tokens`)

return {
  report,
  metrics: {
    sources_parsed: validResults.length,
    sources_provided: sources.length,
    raw_findings: allFindings.length,
    gaps_detected: gaps.length,
    gaps_high_priority: toVerify.length,
    verified_gaps: verified.length,
    covered_count: covered.length,
    coverage_topics_seen: coveredTopics.size,
    coverage_versions_seen: coveredVersions.size,
    budget_spent: totalSpent,
    skepticism,
  },
}
