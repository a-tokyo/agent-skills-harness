# Benchmark — Phase 4 termination

Does the v0.2.0 wording actually change what an agent *does*, or does it only read better?

**Scope of the claim:** this shows the new wording, read on its own, licenses stopping where the old
wording did not. It does **not** show the override beats the competing instruction at runtime — see
[Honest limits](#honest-limits).

The structural self-test cannot answer that: it greps for strings, and a string can be present while the
behaviour it describes never happens. This is a behavioural A/B against the control the change replaced.

Run 2026-08-06.

## Why this exists

An external adopter reported that a build "kept saying uplift is not hitting the exit criteria… do this
again, do this again" and escaped only by force-locking the baseline. Diagnosis: the vendored
autoresearch loop treats a plateau as advisory and continues while budget remains
(`autoresearch/SKILL.md:332` "Continue if budget remains"; `:202` "Do not stop to ask the user"), so a
`target_score` the task cannot reach spends the whole budget before yielding. v0.2.0 moved the
termination decision into the factory's own Phase 4.

## Method

Same model (Sonnet), same scenario, two arms differing only in the skill file:

| Arm | Skill under test |
|-----|------------------|
| control | `create-skill-autoresearch` **v0.1.0** — the shipped text before this change |
| v0.2.0 | the same skill **after** the Phase 4 termination rules |

Each arm ran in a **fresh context** with the skill file as its only instructions, told to consult no other
file or skill, and asked what happens next. Neither was told what outcome was wanted, and neither saw the
other. Decisions were read from each arm's stated answer and its cited lines.

Two scenarios:

1. **Plateau below an unreachable target.** 12 of 20 experiments used, best `overall_score` 0.79 against
   `target_score: 0.85`, last seven scores spanning 0.78-0.79 (≈0.1 on a 1-10 scale — inside the stated
   0.2-0.3 judge variance), no blocked dimension, harness working correctly.
2. **Resume with `baseline_lock: true`** in `state.yaml`, best 0.79, target 0.85, 8 experiments remaining.

## Results

| Scenario | control (v0.1.0) | v0.2.0 |
|----------|------------------|--------|
| 1 — plateau | **Continues the loop.** "12 of 20 is used — the cap isn't reached." Explicitly noted: *"this file does not itself define a 'stop early on plateau' rule"* | **Stops Phase 4.** Recognised the plateau as within judge variance, carried best-so-far into Phase 5, and refused to request re-runs |
| 1 — outcome for 0.79 | no verdict; keeps iterating | **SHIP WITH CAVEATS** (0.79 ≥ 0.85 − 0.10), pending the panel's own score |
| 2 — `baseline_lock` | *"The skill file does not define `baseline_lock` anywhere"* → resumes Phase 4 with remaining budget | Honours it, moves to Phase 5, reports SHIP WITH CAVEATS, logs the unreached target to the ideas backlog |

**The control reproduced the reported failure**, citing the absence of a stop rule as its reason — which
is the defect, stated by an agent that had never seen the bug report.

## Honest limits

The strongest one first, because it bounds what this result can be used to claim:

- **Neither arm was shown the text the fix has to beat.** Each arm received the factory file *alone*,
  told to consult no other skill. But the fix works by overriding a **different** vendored file —
  `autoresearch/SKILL.md:332` "Continue if budget remains" and `:202` "Do not stop to ask the user" —
  and in a real run both texts are in the same context, with autoresearch driving the loop. There is no
  mechanical precedence: `target_score` is never handed to autoresearch, so which instruction wins rests
  on which prose the agent weights.

  **So what this measured is that the new wording, read on its own, licenses stopping — not that it wins
  the conflict at runtime.** Those are different claims, and only the weaker one is evidenced here.
  Testing the stronger one needs both files in context, which is a real build.
- **n=1 per cell, one model (Sonnet).** Below the n=5 the benchmark standard asks for, and with no Haiku
  or Opus cells. Enough to show the wording changes the decision; not enough to quantify how reliably.
- **Scenario-based, not a real build.** Each arm was handed a described state rather than reaching it by
  running 12 experiments. It tests what the instructions license, not the whole pipeline.
- **Judged by reading the arm's stated decision**, not by executing a loop and observing termination. A
  deterministic version would need a real build and a credential.
- Scenario 1 is close to the SHIP-WITH-CAVEATS boundary by construction. A score below
  `target_score - 0.10` would exercise the ITERATE path, which neither arm was tested on.

## What would close the gap

A third arm with **both** files in context, which is the production condition — bare autoresearch text,
autoresearch + factory v0.1.0, autoresearch + factory v0.2.0. That is the test that would show whether
the override actually wins, and it is the honest next step for this benchmark.

## Reproducing

Extract both arms and give each to a fresh agent with the scenarios above:

```bash
git show f1d86ad:.agents/skills/create-skill-autoresearch/SKILL.md > /tmp/skill-v0.1.0.md
cp .agents/skills/create-skill-autoresearch/SKILL.md /tmp/skill-v0.2.0.md
```

## What it changed

The v0.2.0 arm flagged that `baseline_lock` was honoured in §4.3 but absent from §4.4's field list.
Fixed in the same commit as this record — a gap the structural checks could not have found.
