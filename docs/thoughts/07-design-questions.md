# Design Decisions Log

Decisions made during the interview process for the skill creation factory.

## Decided

### D1 -- Skill Types: All types from day one
The factory handles all skill types: code-behavior (A), domain-workflow (B), and pipeline (C). The universal pipeline is the same; differences are in gold standard format and evaluation method -- those become pluggable modules.

### D2 -- Gold Standard Intake: Interview + flexible formats
The factory interviews the user to discover gold standards, supports multiple intake formats (pairs, reference solutions, quality reports). Leans toward interview-driven discovery + structured pairs.

### D3 -- Execution Environment: Agent skill
The factory is an agent skill (SKILL.md) that orchestrates everything. It spawns subagents for research, drafting, evaluation, and verification.

### D4 -- Agent Topology: 4-role system
- ORCHESTRATOR: the factory skill itself, manages phases and spawns others
- RESEARCHER: studies materials, builds dossier (can be N parallel subagents)
- BUILDER: drafts and iterates the skill (the doer)
- PANEL: 3 verifier subagents (including 1 Devil's Advocate) that evaluate independently then reach consensus

Key constraint: BUILDER and PANEL never share context. PANEL only sees skill output + gold standards + rubric.

### D5 -- Consensus Mechanism: Structured protocol with synthesis
1. Each panel member independently scores against rubric (no cross-talk)
2. Scores aggregated; if all agree (within tolerance), consensus reached
3. If disagreement, each writes a 1-paragraph rationale
4. Synthesis round: panel sees all rationales, re-scores
5. Majority rules after synthesis, dissenting concerns logged
6. Devil's Advocate can escalate to user if critical issue overruled

### D6 -- Rubric Creation: Factory proposes, user refines
Factory generates draft rubric from gold standards + skill domain. Universal dimensions always included. Domain-specific dimensions proposed and confirmed. Can use dedicated agents for rubric generation.

### D7 -- Loop Budget: Two-tier with plateau detection
1. Per-session budget (e.g., 10-20 experiments before handoff)
2. Overall target: score threshold on rubric
3. Plateau detection: stop if N consecutive experiments fail to improve by more than judge variance
Multi-session via handoff documents.

### D8 -- Output Structure: Split shipped vs process
**SHIPS (installable skill package):**
- skill-name/SKILL.md
- skill-name/references/ (if needed)
- skill-name/scripts/ (if needed -- NOT evaluation scripts)
- skill-name/assets/ (if needed)

**STAYS (process artifacts in harness):**
- research/ -- dossier, study notes
- experiments/ -- results.tsv, craft-decisions
- gold-standards/ -- input/output pairs
- evaluation/ -- rubric, evaluation scripts, judge configs
- BENCHMARK.md -- final verification scores (generated at end of Phase 5)
- handoffs/ -- context preservation

### D9 -- Re-run Capability: Yes
Evaluation suite must be re-runnable independently for regression testing and drift detection.

### D10 -- Premortem: Yes, before Panel verification
Premortem agent identifies risks in skill design; risks become additional test cases for the Panel.

### D11 -- Factory Name: create-skill-autoresearch
Descriptive name that references both the create-skill concept and autoresearch methodology.

### D12 -- Model Roles: Concept-slot approach
Prescribe model ROLES not specific names:
- Strongest available model for building/drafting
- Fast model for search/lookup subagents
- DIFFERENT model family for judge panel when possible

### D13 -- Test Cases: Minimum 3, adaptive split
Adaptive data split:
- 10+ gold standards: 70% training / 20% validation / 10% test
- 3-9 gold standards: leave-one-out rotation
Prevents overfitting to training examples.

### D14 -- create-skill Integration: Follow conventions
Follow create-skill conventions (frontmatter, structure, naming) but generate SKILL.md ourselves for full control over initial draft quality.

### D15 -- Handoff Format: Both state file + rich doc
1. Structured state file (YAML) for automatic resume
2. Rich handoff document (markdown) for human readability
Next session reads state file for WHERE, handoff doc for WHY and WHAT.

### D16 -- Self-Bootstrap: v2 goal
Build v1 manually with production-grade rigor. Use v1 to improve itself for v2. Ultimate dogfooding validation.

### D17 -- Existing Skills Integration: Mixed approach (REVISED)
- production-grade: follow its principles, don't invoke as dependency
- premortem: invoke directly during pre-Panel phase
- **autoresearch: ENHANCE then CALL as a skill** -- first upgrade the autoresearch skill with pi-autoresearch patterns (METRIC protocol, ASI fields, checks.sh, commit-first git, confidence scoring), then the factory calls the enhanced skill in Phase 4 with a factory-provided `evaluate.sh` as the metric command. This way the autoresearch skill gets better for all users, and the factory doesn't reinvent the loop.
- documentation-writer: invoke for generating reference docs if needed
- create-skill (Cursor): follow conventions, don't invoke
- handoff: invoke when context fatigues

### D18 -- Phased Build: Incremental (5 phases)
- **Phase 0: Enhance autoresearch skill** -- upgrade `.agents/skills/autoresearch/SKILL.md` with pi-autoresearch patterns
- Phase 1 (MVP): Core pipeline -- interview, research, draft, call enhanced autoresearch with LLM-as-judge evaluation
- Phase 2: Multi-agent verification -- Panel with consensus, Devil's Advocate
- Phase 3: Advanced features -- plateau detection, multi-judge, 70/20/10 split, handoff/resume
- Phase 4: Self-improvement -- run factory on itself, refine

### D19 -- Ship Decision: Metric-first when outputs are checkable (2026-10-30, user decision)
Evidence (n10-* benchmark): Haiku builds that ran 3 panel rounds scored 0.836-0.871 on the deterministic answer key
against 0.861-0.971 for 1-round builds, and the panel's label did not track the key (UNSHIPPED skills at 0.969-0.978,
SHIP WITH CAVEATS at 0.836). Panel-driven edits cost money and lowered quality.
- `rubric.yaml` `metric: answer-key`: the 5.0 gate (every gold delta > 0; caveats down to -caveat_margin, below it
  UNSHIPPED) and the Phase 4 metric on the shipped commit (the lower of it and validation) against target_score decide;
  the panel runs one round as a logged review and vetoes only by a cited `veto` (hard constraint, safety, the DA's
  ESCALATE with a reproduction). `check_gate.py` prints and enforces a `SHIP RULE:` line.
