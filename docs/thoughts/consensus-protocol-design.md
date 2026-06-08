# Multi-Agent Consensus & Verification Protocol

> **NOTE**: This is the research/design document. The implemented protocol lives in
> `.agents/skills/create-skill-autoresearch/references/consensus-protocol.md`.
> Key differences: this doc uses a 1-5 scale and 7 fixed dimensions; the implementation
> uses the rubric's scale (typically 1-10) and dynamic dimensions from `rubric.yaml`.
> When in doubt, the reference file is authoritative.

## Research Summary

### Key Sources
- **DCI Framework** (arXiv:2603.11781) — Typed epistemic acts, phased deliberation, minority reports, guaranteed convergence
- **Πk,m,r Committee Protocol** — Propose/Critique/Compare with Copeland aggregation and external verifiers
- **AgentShield** (arXiv:2511.22924) — Byzantine fault tolerance via semantic voting (SVEC) + cross-attestation
- **OpenReview: "Only the Devil's Advocate Works"** — Explicit behavioral assignment achieves 99.2% disagreement vs 48.3% baseline; generic "think critically" is statistically indistinguishable from no intervention
- **Autorubric** (arXiv:2603.00077) — Per-criterion atomic evaluation, ensemble judging, bias mitigations
- **Rulers** — Evidence-anchored scoring requiring verbatim quotes; Wasserstein calibration
- **DynaDebate** — Process-centric audit (reasoning steps, not just answers); trigger-based verification agent
- **Confidence-Modulated Debate** (arXiv:2601.19921) — Calibrated confidence signals improve belief propagation
- **Oracle Poisoning** (arXiv:2605.09822) — Named/specific devil's advocacy is effective; blind/generic skepticism has catch rate = false positive rate

### Critical Design Insights

1. **Explicit role assignment >> implicit instructions** — "You must oppose" works; "think critically" doesn't
2. **Per-criterion atomic evaluation prevents halo effects** — Score each dimension independently in separate calls
3. **Evidence-anchoring prevents hallucinated justifications** — Require verbatim quotes from the artifact
4. **Anonymization reduces source bias** — Strip authorship metadata before judging
5. **Confidence signals improve aggregation** — Let verifiers express calibrated certainty per dimension
6. **Process-centric audit > answer-focused debate** — Audit reasoning steps, not just final outputs
7. **Named/specific adversarial hypothesis >> generic skepticism** — The devil's advocate must target specific failure modes
8. **Minority reports preserve institutional knowledge** — Dissent logged = lessons for future iterations

---

## Protocol Architecture: PANEL (Panel Assessment with Negotiated Evaluation & Logging)

### Overview

```
┌─────────────────────────────────────────────────────────┐
│  ORCHESTRATOR (parent agent)                            │
│  ┌─────────────┐ ┌─────────────┐ ┌──────────────────┐ │
│  │  VERIFIER-A  │ │  VERIFIER-B  │ │  DEVILS ADVOCATE │ │
│  │  (Quality)   │ │  (Utility)   │ │  (Adversarial)   │ │
│  └──────┬───────┘ └──────┬───────┘ └────────┬─────────┘ │
│         │                │                   │           │
│         ▼                ▼                   ▼           │
│  ┌─────────────────────────────────────────────────────┐│
│  │           INDEPENDENT SCORING (Phase 1)             ││
│  │           No cross-talk. Atomic per-criterion.      ││
│  └─────────────────────────────────────────────────────┘│
│                          │                               │
│                    [Agreement?]                           │
│                     /         \                           │
│                  YES           NO                         │
│                   │             │                         │
│                   ▼             ▼                         │
│            ┌──────────┐  ┌───────────────────────┐      │
│            │  ACCEPT  │  │  SYNTHESIS ROUND       │      │
│            │  (done)  │  │  (Phase 2: rationale   │      │
│            └──────────┘  │   exchange + re-score) │      │
│                          └───────────┬───────────┘      │
│                                      │                   │
│                               [Converged?]               │
│                                /         \               │
│                             YES           NO             │
│                              │             │             │
│                              ▼             ▼             │
│                       ┌──────────┐  ┌──────────────┐    │
│                       │ MAJORITY │  │  ESCALATE    │    │
│                       │ (logged) │  │  TO USER     │    │
│                       └──────────┘  └──────────────┘    │
└─────────────────────────────────────────────────────────┘
```

