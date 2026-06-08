# Agent Skills Harness

A factory for building production-grade agent skills — benchmarked against gold standards,
autonomously improved via an autoresearch loop, and verified by independent multi-agent consensus.

Fork it, drop in examples of "what good looks like", and the factory researches your domain,
drafts a skill, iterates it against a measurable rubric, and has an independent panel sign off
before shipping.

## What this is

The core deliverable is **`create-skill-autoresearch`** — an agent skill that runs the entire
skill-creation lifecycle as a 5-phase pipeline:

1. **Interview** — discover purpose, gold standards, and scope
2. **Research** — study domain materials with parallel subagents
3. **Draft** — design-first, following the official skill-authoring rules
4. **Autoresearch** — iterate autonomously against LLM-as-judge (or a real-world metric) until the target score is hit
5. **Verify** — independent panel with a devil's advocate, reaching consensus before shipping

It **extends** the official single-pass skill creators (Anthropic's
[Skill best-practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
/ `skill-creator`, and Cursor's `create-skill`) rather than replacing them — adding the research
dossier, benchmarking, improvement loop, and verification a one-shot generator can't.

## Prerequisites

- An AI coding agent that supports the `SKILL.md` format (Claude Code, Cursor, Gemini CLI, …)
- Git (each build is a git workspace)
- **3+ gold standards** — examples of "what good looks like" for the skill you want. Fewer than 3 is a
  risk; the factory will offer to help you create synthetic examples or find more reference material.
- *(Optional)* an OpenAI-compatible judge endpoint via `JUDGE_MODEL` / `JUDGE_API_KEY` / `JUDGE_API_BASE`;
  without one, evaluation falls back to deterministic-only scoring.

## Quick start

```bash
git clone <your-fork-url> agent-skills-harness
cd agent-skills-harness
npm install                                # optional — no runtime deps; enables `npm run skills:update`
git submodule update --init --recursive    # optional — fetches reference implementations under docs/resources/
```

Neither step is required to use the factory — the skills are committed and work offline. Then open the
repo in your AI coding agent and ask:

> *"Build me a skill for <your domain> using the create-skill-autoresearch factory."*

The factory interviews you, then does the rest. **New here?** Walk through
[docs/usage-guide.md](docs/usage-guide.md) — it covers the interview and each phase step by step.

## Build your own skill

Each build is one self-contained, visible folder — `builds/<skill-name>/` — with three zones:

```
builds/<skill-name>/
  input/                 # YOU: drop gold standards + study materials, in ANY structure
  work/                  # FACTORY: research, rubric, evaluate.sh, autoresearch journal, handoffs
  output/<skill-name>/   # FACTORY: the finished skill (SKILL.md + references) — publish-ready
```

You only ever fill `input/`; the factory owns `work/` and `output/`. In practice:

1. **Run the factory** — it interviews you and creates `builds/<skill-name>/`.
2. **Drop your materials into `input/`** (gold standards + study materials, any structure), or point the
   factory at where they already live. You don't hand-author an index — it scans `input/` and derives one for you to confirm.
3. **The factory works in `work/`** (research → rubric → autoresearch → verification); you don't touch it.
4. **Ship from `output/<skill-name>/`** — copy it into a skills repo's `skills/`, or install with `npx skills`.

Upgrading an existing skill? Hand it to the factory as a study material; it baselines against the rubric and improves it rather than starting from scratch.

- **The full contract** (exactly what goes in and comes out): [`docs/reference/io-contract.md`](docs/reference/io-contract.md)
- **The factory's own regression test**: [`self-test/`](self-test/) benchmarks factory output against a
  committed reference skill (it has its own evaluation layout, separate from `builds/`)

`builds/` is gitignored — your builds are yours. To publish a finished skill, copy
`builds/<skill-name>/output/<skill-name>/` into a skills repo's `skills/` directory, or install it
with `npx skills`.

## Run the self-test

The self-test benchmarks the factory against a tracked public case (`tokyo-production-grade`): it
scores a **factory-produced** skill against the committed reference skill. So first run the factory on
that case to produce `self-test/runs/tokyo-production-grade/skill/`, then:

```bash
cd self-test
./evaluation/evaluate.sh tokyo-production-grade   # emits METRIC lines incl. overall_score
```

Without a judge configured (`JUDGE_MODEL` / `JUDGE_API_KEY`) it runs deterministic structural checks
only; if no factory output exists yet it tells you to run the factory first. See
[`self-test/README.md`](self-test/README.md) for details.

For a worked, committed benchmark — the factory rebuilding a reference skill *blind*, scored by an
independent subagent panel with evidence-based consensus (≈ 0.84 vs the 0.80 target) — see
[`self-test/benchmarks/premortem-rebuild.md`](self-test/benchmarks/premortem-rebuild.md).

## Repository structure

```
.agents/skills/                     # The skills this harness USES
  create-skill-autoresearch/        #   the factory (the original deliverable)
  autoresearch/ production-grade/   #   companion skills (vendored — see Provenance)
  premortem/ handoff/ llm-council/  #   ...
  documentation-writer/

builds/                             # The skills this harness PRODUCES (gitignored; your work)
self-test/                          # The factory's own regression test + worked example
docs/
  reference/io-contract.md          # what goes in / what comes out  ← start here
  reference/workspace-layout.md     # full file-by-file build layout
  reference/rubric-format.md        # how to define evaluation rubrics
  reference/metric-protocol.md      # the METRIC line format
  usage-guide.md  architecture.md   # walkthrough + design overview
  thoughts/                         # research notes and design decisions
  resources/                        # external reference implementations (git submodules)
skills-lock.json                    # provenance + version pins for vendored skills
```

> Two skill directories, on purpose: `.agents/skills/` holds the skills the harness *uses*;
> `builds/<name>/output/` holds the skill a run *produces*.

## Documentation

- [I/O Contract](docs/reference/io-contract.md) — what to provide and what you get back
- [Workspace Layout](docs/reference/workspace-layout.md) — every file the factory creates
- [Usage Guide](docs/usage-guide.md) — end-to-end walkthrough
- [Architecture](docs/architecture.md) — design overview
- [Rubric Format](docs/reference/rubric-format.md) · [METRIC Protocol](docs/reference/metric-protocol.md)

## Companion skills & provenance

The factory orchestrates sibling skills at runtime: **autoresearch** (Phase 4), **premortem**
(Phase 5), and **handoff** (cross-session); the panel design draws on **llm-council**. These and a
couple of utilities are **vendored** into `.agents/skills/` and tracked in `skills-lock.json` with
their upstream source and a content hash. Run `npm run skills:update` to refresh them.

With gratitude to the upstream authors:

| Skill | Source |
|-------|--------|
| `autoresearch`, `documentation-writer` | [github/awesome-copilot](https://github.com/github/awesome-copilot) |
| `handoff` | [mattpocock/skills](https://github.com/mattpocock/skills) |
| `llm-council` | [am-will/codex-skills](https://github.com/am-will/codex-skills) |
| `premortem` | [parcadei/continuous-claude-v3](https://github.com/parcadei/continuous-claude-v3) |
| `production-grade` | [a-tokyo/agent-skills](https://github.com/a-tokyo/agent-skills) |

The factory itself, `create-skill-autoresearch`, is also published standalone at
[a-tokyo/agent-skills](https://github.com/a-tokyo/agent-skills)
(`npx skills add a-tokyo/agent-skills --skill create-skill-autoresearch`). This harness is its
development home and batteries-included environment; the published copy is a release. When bumping
the factory's version, copy the updated skill into `a-tokyo/agent-skills` so the two don't diverge.

## License

[MIT](LICENSE) © 2026 Ahmed Tokyo. Vendored skills remain under their respective upstream licenses.
