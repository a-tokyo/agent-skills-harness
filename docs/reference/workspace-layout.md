# Workspace Layout Reference

The factory creates one self-contained build folder per skill, `builds/<skill-name>/`,
organized into three ownership/lifecycle zones: `input/` (you own it), `work/` (the factory
owns it), and `output/` (the factory owns it). This document describes every file and
directory the factory produces.

`builds/` is gitignored in this harness — it is your working area. (`self-test/` is the factory's own
regression test; it uses a separate evaluation layout, not the three-zone build layout described here.)

## Full Structure

```
builds/<skill-name>/
  input/                          # HUMAN: gold standards + study materials, ANY structure
    ...                           # drop files however you like; the factory discovers them

  work/                           # FACTORY: everything generated during the build (not shipped)
    manifest.yaml                 # Factory-derived index of the gold standards in input/ (you confirm)

    research/                     # Phase 2 output
      00-synthesis.md             # Cross-cutting patterns from all study materials
      01-<topic>.md               # Research note per study-material cluster
      ...

    evaluation/
      rubric.yaml                 # Scored dimensions with weights and criteria
      evaluate.sh                 # METRIC-emitting evaluation script
      evaluate-checks.sh          # Optional correctness gate
      judges.yaml                 # Optional multi-judge configuration
      data-split.yaml             # Train/validation/test assignment (+ plugin_eval case list, written by
                                  #   scripts/gate.py record from disk)
      synthetic/                  # < 3 gold standards only: >= 3 synthetic held-out cases (phase-4.md 4.2)
      run-case.sh                 # Phase 3.6 manual-protocol adapter: one run of <case> <with|without>,
                                  #   prints SCORE=<0..1>
      plugin/                     # Phase 3.6 wrapper plugin: .claude-plugin/plugin.json,
                                  #   skills/<name>/ (copy of output, refreshed by gate.py), evals/<case>/
      gate.json                   # Phase 5.0 gate record: mode (plugin | manual), probe exit code, cases,
                                  #   sha256 of output/<name>/ and of the case set, started/finished
      gate-attempts.jsonl         # one line per gate.py record / gate run and the error that stopped it;
                                  #   check_gate.py --finish needs one before an UNSHIPPED verdict counts
      plugin-eval.json            # Phase 5.0 with/without result (WITH, W/OUT, delta per case)
      uplift.json                 # Phase 5.0 manual with/without result, when plugin eval is unavailable
                                  #   or the skill is user-invoked (replaces plugin-eval.json)

    pids/                         # run_owned.py job records (<name>.json: pid, pgid, supervisor, cmd), logs,
                                  #   exit codes, <name>.lock (held by the live supervisor), <name>.stop
                                  #   (stop request); gate.json/gate.log for the `gate` job; .gitignore (*)

    experiments/
      DESIGN.md                   # Structural decisions locked before drafting
      craft-decisions.md          # Append-only iteration ledger (DNN format)
      improvement-notes.md        # Lesson -> improvement log across rounds (see below)
      OPEN-QUESTIONS.md           # Unresolved questions awaiting a human decision (see below)
      autoresearch.jsonl          # Factory-written machine log, one line per experiment
      results.tsv                 # Human-readable experiment journal (upstream autoresearch)
      autoresearch.ideas.md       # Factory-written hypothesis backlog
      run.log                     # Last evaluation command output

    handoffs/                     # Context preservation
      state.yaml                  # Structured resume state
      HANDOFF-<label>.md          # Rich handoff documents

  output/                         # FACTORY: the finished skill, publish-ready
    <skill-name>/                 # the skill in its own named dir
      SKILL.md                    # The skill itself
      README.md                   # Optional, ships on install: what it does, method, results
      references/                 # Reference files (if needed)
      scripts/                    # Executable utilities (if needed)
      assets/                     # Static assets (if needed)

  output-<variant>/               # Optional: a competing draft kept for comparison (see below)
  BENCHMARK.md                    # Final panel scores + verdict (Phase 5)
```

This is a shape, not a schema. Real builds diverge — one may keep its ledger at `work/` root, or add
`work/runs/` and `work/fixture/` for a benchmark harness, or never need `handoffs/` because it finished
in one session. Follow the intent (human input separate from generated work separate from the
deliverable) rather than creating empty directories to match the diagram.

