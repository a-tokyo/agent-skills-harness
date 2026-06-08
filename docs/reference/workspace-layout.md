# Workspace Layout Reference

The factory creates one self-contained build folder per skill, `builds/<skill-name>/`,
organized into three ownership/lifecycle zones: `input/` (you own it), `work/` (the factory
owns it), and `output/` (the factory owns it). This document describes every file and
directory the factory produces.

`builds/` is gitignored in this harness — it is your working area. (`self-test/` is the factory's own
regression test; it uses a separate evaluation layout, not the three-zone build layout described here.)

## Full Structure

```
builds/<skill-name>/
  input/                          # HUMAN: gold standards + study materials, ANY structure
    ...                           # drop files however you like; the factory discovers them

  work/                           # FACTORY: everything generated during the build (not shipped)
    manifest.yaml                 # Factory-derived index of the gold standards in input/ (you confirm)

    research/                     # Phase 2 output
      00-synthesis.md             # Cross-cutting patterns from all study materials
      01-<topic>.md               # Research note per study-material cluster
      ...

    evaluation/
      rubric.yaml                 # Scored dimensions with weights and criteria
      evaluate.sh                 # METRIC-emitting evaluation script
      evaluate-checks.sh          # Optional correctness gate
      judges.yaml                 # Optional multi-judge configuration
      data-split.yaml             # Train/validation/test assignment

    experiments/
      DESIGN.md                   # Structural decisions locked before drafting
      craft-decisions.md          # Append-only iteration ledger (DNN format)
      autoresearch.md             # Session contract (goal, config, budget)
      autoresearch.jsonl          # Machine log with ASI fields
      results.tsv                 # Human-readable experiment journal
      autoresearch.ideas.md       # Deferred hypothesis backlog
      run.log                     # Last evaluation command output

    handoffs/                     # Context preservation
      state.yaml                  # Structured resume state
      HANDOFF-<label>.md          # Rich handoff documents

  output/                         # FACTORY: the finished skill, publish-ready
    <skill-name>/                 # the skill in its own named dir
      SKILL.md                    # The skill itself
      references/                 # Reference files (if needed)
      scripts/                    # Executable utilities (if needed)
      assets/                     # Static assets (if needed)
```

## The three zones

### input/ — what you provide

Drop gold standards and study materials here in whatever structure is natural. You are **not**
asked to hand-author an index. During Phase 1 the factory scans `input/`, classifies each item
as a gold standard (exemplar input/output pair or reference artifact) vs a study material, and
writes its derived index to `work/manifest.yaml` for you to confirm or correct.

- Gold standards define "what good looks like" — the immutable benchmark. Never modified by autoresearch.
- Study materials are anything that helps the factory understand the domain (docs, code, transcripts, specs, style guides, an existing skill being upgraded).

### work/ — what the factory generates

The lab notebook. None of it ships. Subdirectories:

- `manifest.yaml` — the factory's index of the gold standards found in `input/`, tagged train/validation/test.
- `research/` — Phase 2 notes from parallel subagent exploration. `00-synthesis.md` is the cross-cutting synthesis (read first); numbered notes correspond to study-material clusters.
- `evaluation/` — the scoring infrastructure: `rubric.yaml` (dimensions, weights, criteria), `evaluate.sh` (the script autoresearch calls), the optional `evaluate-checks.sh` correctness gate, `judges.yaml` (multi-judge config), and `data-split.yaml` (which gold standards are training vs held out).
- `experiments/` — all experimentation artifacts: `DESIGN.md` (structural decisions locked before the first draft), `craft-decisions.md` (per-iteration ledger), the autoresearch session files, and `run.log`.
- `handoffs/` — cross-session continuity (`state.yaml` for automatic resume, `HANDOFF-*.md` for rich human-readable context).

### output/ — what you get

The finished skill, in its own `<skill-name>/` directory so it is a real, copyable package.
This is the only zone that ships. To publish, copy `builds/<skill-name>/output/<skill-name>/`
straight into a skills repo's `skills/` directory (or install it with `npx skills`).

## What Ships vs What Stays

| Ships (installable)                       | Stays (process artifacts) |
|-------------------------------------------|---------------------------|
| `output/<name>/SKILL.md`                  | `input/`                  |
| `output/<name>/references/`               | `work/manifest.yaml`      |
| `output/<name>/scripts/`                  | `work/research/`          |
| `output/<name>/assets/`                   | `work/evaluation/`        |
|                                           | `work/experiments/`       |
|                                           | `work/handoffs/`          |

## Autoresearch Integration

Autoresearch runs from the **build workspace root** (`builds/<skill-name>/`). This means
`./work/evaluation/evaluate.sh` works as a relative path. Autoresearch session files land at
the workspace root during an active session and are archived to `work/experiments/` when the
session ends or on handoff.

| Autoresearch creates at root | Archived to |
|------------------------------|-------------|
| `autoresearch.md` | `work/experiments/autoresearch.md` |
| `autoresearch.jsonl` | `work/experiments/autoresearch.jsonl` |
| `results.tsv` | `work/experiments/results.tsv` |
| `run.log` | `work/experiments/run.log` |
| `autoresearch.ideas.md` | `work/experiments/autoresearch.ideas.md` |

The factory creates `autoresearch.checks.sh` at the workspace root as a wrapper that calls
`work/evaluation/evaluate-checks.sh`.

`BENCHMARK.md` (final pass/fail scores for the shipped skill) is generated at the end of Phase 5
(Verify) and placed at `builds/<skill-name>/BENCHMARK.md`. It is a summary, not a process artifact.

## Git Tracking

`builds/` is gitignored in this harness, so none of the below is tracked here — these are the
recommendations for when you run the factory **inside your own project repo** and want to
preserve the build.

| File | Tracked? | Why |
|------|----------|-----|
| `input/**` | Yes | Immutable reference materials |
| `work/manifest.yaml` | Yes | Gold-standard index |
| `work/research/*.md` | Yes | Reproducible evidence |
| `work/evaluation/rubric.yaml` | Yes | Scoring definition |
| `work/evaluation/evaluate.sh` | Yes | Evaluation logic |
| `work/evaluation/judges.yaml` | Yes (if present) | Multi-judge config |
| `work/experiments/DESIGN.md` | Yes | Design contract |
| `work/experiments/craft-decisions.md` | Yes | Iteration history |
| `work/experiments/autoresearch.md` | No | Session-specific |
| `work/experiments/autoresearch.jsonl` | No | Session-specific |
| `work/experiments/results.tsv` | No | Session-specific |
| `work/experiments/run.log` | No | Transient output |
| `output/**` | Yes | The deliverable |
| `work/handoffs/*` | Yes | Cross-session continuity |
| `BENCHMARK.md` | Yes | Final verification record |