---

## Phase 1: Independent Scoring

### Panel Composition (3 members)

| Role | Archetype | Focus | Bias Direction |
|------|-----------|-------|----------------|
| **Verifier-A** | Quality Assessor | Structural correctness, completeness, clarity, adherence to spec | Neutral-positive |
| **Verifier-B** | Utility Assessor | Real-world usability, edge cases, integration quality, developer experience | Neutral-positive |
| **Devil's Advocate** | Adversarial Challenger | Failure modes, hidden assumptions, over-engineering, missing constraints | Explicitly negative |

### Scoring Rubric (7 dimensions, 1-5 scale)

Each dimension scored independently in a separate evaluation pass to prevent halo effects (per Autorubric research).

| # | Dimension | Weight | Description |
|---|-----------|--------|-------------|
| 1 | **Correctness** | 0.20 | Does the skill do what it claims? Are instructions accurate? |
| 2 | **Completeness** | 0.15 | Are all necessary sections present? Edge cases covered? |
| 3 | **Clarity** | 0.15 | Can a naive agent follow the instructions without ambiguity? |
| 4 | **Robustness** | 0.15 | Will it fail gracefully? Are failure modes documented? |
| 5 | **Utility** | 0.15 | Does it solve a real problem? Is it worth the complexity? |
| 6 | **Consistency** | 0.10 | Does it align with existing codebase conventions and patterns? |
| 7 | **Maintainability** | 0.10 | Can it be updated without full rewrites? Are dependencies stable? |

### Score Scale

| Score | Label | Meaning |
|-------|-------|---------|
| 5 | Excellent | Production-ready, no improvements needed |
| 4 | Good | Minor issues, shippable with noted caveats |
| 3 | Acceptable | Functional but needs iteration |
| 2 | Below Standard | Significant gaps, requires rework |
| 1 | Failing | Fundamentally flawed, reject |

### Evidence Requirement (per Rulers framework)

Every score of 4+ must be supported by at least 1 verbatim quote from the artifact.  
Every score of 2- must cite the specific line/section where the failure occurs.

---

## Phase 2: Synthesis Round

### Trigger Conditions (any ONE triggers synthesis)

1. **Score spread** ≥ 2 points on any single dimension across panel members
2. **Pass/fail disagreement**: One member scores overall ≥ 3.5 while another scores < 3.0
3. **Devil's Advocate VETO**: DA scores any dimension at 1 (automatic synthesis trigger)
4. **Confidence divergence**: Any member marks confidence < 0.5 on a dimension where others mark > 0.8

### Synthesis Process

1. Each panel member writes a **rationale document** (max 500 words) explaining their scores on disputed dimensions only
2. Rationales are **anonymized** and shared with all panel members simultaneously
3. Each member may **revise scores** on disputed dimensions only (with written justification for any change)
4. If a member does NOT change their score, they must provide a **one-sentence rebuttal** to the strongest opposing argument

### Convergence Test (after synthesis)

- **Converged**: All dimensions within 1 point spread → take weighted average
- **Majority**: 2-of-3 agree (within 1 point) → majority score adopted, dissent logged
- **Deadlock**: All 3 scores remain > 1 point apart → escalate to user

---

## Phase 3: Resolution & Escalation

### Final Score Computation

```
final_score = Σ (dimension_weight × consensus_score_per_dimension)
```

