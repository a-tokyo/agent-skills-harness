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
has task-2 with Haiku at 0.969 (0.953–0.980), tying v0.2.1. The cycle-3 run (`p-*`, harness `0c94f94`)
had it at 0.958 (0.908–0.989), and the release-candidate run (`r-*`, harness `8e505b0`) at 0.969
(0.926–0.989). The `s-*` run (harness `82ec859`) had it at 0.932 (0.858–0.980). The release run (`u-*`,
harness `f684797`, the shipped factory, loaded as a plugin so its kill guard and finish guard were active)
has it at 0.917 (0.872–0.968), below v0.2.1 but inside the 0.117 pooled spread. Its builds mostly lose the
approval tier (14 of 25 holdout scores miss it), and two lose one holdout almost entirely.

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
  `UNSHIPPED`. In the release-candidate run, 20 of 20 passed. In the `s-*` run, 19 of 20 passed: the
  one failure ran neither the gate nor the validator and labelled itself `UNSHIPPED`. In the release run,
  20 of 20 passed. The gate measures uplift rather than raising quality.
- **A check the agent must choose to run cannot stop it ending early; a step that ends in it can.** In
  both the cycle-2 and the cycle-3 run, three Haiku builds ended their turn after the premortem without
  writing a verdict, and none of the three ran `check_gate.py --finish`. Once 5.1 wrote the premortem to
  a file and ended by running the validator (`6a9f6f2`), no build stopped there: 0 of 10 in an interim
  Haiku run and 0 of 20 in each of the release-candidate, `s-*` and release runs. The finish guard (a
  `Stop` hook running `check_gate.py --finish`, `34c587e`) makes that end mechanical: in the release run
  it sent 6 builds back 14 times, never twice in a row, and all 6 ended with a verdict `--finish`
  accepts. The kill guard (a `PreToolUse` hook) is the other mechanical check: no pattern kill was
  executed in cycle 3 or any release run, though none was attempted either, so no run exercised the
  block.
- **A rule the validator enforces closes a gap that prose leaves open.** In the release-candidate run,
  eight verdicts covered a skill the panel had scored before a last fix. Once `check_gate.py --panel`
  recorded the scored skill's hash and `--finish` rejected a shipped verdict on any other (`f4c31cc`),
  `--finish` accepted all 14 shipped verdicts in the `s-*` run. That receipt was still written before
  the panel ran. Once each panel role wrote a receipt after scoring and `check_gate.py --consensus`
  derived the label from them (`9dcdeab`), no release-run verdict sat above its consensus: 13 SHIP WITH
  CAVEATS on a SHIP WITH CAVEATS consensus, 7 `UNSHIPPED` on ITERATE or ESCALATE.
- **The final matrix finds what the loop cannot.** The loop measured one cell (task-2, Haiku); the
  regression E5 targeted only showed up at n=5 there, against a v0.2.1 baseline.
- **Two builds per measurement is too few.** One bad build moved experiment 3's median past the noise
  threshold on its own; experiment 4 used four.

The before/after comparison against v0.2.1 and bare (n=5 per cell, both tasks, Sonnet 5.5 and Haiku
5.5; v0.3.0 is the `u-*` run on the shipped factory, harness `f684797`, whose installed copy in every
build matches the published skill byte for byte, so the published result matches the shipped factory),
with its fidelity counts, is published in
[Results — v0.3.0 release](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks/create-skill-autoresearch#results--v030-release-u--october-2026).
Median overall v0.3.0 / v0.2.1 / bare: task-2 Sonnet 1.000 / 0.975 / 0.975, task-2 Haiku 0.917 / 0.969 /
0.969, task Sonnet 0.946 / 0.946 / 0.971, task Haiku 0.871 / 0.871 / 0.896. Criterion 4 passes in every
cell. Its gain condition is met on task-2 Sonnet (+0.025 over v0.2.1 and bare, inside the 0.067 pooled
spread, so not a measured improvement). Both task cells tie v0.2.1 and sit 0.025 below bare; task-2
Haiku is 0.052 below both, inside the 0.117 and 0.108 spreads. Across the five v0.3.0 runs (`k-*`, `p-*`,
`r-*`, `s-*`, `u-*`) a cell's median spans 0.025–0.052, and the `s-*` to `u-*` moves (+0.020, −0.015,
−0.025, −0.050) are each smaller than the spread inside the `u-*` cell, so release-to-release movement is
run-to-run noise. Fidelity: 20 of 20 gates valid, 20 of 20 verdicts, three role receipts and a consensus
in every build, no verdict above its consensus, no kill command, no stale gate, no below-target build
labelled shipped. Median wall time is 1.6–5.0× v0.2.1's (15.1 against 9.3 minutes on task Sonnet, 27.9
against 17.6 on task Haiku, 40.0 against 8.2 on task-2 Sonnet, 61.4 against 12.2 on task-2 Haiku) and
input tokens 1.9–6.2× (task-2 Haiku 48.9M against 7.9M; reported, not gated). The earlier `s-*` (harness
`82ec859`), `r-*` (harness `8e505b0`), `p-*` (harness `0c94f94`) and `k-*` (harness `a3fa032`) runs stay
published below it as superseded.

Agent-agnostic check (Amendment 3): two task builds under `cursor-agent` (Sonnet 5.5, harness `f684797`,
isolated HOME, no `claude` on the build PATH) both scored 0.971, above the Claude Code Sonnet median.
Both gates validated in manual mode, with `composer-2.5` as the executor each build chose. One ended
SHIP WITH CAVEATS and one `UNSHIPPED` on an ESCALATE consensus, after 59 and 39 minutes. `cursor-agent -p`
runs no `stop` hook, so the finish guard was not active there. Two builds show that the pipeline runs and
labels honestly without Claude Code; they are not a quality result.
