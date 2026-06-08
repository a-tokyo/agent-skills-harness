# Task-Decomposition Patterns

A task-decomposition workflow built as a distributed agent control plane (Elixir/OTP + Docker) that runs AI agents in isolated containers. Most relevant for: task decomposition, verification loops, model tiering, and the Plan-Critique-Validate gate.

## Architecture

Two orchestration layers:
1. **Composer pipeline** (7 stages): Context → Review → Research → Plan → Critique → Validate → Materialize
2. **Execution layer**: Units of Work (UoW) in Docker with verifiers and retry feedback

## Model Tiering (How Small Models Do Complex Work)

| Role | Model | Why |
|------|-------|-----|
| Repository review | Haiku | Cheap, bounded context |
| Knowledge research | Haiku | Same |
| Plan generation | Sonnet | Needs reasoning |
| Plan critique | Opus | Quality gate |
| Execution (UoW) | Haiku (default) | Verifiers catch errors; retry is cheap |

The trick: shrink scope per step so small models succeed, then verify with cheap automated checks.

## Verification Loop (Core Pattern)

```
Execute command in Docker
  → Collect output artifacts
  → Run verifier (exit_code, file_exists, content_contains, command)
  → Pass: advance to next UoW
  → Fail: increment attempt, inject failure reason, retry (up to 3)
```

On retry, the agent sees: "The previous attempt failed verification with reason: {reason}. Please analyze your previous work, fix the issues, and ensure verification passes."

Critical insight: retry feedback only works for AGENT steps. Non-agent commands retry identically.

## Plan-Critique-Validate Gate

Before any Docker execution spend:
1. **Planner** (Sonnet) generates `plan.json`
2. **Critic** (Opus) reviews: `{approved, issues, strengths, summary}`
3. **Validator** (Elixir) checks: schema, capabilities, agent/utility mixing, parallel sink, step count
4. If critic rejects: retry planning with merged critique (up to 3 times)

No execution without BOTH critic approval AND structural validation.

## MAGI Consensus (Designed but Not Implemented)

Three parallel personas: Melchior (scientist), Balthasar (DX), Caspar (pragmatist). 2/3 approval rule. Deferred in v1 plan.

## Key Patterns for the Factory

1. **Elixir owns workflow; LLMs are bounded stage workers** -- fixed pipeline, strict artifacts, deterministic validation between stages
2. **One agent per UoW; verifiers are separate** -- never mix do and verify
3. **Retry with injected failure reason** -- cheap self-correction without bigger models
4. **Plan → Critic → Validator gate** -- LLM quality + deterministic schema check before execution
5. **KB as executable policy** -- decomposition rules, verifier cookbook, tunable via eval loop
6. **Fix the right layer** -- oracle → environment → benchmark case → KB → prompt (don't prompt-mutate runtime bugs)
7. **Eval harness with goldens + G-Eval** -- continuous prompt improvement with regression checks
