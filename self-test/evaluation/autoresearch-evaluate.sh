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
FALLBACK_REF=".agents/skills/create-skill-autoresearch/references/standalone-fallback.md"
PHASE3_REF=".agents/skills/create-skill-autoresearch/references/phase-3.md"
PHASE4_REF=".agents/skills/create-skill-autoresearch/references/phase-4.md"
PHASE5_REF=".agents/skills/create-skill-autoresearch/references/phase-5.md"
# SKILL.md is the main session's router; phase detail lives in the phase files its workers read
# (references/phase-3.md, phase-4.md, phase-5.md). Content checks read the factory's instructions as a
# whole: the router plus the phase files it dispatches. Router-only checks still read $FACTORY_SKILL.
FACTORY_DOCS=("$FACTORY_SKILL" "$PHASE3_REF" "$PHASE4_REF" "$PHASE5_REF")
factory_has() { grep -q "$@" "${FACTORY_DOCS[@]}" && echo 1 || echo 0; }
# The factory runs the upstream autoresearch skill and owns the loop conventions it needs
# (phase-4.md 4.1-4.3 + its Loop Conventions); convention checks read this contract.
AR_CONTRACT_FILES=("$FACTORY_SKILL" "$PHASE4_REF")
ar_count() { cat "${AR_CONTRACT_FILES[@]}" | grep -c "$@" || true; }
ar_has() { grep -q "$@" "${AR_CONTRACT_FILES[@]}" && echo 1 || echo 0; }
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
for ref in "references/pipeline-phases.md" "references/rubric-templates.md" "references/consensus-protocol.md" \
           "references/standalone-fallback.md" \
           "references/benchmark-standard.md" "references/publishing.md"; do
  dim_crossref_max=$((dim_crossref_max + 1))
  FULL_PATH=".agents/skills/create-skill-autoresearch/$ref"
  check crossref "Factory ref $ref exists" $([ -f "$FULL_PATH" ] && echo 1 || echo 0)
done

