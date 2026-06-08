#!/bin/bash
# autoresearch-evaluate.sh -- Evaluate the FACTORY ITSELF (create-skill-autoresearch) using
# deterministic structural checks and cross-file consistency verification.
# (To score a factory-PRODUCED skill against a gold standard instead, see evaluate.sh.)
#
# This evaluates the create-skill-autoresearch factory and its ecosystem:
# - SKILL.md structural quality
# - Cross-reference integrity
# - Convention compliance
# - Internal consistency
# - Completeness against known requirements

set -euo pipefail

# Resolve the repo root so this runs correctly from any working directory.
cd "$(dirname "$0")/../.."

FACTORY_SKILL=".agents/skills/create-skill-autoresearch/SKILL.md"
AUTORESEARCH_SKILL=".agents/skills/autoresearch/SKILL.md"
PIPELINE_REF=".agents/skills/create-skill-autoresearch/references/pipeline-phases.md"
CONSENSUS_REF=".agents/skills/create-skill-autoresearch/references/consensus-protocol.md"
RUBRIC_REF=".agents/skills/create-skill-autoresearch/references/rubric-templates.md"
WORKSPACE_DOC="docs/reference/workspace-layout.md"
METRIC_DOC="docs/reference/metric-protocol.md"
RUBRIC_DOC="docs/reference/rubric-format.md"

score_structural=0
score_crossref=0
score_consistency=0
score_completeness=0
score_clarity=0
score_depth=0
score_robustness=0
total_checks=0
passed_checks=0
issues=""

check() {
  local dim="$1" desc="$2" result="$3"
  total_checks=$((total_checks + 1))
  if [ "$result" -eq 1 ]; then
    passed_checks=$((passed_checks + 1))
    eval "score_${dim}=\$((score_${dim} + 1))"
  else
    issues="${issues}\nFAIL: [${dim}] ${desc}"
  fi
}

# ============================================================================
# STRUCTURAL QUALITY (convention compliance)
# ============================================================================
dim_structural_max=0

# Factory SKILL.md checks
FACTORY_LINES=$(wc -l < "$FACTORY_SKILL")
dim_structural_max=$((dim_structural_max + 1))
check structural "Factory SKILL.md < 500 lines (actual: $FACTORY_LINES)" $([ "$FACTORY_LINES" -lt 500 ] && echo 1 || echo 0)

dim_structural_max=$((dim_structural_max + 1))
check structural "Factory has YAML frontmatter" $(head -1 "$FACTORY_SKILL" | grep -qc "^---" && echo 1 || echo 0)

dim_structural_max=$((dim_structural_max + 1))
check structural "Factory has name field" $(grep -qc "^name:" "$FACTORY_SKILL" && echo 1 || echo 0)

dim_structural_max=$((dim_structural_max + 1))
check structural "Factory has description field" $(grep -qc "^description:" "$FACTORY_SKILL" && echo 1 || echo 0)

# Autoresearch SKILL.md checks
AR_LINES=$(wc -l < "$AUTORESEARCH_SKILL")
dim_structural_max=$((dim_structural_max + 1))
check structural "Autoresearch SKILL.md < 500 lines (actual: $AR_LINES)" $([ "$AR_LINES" -lt 500 ] && echo 1 || echo 0)

dim_structural_max=$((dim_structural_max + 1))
check structural "Autoresearch has YAML frontmatter" $(head -1 "$AUTORESEARCH_SKILL" | grep -qc "^---" && echo 1 || echo 0)

# ============================================================================
# CROSS-REFERENCE INTEGRITY
# ============================================================================
dim_crossref_max=0

# Check factory references resolve
for ref in "references/pipeline-phases.md" "references/rubric-templates.md" "references/consensus-protocol.md"; do
  dim_crossref_max=$((dim_crossref_max + 1))
  FULL_PATH=".agents/skills/create-skill-autoresearch/$ref"
  check crossref "Factory ref $ref exists" $([ -f "$FULL_PATH" ] && echo 1 || echo 0)
done

# Check docs cross-refs
dim_crossref_max=$((dim_crossref_max + 1))
check crossref "workspace-layout.md exists" $([ -f "$WORKSPACE_DOC" ] && echo 1 || echo 0)

dim_crossref_max=$((dim_crossref_max + 1))
check crossref "metric-protocol.md exists" $([ -f "$METRIC_DOC" ] && echo 1 || echo 0)

dim_crossref_max=$((dim_crossref_max + 1))
check crossref "rubric-format.md exists" $([ -f "$RUBRIC_DOC" ] && echo 1 || echo 0)

