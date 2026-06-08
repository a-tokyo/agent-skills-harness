# Cross-Cutting Patterns from All Case Studies

Distilled from studying 6 skill-building efforts across different domains, teams, and tools.

## The Universal Pipeline

Every successful skill build followed this five-phase pattern, regardless of domain:

```
Phase 1: Gold Standard Acquisition
  Collect human-written exemplars → structure as verifiable pairs or benchmarks

Phase 2: Research and Study
  Deep study of domain materials → distill into research notes → identify rubrics

Phase 3: Skill Drafting
  Draft initial skill/prompt → commit as baseline → measure baseline score

Phase 4: Autoresearch Loop
  Run skill on known inputs → evaluate vs gold standard → keep/revert → log → repeat

Phase 5: Verification and Hardening
  Multi-agent consensus → devils advocate review → final quality gate → ship
```

## Case Study Matrix

| Case Study | Domain | Gold Standard Source | Evaluation Method | Autoresearch Tool | Iterations | Final Score |
|---|---|---|---|---|---|---|
| tokyo skill | Engineering posture | Operator's shipped work (V1-V36, S1-S41) | 12-gate quality bar (manual + structural) | Manual autoresearch ledger (D0-D85+) | 8+ iterations, 11 subagents | All 12 gates green |
| PO docs | Product documentation | Human-written Confluence pages | 14-dimension rubric scored 0-2 (LLM self-eval) | Built into skill (Phase 5) | Max 3 per page | 24+/28 target |
| structured-document generation | Executive summaries | 13 weeks of human-written aggregations | 6-dimension LLM-as-judge (1-10 scale) | pi-autoresearch + custom Python scripts | 69 automated experiments | 8.1/10 |
| game-content team | Game scenario generation | Human-written game scenarios | Quality report + benchmarking | Autoresearch on prompts | Multiple iterations | Matched/exceeded human quality |
| Task-decomposition workflow | Complex task execution | Task specifications | Validation loops per unit of work | Built into workflow | Continuous | Small models (Haiku) doing complex work |

## Key Patterns

### Pattern 1: Gold Standards Are Non-Negotiable
Every case study started by acquiring human-produced exemplars. Without a "what good looks like" reference, there is no measurable improvement target. The gold standard takes different shapes:
- **Document pairs** (structured-document generation): input document + human-written output document
- **Existing artifacts** (PO docs): completed Confluence pages that set the quality bar
- **Operator knowledge** (tokyo): V/S anchors distilled from years of shipped work
- **Manual work product** (game-content team): scenarios humans wrote by hand

### Pattern 2: Rubrics Must Be Deterministic and Multi-Dimensional
Single-number scores hide too much. Every successful effort broke quality into 5-14 specific dimensions:
- structured-document generation: structure, curation, content_accuracy, conciseness, problems_quality, overall_match
- PO docs: coverage, UI depth, business-rule depth, permissions, cross-references, testing hints, edge cases, formatting, evidence discipline, template conformance, PO accessibility, technical preservation, source-link annotation, description/notes split
- tokyo: V coverage, S coverage, hardcoded-name scan, banned-phrase scan, cross-ref integrity, currency check, voice, idiom alignment, etc.

### Pattern 3: The Autoresearch Loop Is the Engine
Whether using the autoresearch skill, pi-autoresearch, or custom scripts, the core loop is identical:
```
THINK → EDIT → COMMIT → RUN → MEASURE → DECIDE (keep/revert) → LOG → REPEAT
```
Critical properties:
- Every experiment is committed before running (clean revert path)
- Failed experiments are reverted, not accumulated
- A results ledger tracks every attempt (TSV or markdown)
- The loop runs autonomously until budget exhausted or target met

### Pattern 4: Verification Requires Fresh Context (No Self-Grading)
The doer agent cannot also be the sole verifier. Approaches used:
- **Separate LLM-as-judge** (structured-document generation): different model evaluates output vs reference
- **Structural scans** (tokyo): automated grep/count checks that don't need LLM judgment
- **Multi-agent consensus** (task-decomposition workflow, described philosophy): spawn multiple verifiers, require agreement
- **Devils advocate** (described philosophy): one agent whose job is to find fault

### Pattern 5: Handoffs Preserve Continuity
Long-running skill builds outlast a single agent context window. Successful efforts used:
- Handoff documents (tokyo: HANDOFF-iter-6-to-iter-7.md, HANDOFF-iter-7-to-iter-8.md)
- Craft-decisions ledger (tokyo: D0-D85+ entries)
- Subagent transcript archives (tokyo: 11 JSONL transcripts)
- Results logs (structured-document generation: autoresearch.md with 20+ experiment entries)

### Pattern 6: Parallel Subagent Orchestration Scales Context Gathering
When the research surface is wide, fanning out N subagents in parallel beats serial exploration:
- tokyo skill: 10 subagents (A-J) mining different repos, canonical sources, peer skills simultaneously
- PO docs: 6 subagents per page for code analysis, Confluence search, Jira search, GitHub, Slack, git blame
- The orchestrator dispatches, monitors, and synthesizes results

### Pattern 7: The Skill Itself Embeds Its Own Quality Loop
The most mature skills (PO docs) have the autoresearch loop built INTO the skill itself:
- Phase 5 of the PO docs skill scores the output against a rubric
- If below threshold, it iterates up to 3 times
- This means the skill self-improves at runtime, not just at creation time

## Gaps and Open Questions

1. **No unified factory**: each effort built its own harness from scratch
2. **Inconsistent tooling**: autoresearch skill vs pi-autoresearch vs custom Python scripts
3. **No standard gold standard format**: pairs.json vs directory of .md files vs Confluence pages
4. **No standard rubric format**: Python dict vs markdown table vs YAML
5. **Verification depth varies**: some had automated judges, others relied on structural checks only
6. **No consensus mechanism formalized**: the "multiple verifiers reaching consensus" and "devils advocate" patterns are described philosophically but not yet codified into a reusable workflow
