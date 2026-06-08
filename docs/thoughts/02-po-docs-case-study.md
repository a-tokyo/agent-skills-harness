# Case Study: PO Product Documentation Skill

Domain-workflow skill that replaces a recurring manual product-documentation review with an AI-automated documentation pipeline. The most mature example of a skill with a built-in self-improvement loop.

## What Was Built

A multi-phase documentation skill (SKILL.md ~630 lines) that:
1. Analyzes screenshots of product pages
2. Discovers code, backend, DB, and feature flag context
3. Enriches with business rules from Jira, Slack, Confluence, GitHub
4. Generates Confluence-formatted documentation
5. Scores against a 14-dimension rubric
6. Iterates up to 3 times to meet quality bar
7. Publishes to Confluence with ADF post-processing

## Gold Standard Approach

- **Source**: existing human-written documentation pages (a primary dashboard page used as the gold standard)
- **Calibration**: before generating, the skill fetches 1-2 completed sibling pages to calibrate quality, depth, and style
- **Comparison**: generated output compared visually and structurally against existing pages

## The 14-Dimension Rubric

Each dimension scored 0-2 (0=missing, 1=partial, 2=solid). Target: 24+/28.

1. Coverage -- every labeled screenshot item has a table row
2. UI depth -- identity + function + constraints documented
3. Business-rule depth -- formulas, lifecycle transitions, enums
4. Permissions -- outcome-headed columns, hierarchical user grouping
5. Cross-references -- live URLs + Confluence links + GitHub links
6. Testing hints -- concrete test data per calculated value
7. Edge cases -- empty states, color coding, conditional visibility
8. Formatting -- table headers match template, clean markdown
9. Evidence discipline -- inline citations, grounded claims
10. Template conformance -- mandatory page structure followed
11. PO accessibility -- plain-English glosses for technical tokens
12. Technical preservation -- no formulas/enums/links dropped
13. Source-link annotation -- parenthetical descriptions on all links
14. Description/Notes split -- product meaning vs code symbols

## Built-In Autoresearch Loop (Phase 5)

```
LOOP (max 3 iterations):
  1. Score against 14 dimensions
  2. Identify lowest-scoring dimensions
  3. Fix them -- dig deeper into code/Jira/Slack
  4. Re-score
  5. If score >= threshold or no improvement, stop
```

This is the most advanced pattern: the skill self-improves at runtime, not just at creation time.

## Subagent Strategy

The skill prescribes specific subagent decomposition:
- Phase 2: 3 subagents (menu search, API endpoint tracing, feature flag search)
- Phase 3: 6 subagents (business rules, Confluence, Jira, GitHub, Slack, git blame)
- Phase 5: 2 subagents (screenshot upload, browser exploration)
- Fast models for search/lookup, default model for analysis/generation

## Key Patterns for the Factory

1. **Skill-embedded quality loop**: the autoresearch loop is INSIDE the skill, not just at creation time
2. **14-dimension rubric**: much more granular than the structured-doc case's 6 dimensions -- better for complex outputs
3. **Calibration-before-generation**: read existing exemplars before writing
4. **Grounding rule**: every claim must have a code citation (anti-hallucination)
5. **Confidence markers**: `[NEEDS REVIEW]` for uncertain items with reviewer routing
6. **Tool-chain fallback**: primary → fallback → skip, never block
7. **Multiple intake formats**: screenshots, meetings, notes -- normalize before processing