**Benchmarks do not live here.** A skill's uplift benchmark belongs at `benchmarks/<skill-name>/` in the
repo you publish to, outside `skills/`, so it never ships on install. The build workspace holds the
*rubric* evaluation that steers the loop; those are different instruments — see
[tuning.md](tuning.md#two-questions-two-instruments).

### Keeping competing drafts: `output-<variant>/`

When a redesign might be better but you are not sure, keep both and let the measurement decide. Both
newest builds in this project did exactly that — one kept three parallel drafts (225, 138 and 169 lines)
and shipped the smallest after it scored equal or better; another kept a pre-premortem snapshot beside
the final. Name them `output-v2/`, `output-pre-premortem/`, whatever is descriptive. Delete the losers
once the decision is recorded in `craft-decisions.md`, so the winner is unambiguous.

### The two ledgers

- **`craft-decisions.md`** — every design decision and iteration, append-only. What was tried, what the
  metric said, what was kept. This is the audit trail for *this* build.
- **`improvement-notes.md`** — the lesson→improvement log that outlives the build: what went wrong, what
  it implies for the *skill's next version* or for the factory itself. This is what turns one build's
  scar tissue into a durable improvement instead of a rediscovery.

### `OPEN-QUESTIONS.md` and the drain

Questions the build cannot settle alone accumulate here rather than blocking. Periodically a human
**drains the queue**: for each question, decide whether the answer should become a durable principle or
rule in the skill. If it should, push it into `work/experiments/autoresearch.ideas.md`, and the next
Phase 4 run picks it up as a hypothesis and measures it.

That loop — open question → human decision → ideas backlog → measured iteration → rebaseline → publish —
is how a skill absorbs new knowledge without anyone hand-editing it. Treat those four steps as the
factory's run modes: **train** (a fresh build or improvement round), **drain** (codify open questions),
**rebaseline** (re-measure after the skill or rubric moved), and **publish**
(`.agents/skills/create-skill-autoresearch/references/publishing.md`).

## The three zones

### input/ — what you provide

Drop gold standards and study materials here in whatever structure is natural. You are **not**
asked to hand-author an index. During Phase 1 the factory scans `input/`, classifies each item
as a gold standard (exemplar input/output pair or reference artifact) vs a study material, and
writes its derived index to `work/manifest.yaml` for you to confirm or correct.

- Gold standards define "what good looks like" — the immutable benchmark. Never modified by autoresearch.
- Study materials are anything that helps the factory understand the domain (docs, code, transcripts, specs, style guides, an existing skill being upgraded).

### work/ — what the factory generates

The lab notebook. None of it ships.

**Four files here are yours to correct at phase boundaries**, even though the factory writes them
first: `manifest.yaml`, `evaluation/rubric.yaml` (which holds the exit criteria),
`evaluation/judges.yaml` and `evaluation/data-split.yaml`. Everything else is derived from those and
gets rewritten, so edit the inputs rather than the outputs. See [tuning.md](tuning.md).

**No credentials in any of these files.** `work/` is committed in the workspace's own git repository
(see [Git Tracking](#git-tracking)), so a key written into `judges.yaml` becomes a key in git history. Credentials belong in the environment.

Subdirectories:

- `manifest.yaml` — the factory's index of the gold standards found in `input/`, tagged train/validation/test.
- `research/` — Phase 2 notes from parallel subagent exploration. `00-synthesis.md` is the cross-cutting synthesis (read first); numbered notes correspond to study-material clusters.
- `evaluation/` — the scoring infrastructure: `rubric.yaml` (dimensions, weights, criteria, and the exit criteria `target_score`/`max_iterations`/`plateau_window`), `evaluate.sh` (the script autoresearch calls), the optional `evaluate-checks.sh` correctness gate, `judges.yaml` (judge models and weights — names only, never a credential), and `data-split.yaml` (which gold standards are training vs held out).
  Phase 3.6 adds `run-case.sh`, and Phase 5.0 writes the gate artifacts through the factory's bundled
  scripts — never by hand: `scripts/gate.py` (run as the owned job `gate`, started with `--detach` and
  awaited with `gate.py --wait`) picks the mode, runs the suite and writes `gate.json` plus
  `plugin-eval.json` or `uplift.json`; `scripts/check_gate.py` exits non-zero unless `gate.json` records a
  finished run whose hashes (skill, cases, `run-case.sh`, the scorer and fixture files under `input/` and
  `evaluation/`, the artifact) still match, at least one case is a gold case with a numeric delta, and that
  artifact is complete (`"partial": false`) and covers exactly the `plugin_eval` cases. Phase 5.2 does not
  start, and 5.4 writes no SHIP verdict, until it passes.
- `pids/` — one record per background job started with the factory's `scripts/run_owned.py` (pid,
  process group, supervisor pid, the leader's start time when `ps` can read it, command, log, exit
  code). Each job runs under a supervisor that holds `<name>.lock` while it lives; `run_owned.py stop
  <name>` writes `<name>.stop` and the supervisor stops only its own child group, so a build never stops
  another build's processes and nothing needs `ps`. Transient; `run_owned.py` writes a `.gitignore` of
  `*` here.
- `experiments/` — all experimentation artifacts: `DESIGN.md` (structural decisions locked before the first draft), `craft-decisions.md` (per-iteration ledger), `premortem.md` (the 5.1 risk list the panel tests), the autoresearch session files, and `run.log`.
- `handoffs/` — cross-session continuity (`state.yaml` for automatic resume, `HANDOFF-*.md` for rich human-readable context).

### output/ — what you get

The finished skill, in its own `<skill-name>/` directory so it is a real, copyable package.
This is the only zone that ships. To publish, copy `builds/<skill-name>/output/<skill-name>/`
straight into a skills repo's `skills/` directory (or install it with `npx skills`).

## What Ships vs What Stays

| Ships (installable)                       | Stays (process artifacts) |
|-------------------------------------------|---------------------------|
| `output/<name>/SKILL.md`                  | `input/`                  |
| `output/<name>/references/`               | `work/manifest.yaml`      |
| `output/<name>/scripts/`                  | `work/research/`          |
| `output/<name>/assets/`                   | `work/evaluation/`        |
|                                           | `work/experiments/`       |
|                                           | `work/handoffs/`          |

## Autoresearch Integration

Autoresearch runs from the **build workspace root** (`builds/<skill-name>/`). This means
`./work/evaluation/evaluate.sh` works as a relative path. Autoresearch session files land at
the workspace root during an active session and are archived to `work/experiments/` when the
session ends or on handoff.

| Session file at root | Written by | Archived to |
|----------------------|------------|-------------|
| `results.tsv` | upstream autoresearch | `work/experiments/results.tsv` |
| `run.log` | upstream autoresearch | `work/experiments/run.log` |
| `autoresearch.jsonl` | the factory | `work/experiments/autoresearch.jsonl` |
| `autoresearch.ideas.md` | the factory | `work/experiments/autoresearch.ideas.md` |

The upstream autoresearch skill keeps only `results.tsv` and `run.log`; the factory writes
`autoresearch.jsonl` and `autoresearch.ideas.md` itself and runs `work/evaluation/evaluate-checks.sh`
(when present) before every measurement — see the "Loop Conventions the Factory Owns" section of the
factory's `references/phase-4.md`.

`BENCHMARK.md` (final pass/fail scores for the shipped skill) is generated at the end of Phase 5
(Verify) and placed at `builds/<skill-name>/BENCHMARK.md`. It is a summary, not a process artifact.

## Git Tracking

Each build workspace is its own git repository, because the Phase 4 loop resets it (factory
SKILL.md 1.6). A workspace inside a parent project — `builds/` here, which this harness gitignores —
is gitignored by the parent, and its files are tracked in the workspace's own repository:

| File | Tracked? | Why |
|------|----------|-----|
| `input/**` | Yes | Immutable reference materials |
| `work/manifest.yaml` | Yes | Gold-standard index |
| `work/research/*.md` | Yes | Reproducible evidence |
| `work/evaluation/rubric.yaml` | Yes | Scoring definition |
| `work/evaluation/evaluate.sh` | Yes | Evaluation logic |
| `work/evaluation/judges.yaml` | Yes (if present) | Multi-judge config — **model names and weights only; a credential here would be committed** |
| `work/evaluation/data-split.yaml` | Yes | Split and gate cases; leave-one-out rotation commits it on its own so experiment reverts cannot roll it back |
| `work/evaluation/run-case.sh`, `gate.json`, `plugin-eval.json` / `uplift.json` | Yes | Gate adapter, record and evidence |
| `work/pids/*` | No | Transient process records |
| `work/experiments/DESIGN.md` | Yes | Design contract |
| `work/experiments/craft-decisions.md` | Yes | Iteration history |
| `work/experiments/autoresearch.jsonl` | No | Session-specific |
| `work/experiments/results.tsv` | No | Session-specific |
| `work/experiments/run.log` | No | Transient output |
| `output/**` | Yes | The deliverable |
| `work/handoffs/*` | Yes | Cross-session continuity |
| `BENCHMARK.md` | Yes | Final verification record |
