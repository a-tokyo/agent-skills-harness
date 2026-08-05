# Tuning a Run

Where to change the exit criteria, which files are yours to edit, and what to do when the
autoresearch loop will not stop. Read this the first time a run keeps asking to iterate.

## Contents

- [What you may edit](#what-you-may-edit)
- [The exit criteria](#the-exit-criteria)
- [When the loop will not stop](#when-the-loop-will-not-stop)
- [Locking a baseline](#locking-a-baseline)
- [Two questions, two instruments](#two-questions-two-instruments)
- [Why measured uplift understates real-world effect](#why-measured-uplift-understates-real-world-effect)
- [Models and credentials](#models-and-credentials)

## What you may edit

A build has three zones: `input/` is yours, `work/` is generated, `output/` is the deliverable
(see [workspace-layout.md](workspace-layout.md)). "Generated" does not mean untouchable — **four
files in `work/` are yours to correct at phase boundaries.** Everything else there is derived from
them and gets rewritten, so hand-edits are lost.

| File | What you set | Edit when |
|------|--------------|-----------|
| `work/evaluation/rubric.yaml` | `target_score`, `max_iterations`, `plateau_window`, dimensions, weights, criteria | **The exit criteria live here.** Any phase boundary |
| `work/manifest.yaml` | gold-standard vs study-material classification, `train`/`validation`/`test` tags | Phase 1, when the factory presents its derived index |
| `work/evaluation/judges.yaml` | judge models and their weights — **never a credential** | Before Phase 4 |
| `work/evaluation/data-split.yaml` | which cases are held out | Before Phase 4 |

Everything else under `work/` — `research/`, `experiments/`, `handoffs/`, `evaluate.sh` — is the
factory's. Change the rubric and let it regenerate rather than editing generated artifacts directly.

## The exit criteria

Three fields in `work/evaluation/rubric.yaml` decide when Phase 4 stops:

```yaml
target_score: 0.85      # normalized 0.0-1.0 — the score the loop is trying to reach
max_iterations: 20      # hard experiment budget
plateau_window: 5       # consecutive non-improving experiments before a plateau is called
```

`target_score` is **absolute**: it scores the skill's output against your gold standards, computed as
`sum(dimension_score / scale_max * weight)` — see [rubric-format.md](rubric-format.md). It is not a
measure of how much the skill helps.

A run does not have to reach `target_score` to be shippable. Phase 5 grades the result:

| Final score | Verdict |
|-------------|---------|
| `>= target_score`, no dimension blocked | SHIP |
| `>= target_score - 0.10` | SHIP WITH CAVEATS — log the concerns and proceed |
| `< target_score - 0.10` | ITERATE — panel feedback feeds back into Phase 4 |
| any dimension `< 3/10` by majority | BLOCK — fix that first |

So a build sitting at 0.78 against a 0.85 target is a **SHIP WITH CAVEATS**, not a failure.

## When the loop will not stop

**Symptom:** the run reports that it is not hitting the exit criteria and asks to iterate again, over
and over, without the score moving.

**Cause:** `target_score` is set higher than the task can reach, and plateau detection is *advisory* —
the loop reports a plateau and then keeps going while budget remains. It stops on `target_score`
reached, `max_iterations` exhausted, or you interrupting it. A target the task cannot reach therefore
spends the whole budget before yielding.

Three ways out, best first:

1. **Set `target_score` to the achievable band.** Run a couple of experiments, see where the score
   settles, and set the target just above it. Scores of 0.80-0.90 are the normal ceiling; 1.0 is not a
   realistic goal for a judged rubric.
2. **Check whether you are chasing noise.** Typical judge variance is 0.2-0.3 points on a 1-10 scale
   ([rubric-format.md](rubric-format.md#judge-variance)). An improvement smaller than that is not
   measurable, so the loop cannot converge on it. If the plateau sits inside judge variance, the skill
   is at the measurement ceiling and further iteration buys nothing.
3. **Lower `max_iterations`** so the loop yields to Phase 5 sooner, and let the verdict table above
   decide honestly.

If the score is close and you simply want to move on, lock the baseline.

## Locking a baseline

Freezing a known-good score lets you proceed with the rest of a migration and revisit the score later.
There is no dedicated setting yet, so do it explicitly:

1. Note the best `overall_score` and its commit from `work/experiments/results.tsv`.
2. Record both in `work/handoffs/state.yaml` as `best_score` / `best_commit`.
3. Set `target_score` at or just below that score, so the criteria are satisfied and Phase 4 exits.
4. Add the real target to `work/experiments/autoresearch.ideas.md` so the gap is not forgotten.

Then continue to Phase 5 and ship with caveats. A first-class `baseline_lock` setting is planned.

## Two questions, two instruments

These get conflated, and conflating them is what makes a good skill look ineffective:

| Question | Instrument | Where |
|----------|-----------|-------|
| *Is the output good?* | the rubric's `overall_score` — **absolute** quality against gold standards | the Phase 4 loop |
| *Does the skill help?* | **uplift** — the same model with the skill vs bare, on identical tasks | a benchmark, outside the loop |

The loop optimizes the first. It never measures the second. So a **small gap between a bare run and a
with-skill run tells you nothing about the loop working correctly** — you are reading an effectiveness
question off a quality metric. To answer "does this skill help", run a benchmark with a bare arm and a
with-skill arm on identical tasks and compare the delta.

Worked examples: the committed panel benchmark in
[`self-test/benchmarks/premortem-rebuild.md`](../../self-test/benchmarks/premortem-rebuild.md), and the
published per-skill uplift benchmarks in
[a-tokyo/agent-skills/benchmarks](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks) — each
with method, per-model results, and honest negatives.

## Why measured uplift understates real-world effect

When you do measure uplift, expect the benchmark to read lower than what you see in practice, for a
structural reason:

- **In real use**, a skill runs inside a loop that retries — a verifier panel catches a first attempt
  that got it wrong and sends it back. Much of the practical benefit comes from that retry.
- **In a benchmark**, the skill arm is a single pass. No panel, no retry.

The two arms are measuring different systems, so a single-pass benchmark systematically understates a
skill whose value shows up under retry. Every benchmark number published in this project today was
measured **single-pass** and is labelled as such; none has been re-scored to look better. Adding
retry-parity arms — bare / skill / skill+panel — is planned, and only then do the numbers change.

If your team's lived experience says a skill is effective and a single-pass benchmark says the uplift
is small, both can be true.

## Models and credentials

**Credentials belong in the environment, never in a config file.** `judges.yaml` holds model names and
weights only. Anything under `work/` may be committed when you run the factory inside your own project
repo, so a key written there is a key in your git history.

Two different paths need two different credentials, because one *judges text* and the other *runs an
agent*:

| Path | Needs | Used by |
|------|-------|---------|
| LLM-as-judge scoring | `JUDGE_MODEL`, `JUDGE_API_KEY`, `JUDGE_API_BASE` (OpenAI-compatible endpoint) | `self-test/evaluation/evaluate.sh`, and the `evaluate.sh` the factory generates |
| Running an agent in a benchmark arm | `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) or `ANTHROPIC_API_KEY` | benchmark arms that drive a real agent |

Without judge credentials, scoring falls back to deterministic structural checks only — and that
fallback `overall_score` is **not** comparable to a judge-scored target.

For judging, prefer a **different model family** from the one that wrote the skill; the factory will
tell you when the builder and judge are too close, and correlated blind spots inflate scores.