dim_crossref_max=$((dim_crossref_max + 1))
check crossref "self-test/evaluation/evaluate.sh exists" $([ -f "self-test/evaluation/evaluate.sh" ] && echo 1 || echo 0)

# ============================================================================
# CONSISTENCY (cross-file agreement)
# ============================================================================
dim_consistency_max=0

# Git model consistency
dim_consistency_max=$((dim_consistency_max + 1))
DECIDE_FIRST_COUNT=$( (grep -ri "decide.first" .agents/skills/create-skill-autoresearch/ .agents/skills/autoresearch/ 2>/dev/null || true) | wc -l | tr -d ' ')
check consistency "No decide-first references in skills" $([ "$DECIDE_FIRST_COUNT" -eq 0 ] && echo 1 || echo 0)

dim_consistency_max=$((dim_consistency_max + 1))
GIT_ADD_A_BAD=$(grep -c "git add -A" "$AUTORESEARCH_SKILL" 2>/dev/null || echo 0)
GIT_ADD_A_WARNING=$(grep -c "Never.*git add -A" "$AUTORESEARCH_SKILL" 2>/dev/null || echo 0)
check consistency "git add -A only in warning context" $([ "$GIT_ADD_A_BAD" -le "$GIT_ADD_A_WARNING" ] && echo 1 || echo 0)

dim_consistency_max=$((dim_consistency_max + 1))
REJECT_COUNT=$( (grep -ri '"REJECT"\|REJECT}' .agents/skills/create-skill-autoresearch/ 2>/dev/null || true) | wc -l | tr -d ' ')
check consistency "No REJECT as panel outcome in factory (should be BLOCK)" $([ "$REJECT_COUNT" -eq 0 ] && echo 1 || echo 0)

# Formula consistency
dim_consistency_max=$((dim_consistency_max + 1))
FORMULA_RUBRIC=$(grep -c "dimension_score / scale_max \* weight" "$RUBRIC_REF" 2>/dev/null || echo 0)
check consistency "Normalized formula in rubric-templates" $([ "$FORMULA_RUBRIC" -ge 1 ] && echo 1 || echo 0)

dim_consistency_max=$((dim_consistency_max + 1))
FORMULA_DOC=$(grep -c "dimension_score / scale_max \* weight" "$RUBRIC_DOC" 2>/dev/null || echo 0)
check consistency "Normalized formula in rubric-format" $([ "$FORMULA_DOC" -ge 1 ] && echo 1 || echo 0)

dim_consistency_max=$((dim_consistency_max + 1))
FORMULA_CONSENSUS=$(grep -c "dimension_consensus / scale_max \* weight" "$CONSENSUS_REF" 2>/dev/null || echo 0)
check consistency "Normalized formula in consensus-protocol" $([ "$FORMULA_CONSENSUS" -ge 1 ] && echo 1 || echo 0)

# KEEP threshold
dim_consistency_max=$((dim_consistency_max + 1))
NOISE_THRESHOLD=$(grep -c "noise threshold" "$AUTORESEARCH_SKILL" 2>/dev/null || echo 0)
check consistency "KEEP decision has noise threshold" $([ "$NOISE_THRESHOLD" -ge 1 ] && echo 1 || echo 0)

# Context budget
dim_consistency_max=$((dim_consistency_max + 1))
CONTEXT_BUDGET=$(grep -c "Context Budget" "$AUTORESEARCH_SKILL" 2>/dev/null || echo 0)
check consistency "Autoresearch has context budget guidance" $([ "$CONTEXT_BUDGET" -ge 1 ] && echo 1 || echo 0)

# Devil's Advocate spelling
dim_consistency_max=$((dim_consistency_max + 1))
DEVILS_WRONG=$( (grep -r "Devils Advocate" "$FACTORY_SKILL" "$PIPELINE_REF" "$CONSENSUS_REF" 2>/dev/null || true) | wc -l | tr -d ' ')
check consistency "No misspelled Devils Advocate" $([ "$DEVILS_WRONG" -eq 0 ] && echo 1 || echo 0)

# ============================================================================
# COMPLETENESS (required sections present)
# ============================================================================
dim_completeness_max=0

# Factory phases
for phase in "Phase 1" "Phase 2" "Phase 3" "Phase 4" "Phase 5"; do
  dim_completeness_max=$((dim_completeness_max + 1))
  check completeness "Factory has $phase" $(grep -qc "$phase" "$FACTORY_SKILL" && echo 1 || echo 0)
