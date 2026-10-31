# Architecture

Design overview of the `create-skill-autoresearch` factory.

## Pipeline

The factory runs a 5-phase pipeline. Every successful skill build in our case studies followed this exact pattern, regardless of domain.

```mermaid
flowchart TB
  subgraph phase1 [Phase 1: Interview]
    Q1[Discover purpose and domain]
    Q2[Identify gold standards]
    Q3[Define scope and constraints]
    Q1 --> Q2 --> Q3
  end

  subgraph phase2 [Phase 2: Research]
    R1[Study domain materials]
    R2[Distill research dossier]
    R3[Propose rubric]
    R1 --> R2 --> R3
  end

  subgraph phase3 [Phase 3: Draft]
    D1[Design skill structure]
    D2[Generate SKILL.md draft]
    D3[Establish baseline score]
    D1 --> D2 --> D3
  end

  subgraph phase4 [Phase 4: Autoresearch]
    A1[Run skill on test cases]
    A2[Evaluate vs gold standards]
    A3{"Improved?"}
    A4[Keep + log ASI]
    A5[Revert + log ASI]
    A1 --> A2 --> A3
    A3 -->|Yes| A4 --> A1
    A3 -->|No| A5 --> A1
  end

  subgraph phase5 [Phase 5: Verify]
    V1[Premortem analysis]
    V2[Panel independent scoring]
    V3[Consensus protocol]
    V4[Ship or iterate]
    V1 --> V2 --> V3 --> V4
  end

  phase1 --> phase2 --> phase3 --> phase4 --> phase5
  V4 -->|ITERATE| phase4
```

## Agent Roles

The factory orchestrates 4 distinct agent roles. The key architectural constraint is context isolation: the BUILDER and PANEL never share context, preventing bias.

```mermaid
flowchart LR
  subgraph orch [ORCHESTRATOR]
    ORC["Factory skill itself<br/>Manages phases, spawns agents"]
  end

  subgraph res [RESEARCHER]
    RES["N parallel subagents<br/>Study materials, build dossier"]
  end

  subgraph build [BUILDER]
    BLD["Drafts and iterates skill<br/>Invokes autoresearch"]
  end

  subgraph panel [PANEL]
    P1["Verifier-A: Quality"]
    P2["Verifier-B: Utility"]
    P3["Devil's Advocate"]
  end

  orch --> res
  orch --> build
  orch --> panel

  build -.->|"context wall"| panel
```

| Role | What It Does | How It's Spawned |
|------|-------------|-----------------|
| ORCHESTRATOR | Manages phase transitions, spawns other roles, handles handoffs | The factory skill itself (the parent agent) |
| RESEARCHER | Studies domain materials, writes research notes | N parallel `explore` subagents |
| BUILDER | Drafts SKILL.md, runs autoresearch loop | Single subagent with autoresearch skill |
| PANEL | Independent verification and consensus | 3 parallel `generalPurpose` subagents |

## Evaluation Architecture

```mermaid
flowchart TB
  GS[Gold Standards] --> ES[evaluate.sh]
  SK[Skill Draft] --> ES
  RB[rubric.yaml] --> ES
  ES --> |"METRIC dim=score"| AR[Autoresearch Loop]
  AR --> |keep/discard| SK
  AR --> |ASI| JL[autoresearch.jsonl]
  AR --> |results| TSV[results.tsv]
```

The evaluation pipeline:
1. `evaluate.sh` takes a gold standard test case as input
2. Runs the skill on the test case input
3. Uses an LLM-as-judge to compare output to the gold standard reference
4. Scores each rubric dimension independently
5. Emits `METRIC <dimension>=<score>` lines for the autoresearch skill to parse

### Why the factory writes a script instead of judging inline

Committing the measurement to a **script** — `evaluate.sh`, plus whatever Python or shell it needs — is
a deliberate design choice, not an artifact of the implementation. An agent asked to score its own work
inline will score it differently each time, and an improvement loop built on a metric that drifts
optimizes noise. A script pins the measurement: same input, same number, every run, and a diff shows
exactly when the bar moved. It also makes the deterministic parts genuinely deterministic — line
counts, frontmatter validation, link integrity and pattern coverage need no model at all, so the judge
is reserved for what actually requires judgment.

The same reasoning drives the [METRIC protocol](reference/metric-protocol.md): a scalar on stdout is
something the loop can compare across experiments, where prose is not.

### What the loop optimizes, and what it does not