- `metric: llm-judge` or absent: the panel's verdict as before, `max_panel_rounds` 3. The gold deltas cap it by the
  same rule as metric-first (verdict-rules.json `gold_gate`; `check_gate.py --consensus` prints a `GOLD GATE:` line):
  a delta <= 0 caps at SHIP WITH CAVEATS, one below -caveat_margin allows only UNSHIPPED. Until 2026-10-30 this path
  capped at SHIP WITH CAVEATS however negative; the user chose the stricter rule for both (2026-10-30), since a skill
  that makes a gold case clearly worse should not ship on a panel's scores.

### D20 -- Stopping and shipping on a held-out score (2026-10-31, user decision)
Evidence (c18-* benchmark, harness d2f7456): v0.3 Haiku task-2 builds read 0.95-1.0 on their own Phase 4 metric, often
at experiment 0, so the fast path, the 1.0 ceiling and the plateau ended Phase 4 early, while the hidden holdout scored
those skills 0.85-0.91 (median 0.877 against v0.2.1's 0.959, which never stopped early); commit messages on Haiku the
same (0.871 against 0.921). The stops trusted a training metric that cannot see overfitting to a handful of gold
standards, and with 3-9 gold standards there was no validation split for "the lower of" to read.
- Every experiment line logs `held_out`: the validation list's mean (>= 10 gold), the rotated-out case (leave-one-out,
  3-9), or the mean over >= 3 synthetic cases written from the materials (< 3). A `validation_check` line for the same
  experiment still counts.
- The 3.5 fast path, the 4.3 ceiling, plateau and target stops, and the metric-first ship rule (the lower of the
  metric and `held_out`) read it through `check_gate.py`. A metric above `held_out` by more than the noise threshold
  is the overfitting signal: no fast path, the loop stays open. No `held_out` is not measured: the loop stays open
  and metric-first ships UNSHIPPED. `max_iterations` (rubric.yaml) is now a loop-guard stop, the backstop for both.
- Known weakness: under leave-one-out the held-out case was seen in the Phase 3 draft and in earlier experiments, and
  one case against an N-1 mean carries case-difficulty spread, which the noise threshold (measured on training
  re-runs) does not cover; if leave-one-out builds run to the budget and cost regresses, that threshold is the lever.

### D21 -- Verified fix cycles after the panel (2026-11-07, user decision)
Evidence (r20-* benchmark, harness 53dd1b5): 26 of 60 builds ended UNSHIPPED, many with hidden answer-key scores of
0.985-1.0. The dominant shape: the panel (or the lite reviewer) found a real, reproducible defect (a request line
pasted into a double-quoted shell command, a Decimal crash for low-income applicants, a parser misreading money lines),
the builder fixed it, and the one-round rule (metric-first, lite) or a spent Phase 4 budget (r20-t1 Haiku ITERATEs)
ended the build UNSHIPPED with the better skill as a draft.
- A consensus that ends the build UNSHIPPED on **cited** findings may run up to `max_fix_cycles` (2, every profile)
  fix cycles (`scripts/fix_cycle.py`, `references/fix-cycle.md`). A finding is a receipt's `veto` or, on the
  panel-verdict path, a failure scenario the member cites with a verbatim `evidence` quote and a `repro`; nothing
  else opens a cycle, and none opens when the gate or the metric already allows only UNSHIPPED.
- The fix is one commit on top of the reviewed version whose every hunk lies in a range the notes declare for a
  finding, with the gate inputs unchanged; only then does the gate re-run. The roles that raised the findings re-check
  only those findings and the touched lines, in receipts bound to the fixed hash; a regression counts as unresolved.
  The panel never re-runs and no dimension is added. Outside a cycle, A3 stands: a post-panel edit cannot re-gate.
- The original panel scores stand; resolved findings leave the veto. Metric-first: the gate and metric decide.
  Panel-verdict path: ITERATE and BLOCK come from scores, which a cycle does not change, so clearing findings alone
  could not move the label; an ITERATE, BLOCK or ESCALATE label instead caps the verdict at SHIP WITH CAVEATS once
  every cited finding resolves (the below-target scores are the caveats), the gate and metric below that. This is the
  one reading of "the verdict can only improve to what the gate, metric and remaining findings allow" that lets the
  r20-t1 ITERATEs reach a verdict without re-scoring.
- Known limit: the declared-lines rule is mechanical; the builder declares the ranges, and only the re-check judges
  whether a declared change is part of the fix. A post-panel edit with no cited finding (r20-t2-haiku-2's hardening)
  still ends UNSHIPPED.
