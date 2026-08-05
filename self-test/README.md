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

**Start here — this one runs on a fresh clone, offline, with no credentials:**

```bash
bash evaluation/autoresearch-evaluate.sh   # structural checks on the factory itself
```

It needs only `bash` and `python3`, and prints `METRIC checks_passed` / `METRIC checks_total` plus an
issues list. That is the regression gate for any change to the factory.

**Scoring a produced skill against a reference** is the other script, and it needs a case you can
actually run. The cases in `gold-standards/manifest.yaml` all carry `input_materials: null` — their
source materials were private to the factory's original development and are not in this repo — so
**pick your own case rather than one from the manifest**:

1. Add a case to `gold-standards/manifest.yaml` with a real `input_materials` path and a
   `reference_skill` to score against. (`tokyo-production-grade` is the one whose `reference_skill`
   resolves here — `.agents/skills/production-grade/SKILL.md` — but its inputs are still absent, so it
   is a scoring target, not a runnable build.)
2. Run the factory on that case's input materials.
3. The factory produces output in `runs/<case-id>/skill/`.
4. Run `./evaluation/evaluate.sh <case-id>` to compare against the reference. Set
   `JUDGE_MODEL`/`JUDGE_API_KEY`/`JUDGE_API_BASE` for judge scoring; without them you get structural
   checks only, and that score is not comparable to the 0.80 judge-scored target.

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
  cross-reference integrity, convention compliance. One check is expected to fail: an *advisory*
  "keep >25 lines of headroom below the 500-line limit" depth heuristic. The factory body is within the
  hard limit, so this is a soft signal, not a defect — run the script for the current
  `checks_passed`/`checks_total` rather than trusting a number quoted here.
- **Skill-vs-reference scoring** (`evaluate.sh`): the 8-dimension rubric via LLM-as-judge when
  `JUDGE_MODEL`/`JUDGE_API_KEY` are set; deterministic structural metrics only otherwise.
- **Subagent-panel benchmark** (committed evidence): a fresh builder rebuilds a reference skill *blind*, and an
  independent 3-member panel (Quality / Utility / Devil's Advocate) scores it with evidence-based consensus.
  See [`benchmarks/premortem-rebuild.md`](benchmarks/premortem-rebuild.md) (adjudicated ≈ 0.84 vs the 0.80 target).

The factory itself was originally developed against several real, now-private case studies (kept out of this
public repo); the cases below with `input_materials: null` are documented references, not runnable here.