Where `consensus_score_per_dimension` is:
- If converged: arithmetic mean of all 3 scores
- If majority: arithmetic mean of the 2 agreeing scores
- If deadlock: escalate (no automatic resolution)

### Pass/Fail Thresholds

| Threshold | Action |
|-----------|--------|
| ≥ 4.0 overall | **SHIP** — Production ready |
| 3.5–3.9 overall | **SHIP WITH CAVEATS** — Log concerns, proceed |
| 3.0–3.4 overall | **ITERATE** — Feed back to autoresearch loop |
| < 3.0 overall | **REJECT** — Major rework needed |
| Any dimension < 2.0 | **BLOCK** — Cannot ship regardless of overall score |

### Escalation to User (Devil's Advocate power)

The DA can escalate to the user when:
1. DA scores any dimension at 1 AND the other two score it at 4+ (extreme disagreement)
2. DA identifies a **safety/correctness** concern that the majority dismisses
3. After synthesis, DA provides a specific **failure scenario** that the others cannot rebut
4. The DA's written dissent includes the phrase "ESCALATE: [reason]" — this is a structured signal

---

## Prompt Templates

### System Prompt: Verifier-A (Quality Assessor)

```markdown
# Role: Quality Assessor

You are an independent quality verifier evaluating an AI agent skill artifact.
Your job is to assess STRUCTURAL QUALITY: correctness, completeness, clarity,
and adherence to specification.

## Your Evaluation Principles
- You evaluate the artifact AS-IS, not its potential
- Every claim must be grounded in evidence from the artifact
- Score each dimension INDEPENDENTLY — do not let a strong dimension
  inflate a weak one
- Express calibrated confidence (0.0–1.0) for each score
- You have NOT seen any other evaluator's scores

## Rubric Dimensions You Own (primary focus)
1. Correctness (are instructions accurate and executable?)
2. Completeness (are all required sections present?)
3. Clarity (can a naive agent follow without ambiguity?)

## Rubric Dimensions You Also Score (secondary)
4. Robustness
5. Utility
6. Consistency
7. Maintainability

## Output Format (JSON)
{
  "scores": {
    "correctness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "completeness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "clarity": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "robustness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "utility": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "consistency": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "maintainability": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" }
  },
  "overall_assessment": "<2-3 sentence summary>",
  "top_concern": "<single most important issue, if any>",
  "pass_recommendation": "<SHIP|SHIP_WITH_CAVEATS|ITERATE|REJECT>"
}

## Evaluation Context
- Artifact type: {{artifact_type}}
- Specification: {{spec_reference}}
- Codebase conventions: {{convention_reference}}
```

### System Prompt: Verifier-B (Utility Assessor)

```markdown
# Role: Utility Assessor

You are an independent utility verifier evaluating an AI agent skill artifact.
Your job is to assess PRACTICAL VALUE: real-world usability, edge case handling,
integration quality, and developer experience.

## Your Evaluation Principles
- You evaluate from the perspective of the END USER (an AI agent using this skill)
- "Would this actually work in production?" is your guiding question
- Consider edge cases, error handling, and graceful degradation
- Score each dimension INDEPENDENTLY
- Express calibrated confidence (0.0–1.0) for each score
- You have NOT seen any other evaluator's scores

## Rubric Dimensions You Own (primary focus)
4. Robustness (failure handling, edge cases, degradation)
5. Utility (solves a real problem, worth the complexity)
7. Maintainability (updatable, stable dependencies)

## Rubric Dimensions You Also Score (secondary)
1. Correctness
2. Completeness
3. Clarity
6. Consistency

## Additional Checks (Utility-specific)
- Does the skill handle the "unhappy path"?
- Are there implicit assumptions that will break in different contexts?
- Is the skill over-engineered for its stated purpose?
- Would a developer curse when trying to modify this 6 months later?

## Output Format (JSON)
{
  "scores": {
    "correctness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "completeness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "clarity": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "robustness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "utility": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "consistency": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" },
    "maintainability": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>" }
  },
  "overall_assessment": "<2-3 sentence summary>",
  "top_concern": "<single most important issue, if any>",
  "edge_cases_found": ["<list of edge cases not handled>"],
  "pass_recommendation": "<SHIP|SHIP_WITH_CAVEATS|ITERATE|REJECT>"
}

## Evaluation Context
- Artifact type: {{artifact_type}}
- Specification: {{spec_reference}}
- Target users: {{user_context}}
```

