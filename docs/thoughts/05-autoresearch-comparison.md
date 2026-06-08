# Autoresearch vs pi-autoresearch Comparison

Two implementations of the same core concept -- autonomous iterative experimentation loops. Both inspired by Karpathy's autoresearch.

## autoresearch (`.agents/skills/autoresearch/SKILL.md`)

**Author**: luiscantero
**Type**: Cursor agent skill (SKILL.md)
**Source**: https://github.com/karpathy/autoresearch (generalized)

### How it works:
- Interactive setup phase: goal, metric command, metric extraction, direction, scope, constraints, budget
- Creates a git branch (`autoresearch/<tag>`)
- Establishes baseline measurement
- Runs autonomous loop: THINK → EDIT → COMMIT → RUN → MEASURE → DECIDE → LOG
- Results tracked in `results.tsv` (tab-separated, 5 columns)
- Failed experiments reverted with `git reset --hard HEAD~1`
- Runs until budget exhausted or user interrupts

### Key properties:
- Git-native: every experiment is a commit, reverts are clean
- Fully autonomous once started (no pause to ask "should I continue?")
- Results log is append-only TSV
- Simplicity criterion: complexity must justify itself
- Crash recovery: attempt quick fix, amend commit, rerun; if unfixable after 2 attempts, revert

### Strengths:
- Clean, well-structured skill document
- Git-based experiment tracking (atomic commits, clean reverts)
- Works with any measurable metric
- Built-in experiment strategy (low-hanging fruit → informed → diversify → combine → simplify → radical)
- Portable across any programming task

### Weaknesses:
- Requires a single numeric metric command
- No built-in multi-judge or consensus mechanism
- No built-in support for LLM-as-judge evaluation
- The agent running the loop is also the one generating experiments (self-bias risk)

## pi-autoresearch (`docs/resources/pi-autoresearch`)

**Author**: davebcn87
**Type**: Git submodule (standalone tool)
**Source**: https://github.com/davebcn87/pi-autoresearch

### How it works:
- External tool that wraps the autoresearch loop
- Expects METRIC output from a runner script
- The structured-doc case study used it with custom generate.py + evaluate.py scripts

### Key properties:
- More tooling-oriented (scripts, not agent skill)
- Designed for programmatic metric extraction
- Used in the structured-doc case study with the `METRIC name=value` output protocol

### Strengths:
- Scriptable and automatable
- Works well with Python evaluation pipelines
- Clear METRIC protocol for integration

### Weaknesses:
- Less well-documented than autoresearch skill
- More opinionated about tooling

## Recommendation for the Factory

**Use autoresearch as the conceptual foundation, but extend it with:**

1. **LLM-as-judge evaluation**: add a standard way to define rubrics and use LLM judges
2. **Multi-judge consensus**: run 2-3 different LLM judges and aggregate scores
3. **Script-based metrics** (from pi-autoresearch / structured-doc case): support Python evaluation scripts alongside simple metric commands
4. **Fresh-context verification**: the verifier agent should NOT share context with the doer agent
5. **Devils advocate agent**: a dedicated contrarian verifier
6. **Plateau detection**: stop when N consecutive experiments fail to improve by more than judge variance
7. **Handoff support**: when context fatigues, generate a handoff document for the next session