done

# Key concepts present in factory
for concept in "gold standard" "rubric" "evaluate.sh" "autoresearch" "consensus" "premortem" "handoff"; do
  dim_completeness_max=$((dim_completeness_max + 1))
  check completeness "Factory mentions '$concept'" $(grep -qic "$concept" "$FACTORY_SKILL" && echo 1 || echo 0)
done

# Key concepts in autoresearch
for concept in "METRIC" "baseline" "plateau" "JSONL" "results.tsv" "autoresearch.checks.sh" "git reset"; do
  dim_completeness_max=$((dim_completeness_max + 1))
  check completeness "Autoresearch mentions '$concept'" $(grep -qc "$concept" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)
done

# Overfitting detection
dim_completeness_max=$((dim_completeness_max + 1))
check completeness "Factory has overfitting detection" $(grep -qic "overfitting" "$FACTORY_SKILL" && echo 1 || echo 0)

dim_completeness_max=$((dim_completeness_max + 1))
check completeness "Factory has leave-one-out overfitting" $(grep -qic "leave-one-out.*overfitting\|overfitting.*leave-one-out\|per-case.*variance" "$FACTORY_SKILL" && echo 1 || echo 0)

# LLM system prompt guidance
dim_completeness_max=$((dim_completeness_max + 1))
check completeness "Factory explains skill invocation as LLM prompt" $(grep -qic "system prompt\|LLM.*system\|SKILL.md as.*prompt" "$FACTORY_SKILL" && echo 1 || echo 0)

# ============================================================================
# CLARITY (actionability for a naive agent)
# ============================================================================
dim_clarity_max=0

# Has concrete examples
dim_clarity_max=$((dim_clarity_max + 1))
YAML_BLOCKS=$(grep -c '```yaml' "$FACTORY_SKILL" 2>/dev/null || echo 0)
check clarity "Factory has YAML examples (actual: $YAML_BLOCKS)" $([ "$YAML_BLOCKS" -ge 2 ] && echo 1 || echo 0)

dim_clarity_max=$((dim_clarity_max + 1))
BASH_BLOCKS=$(grep -c '```bash\|```sh' "$PIPELINE_REF" 2>/dev/null || echo 0)
check clarity "Pipeline ref has bash examples (actual: $BASH_BLOCKS)" $([ "$BASH_BLOCKS" -ge 2 ] && echo 1 || echo 0)

# Has tables for quick reference
dim_clarity_max=$((dim_clarity_max + 1))
TABLES=$(grep -c "^|" "$FACTORY_SKILL" 2>/dev/null || echo 0)
check clarity "Factory uses tables (actual: $TABLES rows)" $([ "$TABLES" -ge 5 ] && echo 1 || echo 0)

# Progressive disclosure
dim_clarity_max=$((dim_clarity_max + 1))
REF_LINKS=$(grep -c "\[references/" "$FACTORY_SKILL" 2>/dev/null || echo 0)
check clarity "Factory uses progressive disclosure (ref links: $REF_LINKS)" $([ "$REF_LINKS" -ge 2 ] && echo 1 || echo 0)

# Phase sequence is clear
dim_clarity_max=$((dim_clarity_max + 1))
check clarity "Phases are numbered sequentially" $(grep -q "## Phase 1" "$FACTORY_SKILL" && grep -q "## Phase 5" "$FACTORY_SKILL" && echo 1 || echo 0)

# ============================================================================
# DEPTH (deeper quality signals beyond structural correctness)
# ============================================================================
dim_depth_max=0