### System Prompt: Devil's Advocate (Adversarial Challenger)

```markdown
# Role: Devil's Advocate — Adversarial Quality Challenger

You are the Devil's Advocate on this evaluation panel. Your EXPLICIT MANDATE is
to find reasons this artifact should NOT ship. You are not being contrarian for
sport — you are the last line of defense against shipping broken, incomplete,
or subtly flawed work.

## Your Behavioral Contract
- You MUST oppose. Find the strongest case for rejection.
- Generic skepticism is WORTHLESS. You must identify SPECIFIC failure modes.
- For each concern, describe the EXACT SCENARIO in which this artifact fails.
- If you genuinely cannot find a flaw, say so — but this should be RARE.
- You score on the same rubric as others, but your scores should reflect
  the WORST REASONABLE interpretation of each dimension.

## Your Attack Vectors (use all that apply)
1. **Hidden Assumptions**: What must be true for this to work that isn't stated?
2. **Failure Scenarios**: Describe a concrete situation where this breaks.
3. **Over-engineering**: Is this more complex than necessary? Does complexity hide bugs?
4. **Missing Constraints**: What inputs/contexts would produce wrong behavior?
5. **Drift Risk**: Will this rot? What external dependencies could break it?
6. **Specification Gaps**: What does the spec require that this doesn't deliver?
7. **Integration Fragility**: How does this interact with other system components?

## Scoring Philosophy
- Your scores should be 0.5–1.5 points LOWER than a neutral evaluator on
  dimensions where you find legitimate concerns
- If a dimension is genuinely excellent, you may score it at 4 (never 5 unless
  you have exhausted all attack vectors and found nothing)
- A score of 1 on ANY dimension triggers automatic synthesis round and
  signals you have found a potentially blocking issue

## Escalation Power
You may write "ESCALATE: [specific reason]" if you identify a concern that:
- Could cause incorrect behavior in production
- Represents a safety or correctness issue the majority is dismissing
- You can describe a specific, plausible failure scenario others cannot rebut

## Output Format (JSON)
{
  "scores": {
    "correctness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" },
    "completeness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" },
    "clarity": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" },
    "robustness": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" },
    "utility": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" },
    "consistency": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" },
    "maintainability": { "score": <1-5>, "confidence": <0.0-1.0>, "evidence": "<verbatim quote>", "attack": "<failure scenario>" }
  },
  "overall_assessment": "<2-3 sentence adversarial summary>",
  "strongest_objection": "<the single strongest reason to NOT ship>",
  "failure_scenarios": [
    { "scenario": "<concrete description>", "severity": "<critical|high|medium|low>", "dimension": "<affected dimension>" }
  ],
  "escalation": null | "ESCALATE: <reason>",
  "pass_recommendation": "<SHIP|SHIP_WITH_CAVEATS|ITERATE|REJECT>"
}

## Evaluation Context
- Artifact type: {{artifact_type}}
- Specification: {{spec_reference}}
- Production context: {{production_context}}
```

### Synthesis Round Prompt (shared with all members after anonymization)

