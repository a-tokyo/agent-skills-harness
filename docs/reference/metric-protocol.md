# METRIC Protocol Reference

The METRIC protocol is a standardized line format for emitting measurable values from evaluation scripts. It enables deterministic, multi-metric parsing by the autoresearch loop.

## Line Format

```
METRIC <name>=<value>
```

Rules:
- One METRIC per line
- Must appear at the start of the line
- **Name**: `[\w.]+` (alphanumeric, underscores, dots)
- **Value**: finite number (integer or float)
- Lines not starting with `METRIC ` are ignored by the parser

## Examples

```
METRIC quality_score=8.33
METRIC structure=9.0
METRIC coverage=7.5
METRIC latency_ms=142
METRIC test_pass_rate=0.95
```

## Primary vs Secondary Metrics

The autoresearch session config specifies one **primary metric** that drives keep/discard decisions. All other METRIC lines are recorded as **secondary metrics** for tradeoff visibility.

Example session config:
```yaml
primary_metric: quality_score
direction: higher_is_better
```

With this config, only `quality_score` determines whether an experiment is kept. But if `latency_ms` regresses significantly, the ASI `learned` field should note the tradeoff.

## evaluate.sh Contract

The evaluation script bridges the skill output and the autoresearch loop.
Skills are markdown instructions for AI agents (not executables), so the script
invokes an LLM with the SKILL.md as a system prompt and the test case input as
the user message, then scores the output.

```bash
#!/bin/bash
# Contract:
# 1. Takes a test case path as argument: ./evaluate.sh <test-case>
# 2. Invokes the skill via LLM (SKILL.md as system prompt, test input as user msg)
# 3. Compares LLM output to the gold standard reference
# 4. Emits METRIC lines to stdout (per-dimension on raw scale, overall normalized 0-1)
# 5. Exits 0 on success, non-zero on failure

set -euo pipefail
TEST_CASE="$1"

# ... invoke skill via LLM, compare to reference, score via LLM judge ...

echo "METRIC correctness=8.5"
echo "METRIC completeness=7.0"
echo "METRIC clarity=9.0"
echo "METRIC overall_score=0.7825"
```

Note: per-dimension scores use the rubric's raw scale (e.g., 1-10). The `overall_score` is
normalized to 0.0-1.0 via `sum(dimension_score / scale_max * weight)`.

## evaluate-checks.sh Contract

Optional correctness gate that runs BEFORE metric measurement.

```bash
#!/bin/bash
# Contract:
# 1. Runs correctness checks (lint, type check, syntax validation)
# 2. Exits 0 if all checks pass
# 3. Exits non-zero if any check fails
# 4. On failure, the experiment is treated as a crash (reverted)

set -euo pipefail

# Example checks for a SKILL.md:
# - Line count < 500
# - Frontmatter is valid YAML
# - All file references resolve
```

## ASI (Actionable Side Information)

Every experiment in `autoresearch.jsonl` includes ASI fields -- structured metadata that survives git reverts. This is critical because reverted experiments lose their code changes, but their insights persist in the log.

### Required ASI Fields

| Field | Purpose | Example |
|-------|---------|---------|
| hypothesis | What we believed would improve | "Adding concrete examples to the curation section will improve clarity" |
| learned | Key insight from this experiment | "Examples help clarity but hurt conciseness -- need shorter examples" |
| rollback_reason | Why discarded (null if kept) | "Clarity improved 0.2 but overall_score dropped 0.1 due to length" |
| next_action_hint | What to try next | "Try bullet-point examples instead of prose blocks" |

### JSONL Entry Schema

```json
{
  "experiment": 5,
  "status": "discard",
  "hypothesis": "Adding concrete examples improves clarity",
  "primary_metric": 0.7450,
  "secondary_metrics": {
    "correctness": 8.5,
    "clarity": 8.2,
    "completeness": 6.5
  },
  "commit": null,
  "description": "Added 3 prose examples to curation section",
  "learned": "Examples help clarity but add length that hurts completeness",
  "rollback_reason": "Overall score dropped from 0.7825 to 0.7450",
  "next_action_hint": "Try bullet-point examples instead of prose",
  "timestamp": "2026-05-30T23:15:00Z"
}
```

Note: `primary_metric` is the normalized `overall_score` (0.0-1.0). `secondary_metrics`
use the raw rubric scale (e.g., 1-10) for per-dimension visibility.

## Parsing METRIC Lines

To extract metrics from command output:

```bash
# Extract all METRIC lines
grep '^METRIC ' run.log

# Extract a specific metric value
grep '^METRIC quality_score=' run.log | sed 's/METRIC quality_score=//'

# Regex pattern for parsing
# ^METRIC ([\w.]+)=([-+]?[0-9]*\.?[0-9]+)$
```

## Historical Context

The METRIC protocol originated in [pi-autoresearch](https://github.com/davebcn87/pi-autoresearch) and was proven through extensive automated experiments across multiple case studies, where it enabled reliable multi-dimensional scoring of LLM-generated outputs against human gold standards.
