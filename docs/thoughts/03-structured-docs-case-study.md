# Case Study: Structured-Document Generator (structured-document generation)

The most automated and script-driven case study. An engineer (guided by Tokyo) built a Gemini Gem prompt through 69 automated experiments using Python scripts and LLM-as-judge evaluation against 13 weeks of historical human-written aggregations.

## What Was Built

A Gemini Gem system instruction (`gem_prompt.txt`) that takes raw weekly structured-document (Progress, Priorities, Problems) updates from multiple teams and produces curated executive summaries matching human quality.

## Gold Standard Approach

- **Source**: 13 weeks of historical structured-documents from a games studio's leadership team
- **Format**: input/output `.docx` files extracted to `.txt`, then structured as `data/pairs.json`
- **Split**: 5 test dates held out for evaluation, remaining used for pattern understanding
- **Explicit skips**: dates with anomalies documented (2.17 empty output, 5.12 output longer than input)

## The Evaluation Pipeline

Two Python scripts form the automated evaluation:

### generate.py
- Takes `gem_prompt.txt` as system instruction
- Runs each test input through Gemini 3.1 Pro (temp=0.0 for deterministic evaluation)
- Saves generated outputs to `generated_outputs.json`
- Outputs `METRIC` lines and `GENERATION_COMPLETE` signal

### evaluate.py
- Loads generated outputs and human references
- Uses LLM-as-judge (Gemini 2.5 Flash) to score on 6 dimensions (1-10 each)
- Outputs `METRIC quality_score=N.NN` lines for autoresearch consumption
- Saves detailed results to `eval_results.json`

### autoresearch.sh
- Shell wrapper: syntax check → generate → signal for judging
- Outputs `METRIC` lines compatible with autoresearch/pi-autoresearch

## The 6-Dimension Rubric

1. **STRUCTURE** (1-10): section headers, functional area organization
2. **CURATION** (1-10): editorial judgment on include/exclude decisions
3. **CONTENT_ACCURACY** (1-10): facts, dates, names preserved without hallucination
4. **CONCISENESS** (1-10): tight, scannable writing
5. **PROBLEMS_QUALITY** (1-10): risks and blockers preserved and clear
6. **OVERALL_MATCH** (1-10): would this serve equally well as the human reference

## The Experiment Log (69 experiments)

Key findings from `autoresearch.md`:

### What worked:
- **Adaptive curation** (7.72 → 9.00): removed fixed length target, quality-focused judge
- **Include vs compress principle** (9.00 → 9.04): separated item selection from compression
- **4-tier priority hierarchy** (7.87 → 8.10): replaced binary keep/cut with nuanced tiers
- **OPS full-length preservation** (8.10 → 8.33): preserve real estate/facilities items
- **Bullet formatting fix**: structure 8.4 → 9.0

### What didn't work (dead ends):
- Model upgrades (Flash = Pro on this task)
- Temperature tuning (0.3 optimal, 0.1 too rigid, 0.4 no help)
- Prompt reordering
- Additional/modified examples
- Section-specific rules
- Executive personas (trigger over-curation)
- Consolidation rules

### Key insight:
> "Judge variance is ~0.2-0.3 points. Real improvements need to be >0.3 to be meaningful."

## Multi-Judge Validation

Three different judge setups were tested:
1. Gemini 2.5 Flash judge (low variance: 0.1)
2. Gemini 3.1 Pro judge (high variance: 0.57)
3. Claude judge (strictest: 7.87 baseline vs 8.77 with Gemini)

This validates the principle: different judges catch different issues. Multiple judges improve confidence.

## Key Patterns for the Factory

1. **Script-driven autoresearch**: generate.py + evaluate.py + autoresearch.sh as a standard triple
2. **METRIC output protocol**: `METRIC name=value` lines for autoresearch consumption
3. **Test/train split**: not all gold standards are scored -- some are for pattern understanding
4. **Multi-judge validation**: different LLM judges catch different issues
5. **Dead-end documentation**: knowing what DOESN'T work is as valuable as what does
6. **Plateau detection**: "further gains likely require fundamentally different methodology"
7. **Variance awareness**: judge variance sets a floor on meaningful improvement detection
