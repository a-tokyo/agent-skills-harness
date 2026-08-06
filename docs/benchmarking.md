# Benchmarking

How to tell whether a skill earns its place, and how to read the numbers this project publishes.

The standard itself lives with the factory, in
[`benchmark-standard.md`](../.agents/skills/create-skill-autoresearch/references/benchmark-standard.md) —
that file travels with the skill when someone installs it, so it is the single source. This page is
the harness-side summary: the shape of the standard, how to run one here, and the two caveats that
decide whether a number means anything.

## The standard in one paragraph

Measure **same-model uplift**: run the *same* model twice on identical tasks — once with the skill as
its system prompt, once bare — and report the delta. A skill's value is what it *changes*, not how the
model scores in absolute terms. Score by **executing** the output against a deterministic answer key
rather than by reading it, and unit-test the scorer itself so a green run means the probes work. Report
medians over n=5 per cell, per model, and **always disclose the actual n**. Publish the cells where the
skill does not separate.

## Two caveats that decide whether a number means anything

**1. Absolute quality is not uplift.** The autoresearch loop optimizes `overall_score` — absolute
output quality against your gold standards. That is a different question from "does this skill help",
and reading one off the other is the most common way to conclude a good skill is useless. See
[reference/tuning.md](reference/tuning.md#two-questions-two-instruments).

**2. Retry parity.** In real use, a skill runs inside a loop that retries: a verifier panel catches a
first attempt that got it wrong and sends it back, and a large share of the practical benefit comes
from that. A benchmark arm is usually a single pass — no panel, no retry. **A single-pass arm and a
panel-retry arm are measuring different systems**, so a single-pass benchmark systematically
understates a skill whose value shows up under retry.

**A published arm is single-pass unless its benchmark README states otherwise**, and nothing is
re-scored to look better. The fix is a third arm — bare / skill / skill+panel — so the skill's
contribution and the panel's are separated rather than confused; read a single-pass figure as a floor.

## What this project has measured

| Benchmark | Shape | Honest reading |
|-----------|-------|----------------|
| [factory end-to-end](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks/create-skill-autoresearch) | one model builds the same skill three ways — bare, official `skill-creator`, full factory pipeline — and the produced skill is executed against a fixed answer key | **No overall uplift on that task**: Sonnet 0.896 in all three arms, best single cell bare Haiku 0.928. Factory beat `skill-creator` on Haiku (0.896 vs 0.846) and was the only arm producing verifiable pipeline artifacts. n=2 (n=1 factory-Haiku), no Opus cells, single-pass. |
| [`self-test/benchmarks/premortem-rebuild.md`](../self-test/benchmarks/premortem-rebuild.md) | the factory rebuilds a reference skill blind; an independent 3-member panel scores it with evidence-based consensus | ≈ 0.84 against a 0.80 target. A panel-scored structural example, not an uplift measurement — it has no bare arm. |
| [per-skill benchmarks](https://github.com/a-tokyo/agent-skills/tree/main/benchmarks) | same-model uplift, with the skill vs bare, per published skill | Each carries its own method, per-model results and negatives. `tailwind-v3-to-v4-migration` has none yet. |

A task where both arms already score highly is a **floor, not a differentiator** — it tells you the
task was too easy to discriminate, not that the skill is inert. Reach for a harder fixture instead of a
kinder metric.

## Running one here

The harness ships the regression gate, not an uplift benchmark:

```bash
npm test        # deterministic structural checks on the factory itself; no credentials, no network
```

An uplift benchmark needs an agent credential, because the arms *run an agent* rather than judging text
— `CLAUDE_CODE_OAUTH_TOKEN` (from `claude setup-token`) or `ANTHROPIC_API_KEY`. See
[reference/tuning.md](reference/tuning.md#models-and-credentials) for which credential does which job.

Build the benchmark outside the skill directory — `benchmarks/<skill>/`, never inside `skills/<skill>/`
— so it does not ship when someone installs the skill. Have the skill arm read the *shipped* skill file
so the benchmark always tests what users actually get.

## Once a fixture is burned, it is burned

After every arm has seen an answer key, that fixture can no longer measure the next round of
improvement — you are scoring against something the skill was tuned on. Author a new fixture, blind to
the skill text, before the next improvement round. All three of `tribunal`'s fixtures are burned in
exactly this way, which is why its next round needs a fresh one.
