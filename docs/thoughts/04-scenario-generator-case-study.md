# Case Study: Scenario Generator (a game-content team)

TypeScript CLI + agent skill pipeline generating branching game scenarios from real localization-QA assessment data. The most mature example of deterministic validation + scoring + autoresearch on prompts.

## What Was Built

A hybrid pipeline: deterministic TypeScript CLIs for DB extraction, validation, and scoring; Claude Opus for creative narrative generation; autoresearch on prompts until scores exceeded 85.0 threshold.

## Gold Standard Approach

Three layers:
1. Hand-crafted key moments (18 CSV rows) -- baseline for key moments pipeline
2. SME-validated scenarios (9 scenarios with feedback cycles) -- reference corpus
3. 5 structured treatment + script gold examples in `temp/content-examples/` -- primary benchmark

## The 5-Dimension Deterministic Scorer

`src/eval/score-scenario.ts` -- composite score >= 85.0 quality gate:

| Dimension | Weight | What it checks |
|-----------|--------|----------------|
| Structure | 30% | KM count 2-4, unique EI codes, valid graph, edge types |
| Mermaid valid | 15% | Zod parse, root exists, all beats reachable |
| Prose quality | 25% | Length bounds, opening-word diversity, persona mention |
| Edge quality | 15% | Label length, Best != Worst on same KM |
| Dialogue quality | 15% | Script blocks, speaker types, playerLine on typed edges |

## Autoresearch Results

- Ship-readiness scores: ~99.8 treatment / ~98.4 script averages (far above 85.0 threshold)
- 7/10 perfect treatment scores (100.0); lowest script 92.8
- Prompt iterations: 4 treatment experiments (3 kept), 5 script experiments (4 kept)

## Key Patterns for the Factory

1. **Deterministic scorer** -- no LLM judge variance; structural validation with weighted dimensions
2. **Prompts as markdown in git** -- autoresearch iterates prompts, not pipeline code
3. **Zod structured output** -- LLM output validated before acceptance; retry on failure
4. **Threshold-driven decisions** -- Path B chosen because first run exceeded 85.0; no Path A needed
5. **CLI + skill hybrid** -- reliable structured steps in TypeScript; agent handles orchestration
6. **Lazy sanitization** -- cost proportional to output, not corpus size
7. **Registry-based dedup** -- accumulative runs without duplicate scenarios