# Does factory explain what to do when 0 gold standards?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory handles 0 gold standards" $(grep -qic "synthetic\|create.*examples\|generate.*examples" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does factory mention cost/budget awareness for evaluation?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory has cost awareness for large gold standard sets" $(grep -qc "cost.*evaluat\|evaluat.*cost\|sampling.*strategy\|100+" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch mention what happens at experiment 0 if baseline fails?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch handles baseline failure" $(grep -qic "baseline.*fail\|fail.*baseline\|metric command fails\|command.*fail" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory explain how evaluate.sh runs the skill? (the critical invocation gap)
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory evaluate.sh shows LLM invocation mechanism" $(grep -qc "curl\|API.*call\|sdk\|programmatic" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch explain what to do when metric variance is high?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch addresses judge variance" $(grep -qic "variance\|MAD\|noise" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory have line budget warning (< 500 tight margin)?
dim_depth_max=$((dim_depth_max + 1))
FACTORY_LINES=$(wc -l < "$FACTORY_SKILL")
check depth "Factory SKILL.md has > 25 line margin (actual: $((500 - FACTORY_LINES)))" $([ "$((500 - FACTORY_LINES))" -ge 25 ] && echo 1 || echo 0)

# Is there guidance on minimum improvement for LLM-judge metrics?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch documents min improvement threshold" $(grep -qc "0\.01\|absolute minimum\|noise threshold" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory address model diversity for panel?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory mentions model diversity for panel" $(grep -qic "different model\|model family\|model diversity" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch have plateau window config?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch has configurable plateau window" $(grep -qc "plateau_window\|PLATEAU_WINDOW" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory reference the self-test?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory references self-test evaluate.sh" $(grep -qc "self-test" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does consensus protocol have anti-patterns section?
dim_depth_max=$((dim_depth_max + 1))
check depth "Consensus protocol has anti-patterns" $(grep -qc "Anti-Pattern" "$CONSENSUS_REF" && echo 1 || echo 0)

# Does factory have resume protocol?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory has resume/handoff protocol" $(grep -qic "resume\|handoff" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch explain ideas backlog?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch explains ideas backlog" $(grep -qc "autoresearch.ideas.md" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# ============================================================================
# ROBUSTNESS (Opus failure scenarios + edge cases)
# ============================================================================
dim_robustness_max=0

# Does autoresearch handle baseline failure gracefully?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Autoresearch handles baseline measurement failure" $(grep -qc "baseline.*fail\|If.*metric.*fail\|cannot.*baseline\|fails.*exit" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory address what happens when LLM API is unavailable?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Factory addresses LLM API unavailability" $(grep -qic "fallback\|unavailable\|fail.*graceful\|deterministic.*only\|without.*LLM" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch explain untracked file cleanup?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Autoresearch uses git clean on revert" $(grep -qc "git clean" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory explain ITERATE → re-autoresearch flow?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Factory has ITERATE feedback loop back to autoresearch" $(grep -qic "ITERATE.*autoresearch\|Return to Phase 4\|feed.*feedback" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch handle experiment budget exhaustion?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Autoresearch handles budget exhaustion" $(grep -qc "MAX_EXPERIMENTS\|budget.*reached\|budget.*exhaust" "$AUTORESEARCH_SKILL" && echo 1 || echo 0)

# Does factory handle deadlock in consensus?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Factory handles panel deadlock" $(grep -qic "deadlock\|escalate.*user" "$FACTORY_SKILL" && echo 1 || echo 0)

# ============================================================================
# SCORING
# ============================================================================

calc_score() {
  local score=$1 max=$2
  if [ "$max" -eq 0 ]; then echo "0"; return; fi
  python3 -c "print(round($score / $max * 10, 1))"
}

S_STRUCTURAL=$(calc_score $score_structural $dim_structural_max)
S_CROSSREF=$(calc_score $score_crossref $dim_crossref_max)
S_CONSISTENCY=$(calc_score $score_consistency $dim_consistency_max)
S_COMPLETENESS=$(calc_score $score_completeness $dim_completeness_max)
S_CLARITY=$(calc_score $score_clarity $dim_clarity_max)
S_DEPTH=$(calc_score $score_depth $dim_depth_max)
S_ROBUSTNESS=$(calc_score $score_robustness $dim_robustness_max)

# Weighted overall (normalized 0-1)
OVERALL=$(python3 -c "
s = $S_STRUCTURAL; c = $S_CROSSREF; cn = $S_CONSISTENCY; cp = $S_COMPLETENESS; cl = $S_CLARITY; d = $S_DEPTH; r = $S_ROBUSTNESS
overall = (s*0.08 + c*0.08 + cn*0.17 + cp*0.17 + cl*0.12 + d*0.20 + r*0.18) / 10
print(round(overall, 4))
")

echo "METRIC structural=$S_STRUCTURAL"
echo "METRIC crossref=$S_CROSSREF"
echo "METRIC consistency=$S_CONSISTENCY"
echo "METRIC completeness=$S_COMPLETENESS"
echo "METRIC clarity=$S_CLARITY"
echo "METRIC depth=$S_DEPTH"
echo "METRIC robustness=$S_ROBUSTNESS"
echo "METRIC overall_score=$OVERALL"
echo "METRIC checks_passed=$passed_checks"
echo "METRIC checks_total=$total_checks"

if [ -n "$issues" ]; then
  echo ""
  echo "--- Issues ---"
  echo -e "$issues"
fi
