# I/O Contract

The one page that tells you what to put **in** and what you get **out** when you build a skill
with this harness. If you only read one reference, read this one.

A build is a single self-contained folder, `builds/<skill-name>/`, with three zones:
`input/` (you provide) → `work/` (the factory maintains) → `output/` (you receive). See
[workspace-layout.md](workspace-layout.md) for the full file-by-file layout. (`self-test/` is the
factory's own regression test and uses a separate evaluation layout, not the three-zone build layout.)

---

## INPUT — what you provide

Drop your materials into `builds/<skill-name>/input/` in **any** structure that's natural to you.
You do not author an index by hand — the factory scans `input/` during the interview and derives
the manifest for you to confirm.

| You provide | What it is | Required? |
|-------------|-----------|-----------|
| **Gold standards** | 3+ exemplars of "what good looks like": input/output pairs, reference artifacts, or previously solved tasks | **Yes** (min 3) |
| **Study materials** | Docs, code, transcripts, specs, style guides, an existing skill to upgrade | Recommended |
| **A judge** (env vars) | `JUDGE_MODEL`, `JUDGE_API_KEY`, `JUDGE_API_BASE` for an OpenAI-compatible endpoint — for *scoring text* | Optional — falls back to deterministic-only scoring |
| **An agent credential** (env vars) | `CLAUDE_CODE_OAUTH_TOKEN` or `ANTHROPIC_API_KEY` — for benchmark arms that *run an agent* | Optional — only for uplift benchmarks |

Gold standards are the benchmark; they are never modified during the build. Fewer than three is a
risk the factory will warn you about.

---

## CONTRACT — what the factory maintains in `work/`

The factory generates these, but they define the measurable bar, so they are part of the contract.
The first four are **yours to correct at the phase boundaries** — that is the intended workflow, not a
violation of the zone model. See [tuning.md](tuning.md) for what each knob does.

| Artifact | Purpose | Yours to edit? | Spec |
|----------|---------|----------------|------|
| `work/manifest.yaml` | Factory-derived index of your gold standards, tagged train/validation/test | **Yes** — confirm or correct during Phase 1 | |
| `work/evaluation/rubric.yaml` | Scored dimensions, weights, criteria, and the **exit criteria** (`target_score`, `max_iterations`, `plateau_window`) | **Yes** — any phase boundary | [rubric-format.md](rubric-format.md) · [tuning.md](tuning.md) |
| `work/evaluation/judges.yaml` | Judge models and weights. **Never a credential** | **Yes** — before Phase 4 | [tuning.md](tuning.md#models-and-credentials) |
| `work/evaluation/data-split.yaml` | Which gold standards are held out | **Yes** — before Phase 4 | |
| `work/evaluation/evaluate.sh` | Runs the skill on a case and emits measurements | No — derived; change the rubric and let it regenerate | [metric-protocol.md](metric-protocol.md) |

The evaluation contract in one line: `./work/evaluation/evaluate.sh <case-id>` prints
`METRIC <name>=<value>` lines to stdout, including a normalized `METRIC overall_score=<0.0–1.0>`
as the primary metric. That is the only interface the autoresearch loop needs.

---

## OUTPUT — what you get

| You receive | Where | Notes |
|-------------|-------|-------|
| **The finished skill** | `builds/<skill-name>/output/<skill-name>/` | `SKILL.md` (+ `references/`), in its own named dir — publish-ready |
| **The autoresearch journal** | `builds/<skill-name>/work/experiments/` | `results.tsv`, `autoresearch.jsonl`, `run.log` — inspectable record of every experiment |
| **The verification record** | `builds/<skill-name>/BENCHMARK.md` | Final panel pass/fail scores (Phase 5) |

To publish the result, copy the named skill dir straight into a skills repo:

```bash
cp -r builds/<skill-name>/output/<skill-name> <your-skills-repo>/skills/
```

or install it directly with `npx skills`.

---

## The flow at a glance

```
input/  ──►  [interview → research → draft → autoresearch → verify]  ──►  output/<skill-name>/
(you)              the factory works in work/                              (publish-ready)
```

The finished skill follows the official skill-authoring rules (the factory's Phase 3.3 checklist,
with `skill-creator` writing the draft): `name` ≤ 64 chars and free of reserved words,
a third-person `description` stating what + when, body < 500 lines, references one level deep.
