# AGENTS.md

## Project Overview

Agent Skills Harness is a factory and testing ground for building production-grade agent skills. It provides a structured pipeline for creating skills that are benchmarked against gold standards, autonomously improved via autoresearch loops, and verified through multi-agent consensus.

The core output is the `create-skill-autoresearch` factory skill, which orchestrates the entire skill creation lifecycle.

## Repository Structure

```
.agents/skills/                 # Skills the harness USES (factory + vendored companions)
  create-skill-autoresearch/    # The factory skill (main deliverable; original)
  autoresearch/                 # Autonomous experimentation loop (vendored, upstream as-is)
  skill-creator/                # Anthropic's skill creator: authoring + description pass (vendored)
  production-grade/             # Engineering posture principles (vendored)
  premortem/                    # Risk analysis before execution (vendored)
  handoff/                      # Context preservation across sessions (vendored)
  documentation-writer/         # Diataxis documentation generation (vendored)
  llm-council/                  # Multi-agent planning with consensus (vendored)
  writing-for-agents/           # Skill-writing craft (vendored)
  tribunal/                     # Phase 5 verification when delegated (vendored)
  design-taste-frontend/        # Anti-slop frontend/UI skill (vendored)

builds/                         # Skills the harness PRODUCES (gitignored; one folder per build)
self-test/                      # The factory's own regression test + worked example
site/                           # Docs + landing site (Nextra → Vercel)
skills-lock.json                # Provenance + version pins for vendored skills

docs/
  reference/io-contract.md      # What goes in / what comes out (start here)
  reference/workspace-layout.md # Full file-by-file build layout
  reference/                    # rubric-format, metric-protocol, ...
  thoughts/                     # Research notes and design decisions
  study/                        # Case study materials (gitignored; maintainer-local)
  resources/                    # External reference implementations (git submodules)
  usage-guide.md                # How to use the factory
  architecture.md               # Design overview
```

## Skills

| Skill | Purpose |
|-------|---------|
| `create-skill-autoresearch` | Factory for creating production-grade skills via autoresearch |
| `autoresearch` | Autonomous iterative experimentation loop (upstream; the factory passes it the METRIC, checks and jsonl conventions) |
| `skill-creator` | Anthropic's skill creator; the factory delegates Phase 3 authoring and the Phase 4.6 description pass to it |
| `production-grade` | Principle-engineering posture for production-grade code |
| `premortem` | Identify failure modes before they occur |
| `handoff` | Compact conversation into handoff document for another agent |
| `documentation-writer` | Diataxis-guided documentation generation |
| `llm-council` | Multi-agent planning with anonymized judging |
| `writing-for-agents` | Skill-writing craft: leading words, information hierarchy, pruning; the factory's craft passes |
| `tribunal` | Doer → verifier-panel → consensus verification; the factory delegates Phase 5 to it when present |
| `design-taste-frontend` | Anti-slop frontend/UI design for landing pages and redesigns |

## Setup

```bash
git clone <repo-url>
cd agent-skills-harness
npm install
git submodule update --init --recursive   # docs/resources/ reference implementations
```

No build step required. Skills are markdown-based and used directly by any AI coding agent that supports the SKILL.md format. The vendored skills are committed, so a fresh clone works offline.

To refresh a vendored skill, scope it: `npx skills update <skill-name>`. `npm run skills:refresh-all` does every one of them from each upstream's current HEAD and rewrites the lock entries — review that diff before committing, since an upstream edit changes how a companion behaves. `skills-lock.json` records provenance and a content hash; it is not a pin the CLI restores you to.

`npm test` runs the regression gate (`self-test/evaluation/gate.sh`): the structural checks, failing on any failure not on its advisory list — which is currently empty on purpose, so the suite is expected to be fully green — then the offline tests of the factory's bundled scripts (`.agents/skills/create-skill-autoresearch/scripts/tests/`). It needs no credentials and no network.

## Development Conventions

