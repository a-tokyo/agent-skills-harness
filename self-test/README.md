# Factory Self-Test

Dogfooding workspace for validating the `create-skill-autoresearch` factory by running it against the case studies that inspired its design.

## How It Works

The self-test asks: **can the factory reproduce comparable quality given the same inputs?** Each case below was a skill built manually during the factory's development; their source materials are private and are **not** in this public repo.

## Gold Standards

See `gold-standards/manifest.yaml` for the full list. Each case study has:
- **Input materials**: The study materials the factory should research
- **Reference skill**: The manually-built skill (the gold standard)
- **Evaluation method**: How the original was evaluated
- **Final outcome**: What quality level was achieved

## Running a Self-Test

1. Pick a case study from the manifest (e.g., `tokyo-production-grade`)
2. Run the factory on that case study's input materials
3. The factory produces output in `runs/<case-id>/skill/`
4. Run `./evaluation/evaluate.sh <case-id>` to compare against the reference

## Evaluation

The rubric (`evaluation/rubric.yaml`) scores 8 dimensions:

| Dimension | Weight | What It Measures |
|-----------|--------|-----------------|
| correctness | 0.15 | Technical accuracy vs reference |
| completeness | 0.15 | Scope coverage vs reference |
| clarity | 0.10 | Agent-followability |
| consistency | 0.10 | Convention adherence |
| research_quality | 0.15 | Dossier depth vs case study notes |
| rubric_quality | 0.10 | Rubric precision and relevance |
| process_quality | 0.10 | Pipeline execution fidelity |
| outcome_match | 0.15 | Would this serve equally well? |

Target: 0.80 overall score.

## Data Split (historical)

This is the train/validation/test split from the factory's **original, private** development, recorded for
provenance. **None of these cases is runnable on a public clone** — their `input_materials` are not in this
repo (all `null` in `gold-standards/manifest.yaml`). The runnable public evidence is the subagent-panel
benchmark in [`benchmarks/`](benchmarks/).

| Case Study | Tag | Role (during private development) |
|------------|-----|-----------------------------------|
| documentation-workflow | training | used during autoresearch iterations |
| executive-summary | training | used during autoresearch iterations |
| scenario-generator | training | used during autoresearch iterations |
| task-decomposition | validation | periodic overfitting checks |
| tokyo-production-grade | test | held out until final verification |

## Two evaluation scripts (don't confuse them)

- `evaluation/evaluate.sh <case-id>` — score a factory-**produced** skill against a gold-standard reference.
- `evaluation/autoresearch-evaluate.sh` — deterministic structural regression checks on the **factory itself**.

## What is actually verified

- **Deterministic structural checks** (`autoresearch-evaluate.sh`): line count, YAML frontmatter,
  cross-reference integrity, convention compliance. (The factory currently scores 67/68; the one miss
  is an *advisory* "keep >25-line headroom" depth heuristic — the SKILL.md is 478/500 lines, well within
  the hard limit, so this is a soft signal, not a defect.)
- **Skill-vs-reference scoring** (`evaluate.sh`): the 8-dimension rubric via LLM-as-judge when
  `JUDGE_MODEL`/`JUDGE_API_KEY` are set; deterministic structural metrics only otherwise.
- **Subagent-panel benchmark** (committed evidence): a fresh builder rebuilds a reference skill *blind*, and an
  independent 3-member panel (Quality / Utility / Devil's Advocate) scores it with evidence-based consensus.
  See [`benchmarks/premortem-rebuild.md`](benchmarks/premortem-rebuild.md) (adjudicated ≈ 0.84 vs the 0.80 target).

The factory itself was originally developed against several real, now-private case studies (kept out of this
public repo); the cases below with `input_materials: null` are documented references, not runnable here.
