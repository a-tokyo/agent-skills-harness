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