- Skills live in `.agents/skills/<skill-name>/SKILL.md`
- Skills follow the official skill-authoring rules (Anthropic best-practices; YAML frontmatter, < 500 lines, progressive disclosure, references one level deep) — authored with `skill-creator`; the hard constraints live in the factory's Phase 3.3 checklist and `references/standalone-fallback.md`
- A factory run produces `builds/<skill-name>/` with three zones: `input/` (human materials), `work/` (generated artifacts), `output/<skill-name>/` (the finished skill). `builds/` is gitignored.
- `create-skill-autoresearch` is developed here (source of truth) and published as a byte-identical release to `a-tokyo/agent-skills` — never edit the published copy directly. See "Releasing create-skill-autoresearch" below.
- Research notes go in `docs/thoughts/` with numbered prefixes (00-, 01-, etc.)
- Design decisions are logged in `docs/thoughts/07-design-questions.md`

## Releasing create-skill-autoresearch

The harness is the **source of truth** for the factory skill (it is developed and benchmarked here against
`self-test/`). `a-tokyo/agent-skills` carries a **byte-identical published copy** for `npx skills` installs.
The two are cross-linked (each README points to the other). To cut a release after editing the factory:

1. Bump `version:` in `.agents/skills/create-skill-autoresearch/SKILL.md`.
2. Re-sync the published copy as a whole directory (so `references/` can't silently drift):
   ```bash
   rm -rf ../agent-skills/skills/create-skill-autoresearch
   cp -r .agents/skills/create-skill-autoresearch ../agent-skills/skills/create-skill-autoresearch
   diff -rq .agents/skills/create-skill-autoresearch ../agent-skills/skills/create-skill-autoresearch  # must be empty
   ```
3. Commit in both repos (harness on `main`; `agent-skills` via a PR) and push.

Never edit the `agent-skills` copy directly — edit here and re-sync, or the two diverge (as `production-grade` once did).

## Key Concepts

- **Gold Standards**: Human-produced exemplars that define "what good looks like"
- **METRIC Protocol**: `METRIC name=value` line format for deterministic metric extraction
- **ASI (Actionable Side Information)**: Structured experiment metadata that survives git reverts
- **Panel Consensus**: Multi-agent verification with independent scoring, synthesis rounds, and devil's advocate
- **Craft-Decisions Ledger**: Append-only log of every design decision and iteration

## Testing

There is no unit-test suite; the harness verifies itself with a structural self-test plus benchmark/panel verification. Quality is verified through:
1. **`npm test`** (→ `self-test/evaluation/gate.sh`) — **this is the gate**. It runs the deterministic structural checks in `self-test/evaluation/autoresearch-evaluate.sh`, then fails on any reported failure that is not on its advisory list, then runs the factory's script tests. It needs no credentials and runs on a fresh clone (`bash` + `python3`, no `npm install`). Judge a change by the *issues list*, not by `checks_passed`: adding checks raises the total, so a count comparison hides a regression behind a rising number.
2. `./self-test/evaluation/evaluate.sh <case-id>` — scores a factory-**produced** skill against a reference. It needs a factory output first, and the tracked cases carry `input_materials: null` (their sources are private), so on a public clone you supply your own case. With `JUDGE_MODEL`/`JUDGE_API_KEY` it scores via LLM-as-judge; otherwise structural checks only, and that score is not comparable to a judge-scored target.
3. Panel verification with multi-agent consensus (Quality + Utility + Devil's Advocate) — the committed worked example is `self-test/benchmarks/premortem-rebuild.md`.

## Git Workflow

- Feature branches for skill development
- Autoresearch sessions run on `autoresearch/<tag>` branches
- `builds/` (a run's working area) is gitignored; session artifacts (`results.tsv`, `autoresearch.jsonl`, `run.log`) are never tracked
- When running the factory inside a real project repo, gold standards, the rubric, and evaluation scripts should be committed (see `docs/reference/workspace-layout.md`) — which is exactly why **no credential may ever be written into `work/`**, `judges.yaml` included. Credentials live in the environment; see `docs/reference/tuning.md`.
- Scratch material (notes, transcripts, anything pulled in while working) goes in `tmp/`, which is gitignored. This repo pushes to public remotes — check `git status --short` before committing.
