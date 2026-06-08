---
name: autoresearch
description: 'Autonomous iterative experimentation loop for any programming task. Guides the user through defining goals, measurable metrics, and scope constraints, then runs an autonomous loop of code changes, testing, measuring, and keeping/discarding results. Inspired by Karpathy''s autoresearch. USE FOR: autonomous improvement, iterative optimization, experiment loop, auto research, performance tuning, automated experimentation, hill climbing, try things automatically, optimize code, run experiments, autonomous coding loop. DO NOT USE FOR: one-shot tasks, simple bug fixes, code review, or tasks without a measurable metric.'
license: MIT
compatibility: Requires git. The project must be a git repository. Requires terminal access to run commands.
metadata:
  author: luiscantero
  enhanced-by: a-tokyo
  inspired-by: https://github.com/karpathy/autoresearch
  pi-autoresearch: https://github.com/davebcn87/pi-autoresearch
---

# Autoresearch: Autonomous Iterative Experimentation

An autonomous experimentation loop for any programming task. You define the goal and how to measure it; the agent iterates autonomously -- modifying code, running experiments, measuring results, and keeping or discarding changes -- until interrupted.

Inspired by [Karpathy's autoresearch](https://github.com/karpathy/autoresearch), enhanced with battle-tested patterns from [pi-autoresearch](https://github.com/davebcn87/pi-autoresearch).

---

## Agent Behavior Rules

1. **DO** guide the user through the Setup phase interactively before starting the loop.
2. **DO** establish a baseline measurement before making any changes.
3. **DO** use the METRIC protocol for all measurements.
4. **DO** keep structured logs: `autoresearch.jsonl` (machine) + `results.tsv` (human).
5. **DO** record ASI fields (hypothesis, learned, rollback_reason) on every experiment.
6. **DO** commit before running, revert on failure -- only kept commits remain on the branch.
7. **DO** run autonomously once the loop starts -- never pause to ask "should I continue?".
8. **DO** run checks (if `autoresearch.checks.sh` exists) before measuring.
9. **DO NOT** modify files the user marked as out-of-scope.
10. **DO NOT** skip the measurement step -- every experiment must be measured.
11. **DO NOT** keep changes that regress the metric unless the user explicitly allowed trade-offs.
12. **DO NOT** install new dependencies or make environment changes unless the user approved it.

---

## Phase 1: Setup (Interactive)

Before any experimentation begins, work with the user to establish these parameters.
Ask the user directly for each item. Do not assume or skip any.

### 1.1 Define the Goal

Ask the user:

> **What are you trying to improve or optimize?**
>
> Examples: execution time, memory usage, binary size, test pass rate, code coverage,
> API response latency, throughput, error rate, benchmark score, build time, bundle size,
> LLM output quality, prompt effectiveness, skill accuracy, etc.

Record the user's answer as the **goal**.

### 1.2 Define the Metric

Ask the user:

> **How do we measure success? What exact command produces the metric?**
>
> I need:
> 1. **The command** to run (e.g., `./evaluate.sh`, `npm run benchmark`, `pytest --tb=short`)
> 2. **Metric output format**: The command must print `METRIC name=value` lines to stdout.
>    Example output: `METRIC quality_score=8.33`
> 3. **Primary metric name**: Which METRIC name is the main optimization target?
> 4. **Direction**: Is lower better or higher better?
>
> If your command doesn't emit METRIC lines yet, I can help you wrap it.

Record:
- `METRIC_COMMAND`: the command to run
- `PRIMARY_METRIC`: the name of the primary metric (e.g., `quality_score`)
- `METRIC_DIRECTION`: `lower_is_better` or `higher_is_better`

### 1.3 Define the Scope

Ask the user:

> **Which files or directories am I allowed to modify?**
>
> And which files are OFF LIMITS (read-only)?

Record:
- `IN_SCOPE_FILES`: files/dirs the agent may edit
- `OUT_OF_SCOPE_FILES`: files/dirs that must not be modified

### 1.4 Define Constraints

Ask the user:

> **Are there any constraints I should respect?**
>
> Examples:
> - Time budget per experiment (e.g., "each run should take < 2 minutes")
> - No new dependencies
> - Must keep all existing tests passing
> - Must not change the public API
> - Must maintain backward compatibility
> - VRAM/memory limit
> - Code complexity limits (prefer simpler solutions)

Record as `CONSTRAINTS`.

### 1.5 Define the Experiment Budget

Ask the user:

> **How many experiments should I run, or should I just keep going until you stop me?**
>
> You can say a number (e.g., "try 20 experiments") or "unlimited" (I'll run until you interrupt).

Record as `MAX_EXPERIMENTS` (number or `unlimited`).

### 1.6 Simplicity Criterion

Inform the user of the default simplicity policy:

> **Simplicity policy (default):** All else being equal, simpler is better. A small improvement
> that adds ugly complexity is not worth it. Removing code while maintaining or improving
> the metric is a great outcome. I'll weigh the complexity cost against the improvement
> magnitude. Does this policy work for you, or do you want to adjust it?

Record any adjustments as `SIMPLICITY_POLICY`.

### 1.7 Optional: Correctness Gate

Ask the user:

> **Is there a correctness check that must pass before I measure the metric?**
>
> For example: lint checks, type checks, test suites, syntax validation.
> If yes, I'll create an `autoresearch.checks.sh` script that must exit 0
> before any metric measurement. Failed checks = experiment treated as crash.

If yes, create `autoresearch.checks.sh` with the specified checks.

### 1.8 Confirm Setup and Write Session Contract

Summarize all parameters back to the user in a clear table:

| Parameter          | Value                        |
| ------------------ | ---------------------------- |
| Goal               | ...                          |
| Metric command     | ...                          |
| Primary metric     | ...                          |
| Direction          | lower is better / higher ... |
| In-scope files     | ...                          |
| Out-of-scope files | ...                          |
| Constraints        | ...                          |
| Max experiments    | ...                          |
| Simplicity policy  | ...                          |
| Checks script      | yes / no                    |

Ask the user to confirm. Do not proceed until confirmed.

Once confirmed, write the **session contract** file `autoresearch.md` in the workspace:

```markdown
# Autoresearch Session

- **Goal**: <goal>
- **Primary metric**: <PRIMARY_METRIC> (<METRIC_DIRECTION>)
- **Metric command**: `<METRIC_COMMAND>`
- **Checks command**: `./autoresearch.checks.sh` (or "none")
- **Budget**: <MAX_EXPERIMENTS> experiments
- **Branch**: autoresearch/<tag>
- **In-scope**: <IN_SCOPE_FILES>
- **Out-of-scope**: <OUT_OF_SCOPE_FILES>
- **Constraints**: <CONSTRAINTS>
- **Simplicity**: <SIMPLICITY_POLICY>
- **Started**: <ISO timestamp>
```

---

## Phase 2: Branch & Baseline

Once the user confirms:

1. **Create a branch**: Propose a tag based on today's date (e.g., `autoresearch/may30`).
   Create the branch: `git checkout -b autoresearch/<tag>`.

2. **Read in-scope files**: Read all files that are in scope to build full context.

3. **Initialize tracking files**: Create in the workspace root:
   - `results.tsv` with the header: `experiment\tcommit\tmetric\tstatus\tdescription`
   - `autoresearch.jsonl` (empty, will be appended to)
   Add `results.tsv`, `run.log`, `autoresearch.jsonl`, and `autoresearch.md` to `.git/info/exclude` so they stay untracked.

4. **Run the baseline**: Execute the metric command on the current unmodified code.
   Record the result as experiment `0` with status `baseline`.
   Log the baseline to both `results.tsv` and `autoresearch.jsonl`.

5. **Report baseline** to the user:
   > Baseline established: **[PRIMARY_METRIC] = [value]**
   > Starting autonomous experimentation loop.

---

## Phase 3: Experiment Loop

Run this loop continuously. Do not stop to ask the user. Run until:
- `MAX_EXPERIMENTS` is reached, OR
- The user manually interrupts, OR
- Plateau detected (see below)

### For each experiment:

```
LOOP:
  1. THINK   - Analyze previous results, ASI from past experiments, and current code.
               Generate a hypothesis: "I believe <change> will improve <metric> because <reason>."
               Check autoresearch.ideas.md for queued hypotheses.
               Consider: what worked, what didn't, what hasn't been tried.

  2. EDIT    - Modify the in-scope file(s) to implement the hypothesis.
               Keep changes focused and minimal per experiment.

  3. COMMIT  - Stage and commit before running:
               `git add <in-scope-files> && git commit -m "experiment N: <description>"`
               This ensures every experiment has a clean revert point.

  4. RUN     - If autoresearch.checks.sh exists, run it first.
               If checks FAIL: log status = "checks_failed", revert commit
               (`git reset --hard HEAD~1 && git clean -fd -e 'autoresearch.*' -e 'results.tsv' -e 'run.log'`),
               skip to LOG.
               If checks PASS (or no checks): execute the metric command.
               Redirect output to run.log: `<command> > run.log 2>&1`

  5. MEASURE - Parse METRIC lines from run.log.
               Extract PRIMARY_METRIC value. Record all secondary metrics.
               If extraction fails (crash/error), read the last 50 lines
               of run.log for diagnostics.

  6. DECIDE  - Compare PRIMARY_METRIC to the current best:
               - KEEP: Metric improved AND improvement exceeds noise threshold.
                 Noise threshold = max(0.01, 1.0 × MAD of recent kept scores).
                 Use the last 5 kept experiments for MAD; if < 3 kept, use 0.01.
                 Improvements within noise are treated as DISCARD.
                 Update the "best" baseline. Log status = "keep".
               - DISCARD: Metric same, worse, or improved within noise. Revert:
                 `git reset --hard HEAD~1 && git clean -fd -e 'autoresearch.*' -e 'results.tsv' -e 'run.log'`
                 Log status = "discard".
               - CRASH: Metric extraction failed or runtime error.
                 Attempt a quick fix (typo, import, simple error).
                 If fixed, amend the commit (`git commit --amend`) and rerun from step 4.
                 If unfixable after 2 attempts, revert (same as DISCARD)
                 and log status = "crash".

  7. LOG     - Append to results.tsv:
                 experiment_number  commit_hash  metric_value  status  description
               Append to autoresearch.jsonl (one JSON object per line):
                 {
                   "experiment": N,
                   "status": "keep|discard|crash|checks_failed|baseline",
                   "hypothesis": "<what we thought would improve>",
                   "primary_metric": <value>,
                   "secondary_metrics": { "<name>": <value>, ... },
                   "commit": "<hash or null>",
                   "description": "<what changed>",
                   "learned": "<insight that survives revert>",
                   "rollback_reason": "<why discarded, if discarded>",
                   "next_action_hint": "<what to try next>",
                   "confidence": <MAD ratio or null>,
                   "timestamp": "<ISO timestamp>"
                 }
               If a hypothesis was deferred, append it to autoresearch.ideas.md.

  8. CONTINUE - Check plateau. Go to step 1.
```

### METRIC Protocol

The metric command MUST print lines in this format to stdout:

```
METRIC <name>=<value>
```

Rules:
- One METRIC per line, at line start
- Names: `[\w.]+` (alphanumeric, underscores, dots)
- Values: finite numbers (integers or floats)
- The PRIMARY_METRIC name must appear in the output
- Additional metrics are tracked as secondary (for tradeoff visibility)

Examples:
```
METRIC quality_score=8.33
METRIC structure=9.0
METRIC coverage=7.5
METRIC latency_ms=142
```

### ASI (Actionable Side Information)

Every experiment log entry in `autoresearch.jsonl` MUST include these fields:

- **hypothesis**: What we believed would improve the metric and why
- **learned**: The key insight from this experiment (survives revert)
- **rollback_reason**: Why the experiment was discarded (null if kept)
- **next_action_hint**: What to try next based on this result

ASI is the ONLY structured memory that survives a git revert. It prevents the agent from repeating failed approaches and builds cumulative knowledge across the session.

### Experiment Strategy

When generating experiment ideas, follow this priority order:

1. **Low-hanging fruit first**: Simple parameter tweaks, obvious inefficiencies.
2. **Informed by ASI**: Read `learned` and `next_action_hint` from past experiments.
3. **Check the ideas backlog**: Review `autoresearch.ideas.md` for queued hypotheses.
4. **Diversify after plateaus**: If the last 3-5 experiments all failed, try a different approach.
5. **Combine winners**: If experiments A and B each improved independently, try combining them.
6. **Simplification passes**: Periodically try removing code/complexity to see if the metric holds.
7. **Radical changes**: After exhausting incremental ideas, try larger architectural changes.

### Plateau Detection

Track a sliding window of the last `PLATEAU_WINDOW` experiments (default: 5).
If ALL experiments in the window were discarded (no improvement), check whether the plateau is within measurement noise using confidence scoring (see below).

Report:

> **Plateau detected** after [N] consecutive failed experiments.
> Best score: [value]. Confidence: [ratio]x MAD.
> Consider:
> 1. Trying a fundamentally different approach
> 2. Reviewing the ideas backlog for untried directions
> 3. Stopping if confidence is high (improvements may be at measurement ceiling)

Continue if budget remains, but shift strategy to radical changes.

### Confidence Scoring (MAD)

For noisy metrics (benchmarks with variance between runs), track confidence using Median Absolute Deviation:

1. Collect all primary metric values from the current session (kept + discarded, excluding crashes)
2. Compute the median of all values
3. Compute MAD = median of absolute deviations from the median
4. Confidence ratio = |best_kept - baseline| / MAD

Interpretation:
- **>= 2.0x MAD**: Improvement is likely real (high confidence)
- **1.0-2.0x MAD**: Above noise but marginal (medium confidence)
- **< 1.0x MAD**: Within noise -- consider re-running or treating as no improvement

The logged `confidence` ratio is **advisory** -- it provides interpretive context but does not override the binding noise threshold in DECIDE (which uses the same MAD stats). The DECIDE gate is the binding rule; confidence is for human/agent reasoning about result reliability.

For metrics with zero variance (deterministic), confidence is null and the noise threshold falls back to the 0.01 absolute minimum.

### Handling Constraints

- **Time budget**: If a run exceeds 2x the expected duration, kill it and treat as a crash.
- **Existing tests**: If constraints require tests to pass, include them in `autoresearch.checks.sh`.
- **Memory/resources**: Monitor and revert if resource usage exceeds stated limits.

### Resume After Interrupt

If the session was interrupted (context limit, user stop, crash):

1. Read `autoresearch.md` to re-establish goal, metric, scope, and constraints
2. Read the tail of `autoresearch.jsonl` to reconstruct current state:
   - Last experiment number
   - Best score and commit
   - Recent ASI (`learned`, `next_action_hint`) from the last few experiments
3. Run `git log --oneline` on the autoresearch branch to see kept experiments
4. Check `autoresearch.ideas.md` for queued hypotheses
5. Resume the loop from the next experiment number

### Context Budget Awareness

Each experiment consumes context. To avoid degradation:
- **Track context usage**: After ~15 experiments in one session, proactively handoff
  rather than waiting for quality to degrade from context saturation
- **Minimize resume payload**: When resuming, read only `autoresearch.md` (config),
  the last 5 entries from `autoresearch.jsonl` (recent ASI), `autoresearch.ideas.md`,
  and `results.tsv` summary. Do NOT reload all research, gold standards, or full
  experiment history into context
- **Prefer small diffs**: Summarize prior experiments rather than replaying them.
  The JSONL `learned` and `next_action_hint` fields carry the signal without the bulk

---

## Phase 4: Reporting

When the loop ends (budget reached, user interrupts, or plateau):

1. **Print the full results.tsv** as a formatted table.
2. **Summarize**:
   - Total experiments run
   - Experiments kept / discarded / crashed
   - Starting metric (baseline) vs. final metric
   - Improvement percentage
   - Top 3 most impactful changes (from kept experiments)
   - Key learnings (aggregated from ASI `learned` fields)
3. **Show the cumulative git log** of kept experiments:
   `git log --oneline <start_commit>..HEAD`
4. **Recommend next steps**: Based on ASI and results, suggest what to try next.
5. **Ideas backlog**: Print any remaining items from `autoresearch.ideas.md`.

---

## Quick Reference

### METRIC Line Format

```
METRIC <name>=<value>    # one per line, at line start
METRIC quality_score=8.33
METRIC structure=9.0
```

Names: `[\w.]+`, values: finite numbers. Primary metric named in session config.

### Results TSV Format

Tab-separated, 5 columns:

```
experiment	commit	metric	status	description
0	a1b2c3d	0.997900	baseline	unmodified code
1	b2c3d4e	0.993200	keep	increase learning rate to 0.04
2	-	1.005000	discard	switch to GeLU activation
3	-	0.000000	crash	double model width (OOM)
```

### autoresearch.jsonl Format

One JSON object per line. Status values: `baseline`, `keep`, `discard`, `crash`, `checks_failed`. Each entry contains: `experiment`, `status`, `hypothesis`, `primary_metric`, `secondary_metrics`, `commit`, `description`, `learned`, `rollback_reason`, `next_action_hint`, `confidence`, `timestamp`.

### Session Artifacts

| File | Purpose | Tracked in git? |
|------|---------|-----------------|
| `autoresearch.md` | Session contract (goal, config) | No (.git/info/exclude) |
| `autoresearch.jsonl` | Machine log with ASI | No (.git/info/exclude) |
| `results.tsv` | Human-readable results journal | No (.git/info/exclude) |
| `autoresearch.checks.sh` | Correctness gate (optional) | Yes (committed) |
| `autoresearch.ideas.md` | Deferred hypothesis backlog | No (.git/info/exclude) |
| `run.log` | Last command output | No (.git/info/exclude) |

### Git Workflow (Commit-First Model)

- All experiments happen on the `autoresearch/<tag>` branch
- Every experiment is committed BEFORE running (clean revert point)
- **Commit**: `git add <in-scope-files> && git commit -m "experiment N: <description>"`
  Only stage in-scope files. Never `git add -A` (risks staging out-of-scope changes).
- **KEEP**: Commit stays. Branch advances.
- **DISCARD**: `git reset --hard HEAD~1 && git clean -fd -e 'autoresearch.*' -e 'results.tsv' -e 'run.log'`
- **CRASH**: Attempt fix + amend; if unfixable, same revert as DISCARD
- **CHECKS_FAILED**: Same revert as DISCARD (revert before measuring)
- Session artifacts stay untracked (added to `.git/info/exclude`)

### Key Principles

1. **Measure everything**: No experiment without a measurement.
2. **METRIC protocol**: All measurements use `METRIC name=value` format.
3. **ASI survives reverts**: Log hypothesis + learned even on discard.
4. **Revert failures**: The branch only advances on improvements.
5. **Stay autonomous**: Never stop to ask. Think harder if stuck.
6. **Keep it simple**: Complexity is a cost. Weigh it against gains.
7. **Log everything**: JSONL is the machine journal, TSV is the human journal.
