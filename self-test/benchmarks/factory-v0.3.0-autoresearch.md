# Factory v0.3.0 — autoresearch on the factory itself

The v0.3.0 refactor (skill-creator composed instead of distilled, `claude plugin eval` as Phases 3.6
and 5.0, upstream autoresearch driven with factory-owned conventions) was tuned with the same loop
the factory runs on the skills it builds.

## Setup

- **Metric:** two factory builds per experiment (Haiku 5.5 builder, benchmark task-2 from
  [a-tokyo/agent-skills](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks/create-skill-autoresearch)),
  each scored by executing the produced skill against held-out answer keys.
  `composite = completion_rate × median_overall − 0.05 × median_wall_hours`. Output quality alone was
  saturated (a bare model already scores 0.94–1.00 on the task), so completion and wall time carry
  the signal.
- **Checks:** the structural gate (`npm test`) green before every measurement.
- **Keep rule:** beat the best composite by more than 0.02, or tie within 0.02 while fixing a
  process deviation the builds reported.

## Experiments

| # | Change | Composite | Verdict |
|---|--------|-----------|---------|
| 0 | v0.3.0 as first written | 0.938 | baseline (builds 38/46 min) |
| 1 | A worked plugin-eval case with a working `scaffold_script` | 0.973 | keep |
| 2 | A dedicated working directory is the build workspace | 0.931 (from baseline) | keep: tie, fixes the layout deviation both builds reported |
| 1+2 | Combined | 0.958 | keep: tie; builds 7/13 min |
| 3 | Sample ≤ 3 cases per agentic eval; gate `-j 4`; "never skip the gate" | 0.904 | discard |
| 4 | Phase 5 starts only once `plugin-eval.json` exists; gate `-j 4` | 0.925 | discard |
| 5 | Gold standards win conflicts with study materials (a conflicts table in 2.2) | full n=5 matrix | keep |

Shipped: experiments 1, 2 and 5, plus `-j 4` on the gate command.

Experiment 5 came from the release matrix, not the loop. The first release candidate regressed on
task-2 with Haiku (median 0.932 vs v0.2.1's 0.969): two of five builds trusted the task's stale written
policy over the gold standards, and one hard-coded its outdated approval thresholds. Neither version
had a rule for that conflict. With the rule, the next candidate run reached 0.969. The final release
run, which also carries the tribunal round-1 and round-2 fixes, has task-2 with Haiku at 0.955:
inside the pooled run-to-run spread, but below v0.2.1's worst build (0.958).

## What the loop taught

- **The builds told us what to fix.** Experiments 1 and 2 came straight from deviations the
  baseline builds wrote into their own reports: the eval scaffold could not copy fixtures, and the
  `builds/` layout did not fit a working directory that already was the build root.
- **Wording does not make an agent run an expensive step; a check with a fallback does.** "Never
  skip the gate" changed nothing. A checkable completion criterion (experiment 4) got the gate to run
  in half the builds, which took 79 minutes and over two hours for an unchanged output score. The
  release makes gate availability a check and requires an uplift artifact either way (plugin eval or
  the manual with/without protocol); in the final release run 14 of 20 builds wrote one, so even a
  checked requirement is not followed every time unattended. The gate measures uplift rather than
  raising quality.
- **The final matrix finds what the loop cannot.** The loop measured one cell (task-2, Haiku); the
  regression E5 targeted only showed up at n=5 there, against a v0.2.1 baseline.
- **Two builds per measurement is too few.** One bad build moved experiment 3's median past the noise
  threshold on its own; experiment 4 used four.

The before/after comparison against v0.2.1 (n=5 per cell, both tasks, Sonnet 5.5 and Haiku 5.5;
v0.3.0 is the final `i-*` run at harness `8f6a323`) is published in
[Results — October 2026](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks/create-skill-autoresearch#results--october-2026-v021-vs-v030).