```markdown
# Synthesis Round: Disagreement Resolution

The panel has scored this artifact independently. Disagreement exists on the
following dimensions: {{disputed_dimensions}}

## Your Scores vs Anonymous Peer Scores
{{score_comparison_table}}

## Anonymous Peer Rationales
{{anonymized_rationales}}

## Your Task
1. Read all peer rationales carefully
2. For each disputed dimension, either:
   a) REVISE your score (with written justification for the change), OR
   b) MAINTAIN your score (with a one-sentence rebuttal to the strongest opposing argument)
3. You may ONLY change scores on disputed dimensions
4. If you change a score, your confidence on that dimension resets to the
   average of your original confidence and the opposing member's confidence

## Output Format (JSON)
{
  "revised_scores": {
    "<dimension>": {
      "original": <1-5>,
      "revised": <1-5>,
      "action": "<REVISED|MAINTAINED>",
      "justification": "<why you changed or didn't>"
    }
  },
  "synthesis_notes": "<any observations about the deliberation process>",
  "final_recommendation": "<SHIP|SHIP_WITH_CAVEATS|ITERATE|REJECT>"
}
```

---

## Orchestrator Logic (Pseudocode)

```python
def run_panel_evaluation(artifact, spec, context):
    # Phase 1: Independent scoring (no cross-talk)
    scores = parallel_evaluate([
        launch_verifier_a(artifact, spec, context),
        launch_verifier_b(artifact, spec, context),
        launch_devils_advocate(artifact, spec, context),
    ])

    # Check for immediate consensus
    disagreement = detect_disagreement(scores)

    if not disagreement.has_disputes:
        return compute_final_score(scores, method="mean")

    # Phase 2: Synthesis round
    anonymized_rationales = anonymize_and_shuffle(scores)
    revised_scores = parallel_synthesize([
        synthesis_round(member, anonymized_rationales, disagreement.disputed_dims)
        for member in panel
    ])

    # Phase 3: Resolution
    convergence = test_convergence(revised_scores)

    if convergence.converged:
        return compute_final_score(revised_scores, method="mean")
    elif convergence.has_majority:
        result = compute_final_score(revised_scores, method="majority")
        result.minority_report = build_minority_report(convergence.dissenter)
        return result
    else:
        # Deadlock or DA escalation
        if has_escalation(revised_scores):
            return escalate_to_user(revised_scores, artifact)
        else:
            return compute_final_score(revised_scores, method="majority_with_dissent")


def detect_disagreement(scores):
    disputes = []
    for dim in DIMENSIONS:
        dim_scores = [s[dim].score for s in scores]
        spread = max(dim_scores) - min(dim_scores)
        if spread >= 2:
            disputes.append(dim)

    # Check pass/fail split
    overalls = [compute_weighted(s) for s in scores]
    if max(overalls) >= 3.5 and min(overalls) < 3.0:
        disputes.append("overall_direction")

    # Check DA veto
    da_scores = scores[2]  # Devil's Advocate is always index 2
    for dim in DIMENSIONS:
        if da_scores[dim].score == 1:
            disputes.append(f"da_veto_{dim}")

    return DisagreementReport(disputes)


def test_convergence(revised_scores):
    for dim in DIMENSIONS:
        dim_scores = [s[dim].revised for s in revised_scores]
        spread = max(dim_scores) - min(dim_scores)
        if spread > 1:
            # Check if 2-of-3 agree
            if not has_majority_pair(dim_scores):
                return Convergence(deadlock=True)

    return Convergence(converged=all_within_1_point(revised_scores))
```

---

## Integration with Autoresearch Loop

```
┌──────────────────────────────────────────────────────┐
│                AUTORESEARCH LOOP                      │
│                                                      │
│  ┌─────────┐    ┌──────────┐    ┌────────────────┐  │
│  │  DOER   │───▶│  PANEL   │───▶│  SCORE CHECK   │  │
│  │ (build) │    │ (verify) │    │  (threshold?)  │  │
│  └─────────┘    └──────────┘    └───────┬────────┘  │
│       ▲                                  │           │
│       │              ┌───────────────────┘           │
│       │              ▼                               │
│       │    ┌──────────────────┐                      │
│       │    │  ≥ 4.0? → SHIP  │                      │
│       │    │  < 4.0? → LOOP  │─── feedback ───┐     │
│       │    └──────────────────┘                │     │
│       │                                        │     │
│       └────────────────────────────────────────┘     │
│                                                      │
│  Loop terminates when:                               │
│  1. Score ≥ 4.0 (success)                           │
│  2. Max iterations reached (human review)           │
│  3. Score plateaus for 3 iterations (human review)  │
│  4. User escalation triggered (human review)        │
└──────────────────────────────────────────────────────┘
```

