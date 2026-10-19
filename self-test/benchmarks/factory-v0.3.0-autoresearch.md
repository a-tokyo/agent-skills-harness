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
had a rule for that conflict. With the rule, the next candidate run reached 0.969. The cycle-2 run
(`k-*`), which also carries the tribunal fixes, the cycle-2 scripts and the owned, hash-bound gate,
has task-2 with Haiku at 0.969 (0.953–0.980), tying v0.2.1. The published cycle-3 run (`p-*`, harness
`0c94f94`, factory loaded as a plugin so its kill guard was active) has it at 0.958 (0.908–0.989):
−0.011 against v0.2.1, inside the 0.081 pooled spread.

## What the loop taught

- **The builds told us what to fix.** Experiments 1 and 2 came straight from deviations the
  baseline builds wrote into their own reports: the eval scaffold could not copy fixtures, and the
  `builds/` layout did not fit a working directory that already was the build root.
- **Wording does not make an agent run an expensive step; a check with a fallback does.** "Never
  skip the gate" changed nothing. A checkable completion criterion (experiment 4) got the gate to run
  in half the builds, which took 79 minutes and over two hours for an unchanged output score. The
  release requires an uplift artifact either way (plugin eval or the manual with/without protocol).
  Written as prose, 13 of 20 builds wrote it at its canonical path. Run as bundled scripts (`gate.py`
  as an owned job, then the `check_gate.py` validator against a hash-bound gate record), 20 of 20 did
  and 19 passed the validator, one of them with no gold-standard case counted. With the case list
  written by `gate.py record` after a zero-cost load check (cycle 3), 19 of 20 passed again and none
  failed "artifact cases differ"; the one failure skipped the gate entirely and labelled itself
  `UNSHIPPED`. The gate measures uplift rather than raising quality.
- **A check the agent must choose to run cannot stop it ending early.** In both the cycle-2 and the
  cycle-3 run, three Haiku builds ended their turn after the premortem without writing a verdict.
  `check_gate.py --finish` reports that state, but none of the three ran it. The mechanical kill
  guard (a `PreToolUse` hook) is the other kind: zero pattern kills were executed in cycle 3, though
  none was attempted either, so the run never exercised the block.
- **The final matrix finds what the loop cannot.** The loop measured one cell (task-2, Haiku); the
  regression E5 targeted only showed up at n=5 there, against a v0.2.1 baseline.
- **Two builds per measurement is too few.** One bad build moved experiment 3's median past the noise
  threshold on its own; experiment 4 used four.

The before/after comparison against v0.2.1 and bare (n=5 per cell, both tasks, Sonnet 5.5 and Haiku
5.5; v0.3.0 is the `p-*` run at harness `0c94f94`), with its fidelity counts, is published in
[Results — cycle 3 final run](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks/create-skill-autoresearch#results--cycle-3-final-run-p--october-2026).
Median overall v0.3.0 / v0.2.1 / bare: task-2 Sonnet 0.957 / 0.975 / 0.975, task-2 Haiku 0.958 / 0.969 /
0.969, task Sonnet 0.946 / 0.946 / 0.971, task Haiku 0.886 / 0.871 / 0.896. Criterion 4 passes in every
cell; its gain condition is met only by task Haiku's +0.015, inside a 0.125 pooled spread. v0.3.0 takes
3.3–4.7× v0.2.1's wall time on task-2 and more input tokens in every cell (reported, not gated). The
cycle-2 `k-*` run (harness `a3fa032`) stays published below it as superseded.