`overall_score` is **absolute** output quality against your gold standards. It is not a measure of how
much the skill helps — that is uplift, measured by a separate benchmark with a bare arm and a
with-skill arm. Reading effectiveness off the loop's metric is a common mistake; see
[tuning.md](reference/tuning.md#two-questions-two-instruments).

## Consensus Protocol

The verification panel uses a structured protocol inspired by academic research on multi-agent deliberation.

```mermaid
flowchart TB
  IS["Independent Scoring<br/>3 panel members score in isolation"] --> AC{"All within<br/>1 point?"}
  AC -->|Yes| SHIP[Consensus Reached]
  AC -->|No| SR["Synthesis Round<br/>Anonymized rationales shared"]
  SR --> RC{"Converged?"}
  RC -->|Yes| SHIP2[Accept Consensus]
  RC -->|"2-of-3 agree"| MAJ["Majority Rules<br/>Dissent logged"]
  RC -->|Deadlock| ESC[Escalate to User]
  DA["DA Escalation"] -.-> ESC
```

Key design decisions:
- **Per-criterion atomic scoring** prevents halo effects (Autorubric research)
- **Evidence-anchoring** requires verbatim quotes for extreme scores (Rulers framework)
- **Explicit adversarial assignment** achieves 99.2% disagreement detection vs 48.3% for "think critically" (OpenReview research)
- **Single synthesis round** balances deliberation quality against token cost

## Skill Integration

```mermaid
flowchart LR
  CSA["create-skill-autoresearch"] --> AR2["autoresearch<br/>(called as skill)"]
  CSA --> PM["premortem<br/>(invoked Phase 5)"]
  CSA --> HO["handoff<br/>(invoked on context fatigue)"]
  CSA -.->|"if installed"| TR["tribunal<br/>(Phase 5 verification)"]
  CSA --> SC["skill-creator<br/>(Phase 3 authoring, 4.6 description)"]
  CSA -.->|"craft passes"| WFA["writing-for-agents"]
  CSA --> PE["claude plugin eval<br/>(3.6 suite, 5.0 gate)"]
  CSA -.->|"follows conventions"| PG["production-grade"]
```

| Skill | Integration Type | When |
|-------|-----------------|------|
| skill-creator | Called as dependency, with fallback | Phase 3.3 authoring and Phase 4.6 description pass; without it, the 3.3 checklist and `references/standalone-fallback.md` |
| autoresearch | Called as dependency | Phase 4: the upstream experimentation loop, run with the factory's METRIC, checks and jsonl conventions (`references/phase-4.md`) |
| `claude plugin eval` | CLI, with fallback | Phase 3.6 builds a wrapper-plugin suite in `work/evaluation/plugin/`; Phase 5.0 runs it with and without the skill. Without Claude Code, `evaluate.sh` and the manual uplift benchmark |
| premortem | Invoked directly | Phase 5: before panel evaluation |
| handoff | Invoked directly | When context fatigues or session ends |
| tribunal | Delegated to when installed | Phase 5: replaces the inline panel; the inline one remains the fallback so a standalone install works |
| writing-for-agents | Called as dependency, with fallback | Phase 3.1 design and the Phase 4 craft passes; failure modes probed in Phase 5 |
| production-grade | Conventions followed | Throughout (plan-of-plans, quality gates) |
| llm-council | Design influence only | Phase 5 panel and consensus design |

## Design Decisions

All 18 locked design decisions are documented in [thoughts/07-design-questions.md](thoughts/07-design-questions.md). Key ones:

- **D4**: 4-role agent topology (Orchestrator, Researcher, Builder, Panel)
- **D5**: Structured consensus with synthesis round and escalation
- **D7**: Two-tier loop budget (per-session + score threshold + plateau detection)
- **D8**: Shipped skill package vs process artifacts split
- **D13**: Adaptive data split (70/20/10 for 10+ cases, leave-one-out for fewer)
- **D17**: Enhance then call autoresearch skill (not embed)
- **D18**: Incremental build in 5 phases

## Case Study Origins

Each factory component traces to a real-world case study:

| Component | Origin | Evidence |
|-----------|--------|----------|
| 5-phase pipeline | All case studies | Every build followed this pattern |
| METRIC protocol | Case studies + pi-autoresearch | Automated experiments proved it |
| Research dossier | tokyo skill | 19 research files, 10 parallel subagents |
| LLM-as-judge | Case studies | Deterministic scoring with rubrics |
| Panel consensus | Philosophy + research | Formalized from described approach |
| Handoff documents | tokyo skill | 2 cross-session handoffs preserved continuity |
| Craft-decisions ledger | tokyo v2 | 85+ DNN entries tracked every iteration |