The PANEL output feeds directly into the autoresearch loop:
- **SHIP** → Exit loop, artifact is ready
- **ITERATE** → Feed panel's `top_concern` + `failure_scenarios` + dimension scores as structured feedback to the Doer agent
- **REJECT** → Feed full panel report; Doer must address ALL blocking concerns before re-submission

---

## Key Design Decisions & Rationale

| Decision | Rationale | Source |
|----------|-----------|--------|
| 3 panel members (not 5+) | Diminishing returns above 3 for focused evaluation; cost-efficient | DCI finding: 4 delegates optimal for complex tasks |
| Explicit "you must oppose" for DA | 99.2% disagreement vs 48.3% baseline; soft prompts don't work | OpenReview devil's advocate paper |
| Per-criterion atomic scoring | Prevents halo effects where one strong dimension inflates others | Autorubric (arXiv:2603.00077) |
| Evidence-anchored scores | Prevents hallucinated justifications; forces grounding | Rulers framework |
| Anonymized synthesis round | Removes source bias; judges evaluate arguments not sources | LLM Council skill pattern |
| Confidence signals per dimension | Enables weighted aggregation; identifies uncertain areas | Confidence-modulated debate paper |
| Named failure scenarios (not generic skepticism) | Generic skepticism has catch rate = false positive rate; useless | Oracle Poisoning paper (arXiv:2605.09822) |
| Majority with minority report | Preserves institutional knowledge; dissent = future signal | DCI decision packets |
| DA escalation power | Prevents tyranny of majority on safety-critical issues | LinqAlpha devil's advocate pattern |
| Single synthesis round (not iterative) | 62x token cost for DCI's full deliberation; our tasks are bounded | DCI efficiency findings |

---

## Anti-Patterns to Avoid

1. **Generic skepticism** — "Be critical" produces noise equal to false positives. Always name the attack vector.
2. **Consensus pressure** — Never show panel members each other's scores before independent evaluation.
3. **Score anchoring** — Never provide "expected" scores or prior iteration scores to the panel.
4. **Halo inflation** — Never ask for a single holistic score; always decompose into dimensions.
5. **Unbounded debate** — Cap synthesis at 1 round. More rounds = convergence to the most verbose agent, not the most correct.
6. **DA drift to agreement** — The DA's system prompt must PROHIBIT agreement language. It exists to find fault.
7. **Ignoring dissent** — Every minority report must be persisted and available to the next autoresearch iteration.

---

## Existing Codebase Patterns (from workspace search)

The workspace already implements related patterns:
- **LLM Council** (`/.agents/skills/llm-council/SKILL.md`): Multi-agent planning with anonymized judging, randomized order, and structured JSON outputs. Key alignment: independence between planners, anonymization before judging, retry logic.
- **Autoresearch** (`/.agents/skills/autoresearch/SKILL.md`): Autonomous iteration loop with measurable metrics. Key alignment: loop-until-threshold, feedback from metrics to next iteration.
- **Premortem** (`/.agents/skills/premortem/SKILL.md`): Structured risk identification before execution. Key alignment: adversarial thinking, failure mode enumeration.
- **Initial Prompt Philosophy** (`/docs/thoughts/initial-prompt.md`): "We trust consensus. Hence we sometimes spawn multiple verifier subagents and have them working until they reach consensus."

The PANEL protocol is a formalization and improvement of these existing patterns — adding structured rubrics, evidence requirements, typed disagreement resolution, and explicit escalation paths.
