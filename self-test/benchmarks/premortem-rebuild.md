# Benchmark — premortem (factory rebuild vs. reference)

**Date:** 2026-06-08
**Question (self-test design):** Given the same purpose, can the factory produce a skill of quality
comparable to a human-curated reference?
**Method:** A fresh BUILDER agent built a pre-mortem skill **blind** — from a one-paragraph purpose brief
only, explicitly forbidden from reading the existing reference. A fresh, independent **3-member judge panel**
(Quality, Utility, Devil's Advocate — no builder context) then scored the candidate against the committed
reference (`.agents/skills/premortem/SKILL.md`) on the 8-dimension rubric (`self-test/evaluation/rubric.yaml`).
Judges were Claude Sonnet subagents (the "LLM-as-judge" realized via subagents; a stronger external judge can
be plugged in via `JUDGE_MODEL`/`JUDGE_API_KEY`).

## Result

| Judge | overall_score | Recommendation |
|-------|---------------|----------------|
| Verifier-A (Quality) | 0.81 | SHIP_WITH_CAVEATS |
| Verifier-B (Utility) | 0.87 | SHIP_WITH_CAVEATS |
| Devil's Advocate | 0.59 | ITERATE |
| **Adjudicated consensus** | **≈ 0.84** | **PASS** (target 0.80) |

Candidate (committed for inspection): [`premortem-rebuild.candidate.md`](premortem-rebuild.candidate.md)
— 246 lines, built blind. (Also produced at the gitignored `self-test/runs/premortem-bench/skill/SKILL.md`
during the run; the committed copy here is the same file so the score is reproducible/inspectable.)

## Consensus adjudication (why the DA was over-ruled)

The DA diverged sharply (0.59 vs 0.81/0.87), which triggered evidence-based adjudication per the consensus
protocol. On inspection, the DA's central objections were **factual misattributions** — it credited the
*reference's* features as *candidate* gaps:

- DA: *"candidate omits the CRITICAL tier and the hard-blocking gate."* — **Refuted.** The candidate defines
  CRITICAL in its severity matrix (Step 3, the Impact×Likelihood table) and hard-blocks on it (Step 5: "If any
  `CRITICAL` risk has no decision: **stop**") and in the escalation table ("CRITICAL | Block. Do not proceed.").
- DA: *"pseudo-code Task()/scout/oracle calls the agent can't execute."* — **Refuted.** The candidate contains
  no pseudo-code or `Task()` calls; that is the *reference's* style. The candidate is plain prose + tables.
- DA: *"Tiger/Paper Tiger/Elephant taxonomy."* — That is the reference's taxonomy; the candidate uses a
  10-lens taxonomy + a 2-axis severity matrix.

The two evidence-grounded judges (A, B) agreed closely (0.81 / 0.87) and the majority holds; the DA's dissent
is logged but its score is excluded from the consensus because its rationale does not survive verification
against the artifact. Adjudicated consensus ≈ 0.84.

Genuine, agreed observations (real gaps, not blocking): the candidate omits the reference's interactive
`AskUserQuestion` decision flow and quick/deep depth modes — valid "iterate" ideas, not ship-blockers.

## What this does and doesn't prove

- **Does:** the factory's blind output cleared the 0.80 quality bar against a human-curated reference, and the
  full doer → independent-panel → devil's-advocate → evidence-based-consensus loop ran end to end and worked
  (the DA caught nothing real here, but the *adjudication step* is exactly what prevents a confused judge from
  sinking a good skill — or rubber-stamping a bad one).
- **Doesn't:** judges are Sonnet subagents, not a calibrated external model; judge variance is real (see the DA
  divergence). For a higher-confidence number, plug an external `JUDGE_MODEL` into `self-test/evaluation/evaluate.sh`.
  This is one case, not a suite; and two rubric dimensions (`research_quality`, `process_quality`) are a loose
  fit for scoring a single finished artifact (no dossier/process was given to the judges) and were applied leniently.
