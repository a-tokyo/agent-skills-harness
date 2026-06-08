# Usage Guide

End-to-end walkthrough of using the `create-skill-autoresearch` factory to build a production-grade agent skill.

## Prerequisites

- An AI coding agent that supports SKILL.md (e.g., Claude Code, Gemini CLI, or similar)
- **Git** repository (the factory uses git branches for experiment tracking)
- **Gold standards**: 3+ examples of "what good looks like" for your skill domain
- **Study materials**: Documentation, code, transcripts, or specs the factory should learn from

## Step 1: Invoke the Factory

In your agent's chat, reference the factory skill:

> "Build me a skill for [your domain] using @create-skill-autoresearch"

Or simply describe what you need and the factory will be triggered automatically if it matches the skill description.

## Step 2: Interview (Phase 1)

The factory asks you a series of structured questions:

### Purpose and Domain
- What skill are you building?
- What problem does it solve?
- Who uses it? (which agent, what context)
- What does success look like?

### Gold Standards
- Do you have examples of ideal output?
- Where are they? What format?
- How many do you have? (minimum 3 recommended)

### Study Materials
- What should the factory study to understand the domain?
- Paths to documentation, code, transcripts, specifications

### Constraints
- Conventions to follow?
- Skills to integrate with?
- Anti-patterns to avoid?

The factory summarizes your answers and asks you to confirm before proceeding.

## Step 3: Research (Phase 2)

The factory spawns parallel researcher subagents to study your materials. Each researcher:
1. Reads assigned materials deeply
2. Writes a research note in `research/`
3. Identifies patterns, conventions, and quality signals

After all researchers complete, the factory synthesizes findings into `work/research/00-synthesis.md` and proposes a scoring rubric.

**You review the rubric** -- this defines how your skill will be evaluated. Adjust dimensions and weights as needed.

## Step 4: Draft (Phase 3)

The factory:
1. Creates a design document (`work/experiments/DESIGN.md`) locking structural decisions
2. Generates an initial SKILL.md draft following the official skill-authoring rules
3. Builds the evaluation pipeline (`work/evaluation/evaluate.sh`)
4. Measures baseline quality against your gold standards

You'll see the baseline score and per-dimension breakdown.

## Step 5: Autoresearch (Phase 4)

The factory invokes the `autoresearch` skill with your evaluation pipeline:
- Each experiment modifies the skill draft
- The evaluation script runs the skill on test cases and scores via LLM-as-judge
- Improvements are kept, regressions are reverted
- Every experiment logs a hypothesis, result, and insight

The loop runs autonomously until the budget is exhausted or a plateau is detected.

### What You See During Autoresearch

The factory tracks progress in:
- `results.tsv` -- human-readable experiment journal
- `autoresearch.jsonl` -- machine log with ASI (actionable side information)
- Git history -- only successful experiments appear as commits

### When to Intervene

- **Plateau detected**: The factory alerts you when N consecutive experiments fail to improve. Consider providing new directions or adjusting the rubric.
- **Context limit**: The factory writes a handoff document and creates a `state.yaml` for seamless resume in a new session.

## Step 6: Verification (Phase 5)

After autoresearch, the factory runs independent verification:

1. **Premortem**: Identifies risks in the skill design
2. **Panel evaluation**: 3 independent verifier subagents score the skill:
   - Verifier-A (Quality): correctness, completeness, clarity
   - Verifier-B (Utility): real-world usability, edge cases
   - Devil's Advocate: failure modes, hidden assumptions
3. **Consensus**: Scores are compared. Disagreements trigger a synthesis round with anonymized rationales.

### Outcomes

| Score | Action |
|-------|--------|
| Above target | **SHIP** -- skill is ready for installation |
| Near target | **SHIP WITH CAVEATS** -- concerns logged |
| Below target | **ITERATE** -- feedback fed back to autoresearch |
| Critical block | **BLOCK** -- specific concern must be addressed |

## Step 7: Ship

The final skill package is placed in `builds/<skill-name>/output/<skill-name>/`:

```
builds/<skill-name>/output/<skill-name>/
  SKILL.md
  references/           # If needed
```

Copy this directory to your target project's `.agents/skills/` (or `~/.cursor/skills/`), or into a skills repo's `skills/` to publish:

```bash
cp -r builds/<skill-name>/output/<skill-name> <your-skills-repo>/skills/
```

## Workspace Layout

The factory creates a workspace with all process artifacts. See [reference/workspace-layout.md](reference/workspace-layout.md) for the full structure.

## Multi-Session Workflows

For complex skills that take multiple sessions:

1. The factory writes `handoffs/state.yaml` when context fatigues
2. In a new session, reference the factory again: *"Resume building the [skill-name] skill"*
3. The factory reads `state.yaml` and continues from the correct phase

## Tips

- **More gold standards = better results**: 10+ examples enable proper train/validation/test splits
- **Review the rubric carefully**: It defines what "good" means -- weak rubrics produce weak skills
- **Read the craft-decisions ledger**: `work/experiments/craft-decisions.md` logs every iteration decision
- **Check the ideas backlog**: `autoresearch.ideas.md` tracks deferred experiment hypotheses