# Every reference must be reachable from SKILL.md — an orphan reference is dead weight the
# model never loads, and a link to a missing file is worse.
for ref in .agents/skills/create-skill-autoresearch/references/*.md; do
  base="references/$(basename "$ref")"
  dim_crossref_max=$((dim_crossref_max + 1))
  check crossref "SKILL.md links $base" \
    $(grep -qF "$base" "$FACTORY_SKILL" && echo 1 || echo 0)
done

# A reference over ~100 lines needs a Contents list, so a partial read still shows full scope.
for ref in .agents/skills/create-skill-autoresearch/references/*.md; do
  ref_lines=$(wc -l < "$ref")
  if [ "$ref_lines" -gt 100 ]; then
    dim_crossref_max=$((dim_crossref_max + 1))
    check crossref "$(basename "$ref") ($ref_lines lines) has a Contents TOC" \
      $(grep -qE '^## Contents' "$ref" && echo 1 || echo 0)
  fi
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
GIT_ADD_A_BAD=$(ar_count "git add -A")
GIT_ADD_A_WARNING=$(ar_count "Never.*git add -A")
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
NOISE_THRESHOLD=$(ar_count "noise threshold")
check consistency "KEEP decision has noise threshold" $([ "$NOISE_THRESHOLD" -ge 1 ] && echo 1 || echo 0)

# Context budget
dim_consistency_max=$((dim_consistency_max + 1))
CONTEXT_BUDGET=$(ar_count -i "Context Budget")
check consistency "Autoresearch has context budget guidance" $([ "$CONTEXT_BUDGET" -ge 1 ] && echo 1 || echo 0)

# Devil's Advocate spelling
dim_consistency_max=$((dim_consistency_max + 1))
DEVILS_WRONG=$( (grep -r "Devils Advocate" "$FACTORY_SKILL" "$PIPELINE_REF" "$PHASE5_REF" "$CONSENSUS_REF" 2>/dev/null || true) | wc -l | tr -d ' ')
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

# Key concepts in the autoresearch contract the factory passes to the loop
for concept in "METRIC" "baseline" "plateau" "jsonl" "results.tsv" "evaluate-checks.sh" "git reset"; do
  dim_completeness_max=$((dim_completeness_max + 1))
  check completeness "Autoresearch contract mentions '$concept'" $(ar_has -i "$concept")
done

# Companion composition (v0.3.0): authoring, craft, and the eval gate are delegated, with fallbacks
for concept in "skill-creator" "writing-for-agents" "claude plugin eval" "standalone-fallback.md"; do
  dim_completeness_max=$((dim_completeness_max + 1))
  check completeness "Factory composes '$concept'" $(grep -qF "$concept" "$FACTORY_SKILL" && echo 1 || echo 0)
done

# Overfitting detection
dim_completeness_max=$((dim_completeness_max + 1))
check completeness "Factory has overfitting detection" $(factory_has -i "overfitting")

dim_completeness_max=$((dim_completeness_max + 1))
check completeness "Factory has leave-one-out overfitting" $(factory_has -i "leave-one-out.*overfitting\|overfitting.*leave-one-out\|per-case.*variance")

# LLM system prompt guidance
dim_completeness_max=$((dim_completeness_max + 1))
check completeness "Factory explains skill invocation as LLM prompt" $(factory_has -i "system prompt\|LLM.*system\|SKILL.md as.*prompt")

# ============================================================================
# CLARITY (actionability for a naive agent)
# ============================================================================
dim_clarity_max=0

# Has concrete examples
dim_clarity_max=$((dim_clarity_max + 1))
CODE_BLOCKS=$(grep -cE '^```(yaml|bash|sh)' "$FACTORY_SKILL" || true)
check clarity "Factory has concrete yaml/bash examples (actual: $CODE_BLOCKS)" $([ "$CODE_BLOCKS" -ge 2 ] && echo 1 || echo 0)

dim_clarity_max=$((dim_clarity_max + 1))
BASH_BLOCKS=$(cat "$PIPELINE_REF" "$PHASE3_REF" "$PHASE4_REF" "$PHASE5_REF" | grep -c '```bash\|```sh' || true)
check clarity "Phase refs have bash examples (actual: $BASH_BLOCKS)" $([ "$BASH_BLOCKS" -ge 2 ] && echo 1 || echo 0)

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
check depth "Factory has cost awareness for large gold standard sets" $(factory_has "cost.*evaluat\|evaluat.*cost\|sampling.*strategy\|100+")

# Does autoresearch mention what happens at experiment 0 if baseline fails?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch contract handles baseline failure" $(ar_has -i "baseline.*fail\|fail.*baseline\|metric command fails\|command.*fail")

# Does factory explain how evaluate.sh runs the skill? (the critical invocation gap)
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory evaluate.sh shows LLM invocation mechanism" $(factory_has "curl\|API.*call\|sdk\|programmatic")

# Does autoresearch explain what to do when metric variance is high?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch contract addresses judge variance" $(ar_has -i "variance\|MAD\|noise")

# Does factory have line budget warning (< 500 tight margin)?
dim_depth_max=$((dim_depth_max + 1))
FACTORY_LINES=$(wc -l < "$FACTORY_SKILL")
check depth "Factory SKILL.md has > 25 line margin (actual: $((500 - FACTORY_LINES)))" $([ "$((500 - FACTORY_LINES))" -ge 25 ] && echo 1 || echo 0)

# SKILL.md is re-read on every main-session call, so it stays a lean router (cost parity, criterion 17)
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory SKILL.md is a router <= 260 lines (actual: $FACTORY_LINES)" $([ "$FACTORY_LINES" -le 260 ] && echo 1 || echo 0)

# The orchestration contract: each phase worker reads only its file and returns a short summary
for ref in "references/phase-3.md" "references/phase-4.md" "references/phase-5.md" "references/operating-rules.md"; do
  dim_depth_max=$((dim_depth_max + 1))
  check depth "Router dispatches a worker with $ref" $(grep -qF "$ref" "$FACTORY_SKILL" && [ -f ".agents/skills/create-skill-autoresearch/$ref" ] && echo 1 || echo 0)
done
dim_depth_max=$((dim_depth_max + 1))
check depth "Worker summary is bounded (<= 15 lines) in the dispatch prompt" $(grep -qi "at most 15 lines" "$FACTORY_SKILL" && echo 1 || echo 0)

# Is there guidance on minimum improvement for LLM-judge metrics?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch contract documents min improvement threshold" $(ar_has "0\.01\|absolute minimum\|noise threshold")

# Does factory address model diversity for panel?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory mentions model diversity for panel" $(grep -qic "different model\|model family\|model diversity" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch have plateau window config?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch contract has configurable plateau window" $(ar_has "plateau_window\|PLATEAU_WINDOW")

# Does factory reference the self-test?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory references self-test evaluate.sh" $(factory_has "self-test")

# Does consensus protocol have anti-patterns section?
dim_depth_max=$((dim_depth_max + 1))
check depth "Consensus protocol has anti-patterns" $(grep -qc "Anti-Pattern" "$CONSENSUS_REF" && echo 1 || echo 0)

# Does factory have resume protocol?
dim_depth_max=$((dim_depth_max + 1))
check depth "Factory has resume/handoff protocol" $(grep -qic "resume\|handoff" "$FACTORY_SKILL" && echo 1 || echo 0)

# Does autoresearch explain ideas backlog?
dim_depth_max=$((dim_depth_max + 1))
check depth "Autoresearch contract explains ideas backlog" $(ar_has "autoresearch.ideas.md")

# ============================================================================
# ROBUSTNESS (Opus failure scenarios + edge cases)
# ============================================================================
dim_robustness_max=0

# Does autoresearch handle baseline failure gracefully?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Autoresearch contract handles baseline measurement failure" $(ar_has "baseline.*fail\|If.*metric.*fail\|cannot.*baseline\|fails.*exit")

# Does factory address what happens when LLM API is unavailable?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Factory addresses LLM API unavailability" $(factory_has -i "fallback\|unavailable\|fail.*graceful\|deterministic.*only\|without.*LLM\|no LLM available")

# Does autoresearch explain untracked file cleanup?
dim_robustness_max=$((dim_robustness_max + 1))
check robustness "Autoresearch contract uses git clean on revert" $(ar_has "git clean")

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
