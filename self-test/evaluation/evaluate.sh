#!/bin/bash
# evaluate.sh -- Evaluate a factory-PRODUCED skill against its gold-standard reference.
# (For the factory's OWN structural regression checks, see autoresearch-evaluate.sh.)
#
# Usage: ./evaluate.sh <case-id>
#
# How skill evaluation works:
# Skills are markdown instructions for AI agents -- not executable programs.
# To evaluate a skill, we:
#   1. Read the factory-produced SKILL.md
#   2. Read the reference (gold standard) SKILL.md
#   3. Run DETERMINISTIC structural checks (no LLM needed)
#   4. Run LLM-AS-JUDGE comparison on subjective dimensions
#   5. Emit METRIC lines for each dimension + overall_score
#
# The LLM judge step requires an LLM API. Set JUDGE_MODEL and JUDGE_API_KEY
# environment variables, or the script falls back to structural-only scoring.

set -euo pipefail

CASE_ID="${1:?Usage: ./evaluate.sh <case-id>}"
SELF_TEST_DIR="$(cd "$(dirname "$0")/.." && pwd)"
REPO_ROOT="$(cd "$SELF_TEST_DIR/.." && pwd)"
RUBRIC="$SELF_TEST_DIR/evaluation/rubric.yaml"

# --- Locate files ---
FACTORY_SKILL=$(find "$SELF_TEST_DIR/runs/$CASE_ID/skill/" -name "SKILL.md" -type f 2>/dev/null | head -1 || true)
if [ -z "$FACTORY_SKILL" ]; then
  echo "ERROR: No factory output found. Run the factory on case '$CASE_ID' first." >&2
  exit 1
fi

# Lookup reference skill from manifest
REFERENCE_SKILL=$(python3 -c "
import yaml, sys
with open('$SELF_TEST_DIR/gold-standards/manifest.yaml') as f:
    m = yaml.safe_load(f)
for c in m['cases']:
    if c['id'] == '$CASE_ID' and c.get('reference_skill'):
        print(c['reference_skill'])
        sys.exit(0)
print('')
" 2>/dev/null)

# Manifest reference_skill paths are repo-root-relative; resolve them so the check
# works regardless of the current working directory.
if [ -n "$REFERENCE_SKILL" ] && [ "${REFERENCE_SKILL#/}" = "$REFERENCE_SKILL" ]; then
  REFERENCE_SKILL="$REPO_ROOT/$REFERENCE_SKILL"
fi

if [ -z "$REFERENCE_SKILL" ] || [ ! -f "$REFERENCE_SKILL" ]; then
  echo "WARNING: No reference skill for case '$CASE_ID'. Running structural checks only." >&2
fi

echo "--- Evaluating: $CASE_ID ---" >&2

# =============================================================================
# DETERMINISTIC CHECKS (no LLM needed)
# =============================================================================

FACTORY_LINES=$(wc -l < "$FACTORY_SKILL")
HAS_FRONTMATTER=$(head -1 "$FACTORY_SKILL" | grep -c "^---" || true)
HAS_NAME=$(grep -c "^name:" "$FACTORY_SKILL" || true)
HAS_DESCRIPTION=$(grep -c "^description:" "$FACTORY_SKILL" || true)

# Line count check (convention: < 500)
if [ "$FACTORY_LINES" -lt 500 ]; then
  LINE_SCORE=10
else
  LINE_SCORE=$(( 10 - (FACTORY_LINES - 500) / 50 ))
  [ "$LINE_SCORE" -lt 1 ] && LINE_SCORE=1
fi

# Frontmatter check
if [ "$HAS_FRONTMATTER" -ge 1 ] && [ "$HAS_NAME" -ge 1 ] && [ "$HAS_DESCRIPTION" -ge 1 ]; then
  FRONTMATTER_SCORE=10
elif [ "$HAS_FRONTMATTER" -ge 1 ]; then
  FRONTMATTER_SCORE=6
else
  FRONTMATTER_SCORE=2
fi

# Reference link integrity
BROKEN_LINKS=0
while IFS= read -r link; do
  LINK_PATH=$(dirname "$FACTORY_SKILL")/"$link"
  if [ ! -f "$LINK_PATH" ]; then
    BROKEN_LINKS=$((BROKEN_LINKS + 1))
  fi
done < <(grep -oE '\]\([^)]+\.md\)' "$FACTORY_SKILL" | sed -E 's/^\]\(//; s/\)$//' | grep -v '^http' || true)

if [ "$BROKEN_LINKS" -eq 0 ]; then
  CROSSREF_SCORE=10
else
  CROSSREF_SCORE=$(( 10 - BROKEN_LINKS * 2 ))
  [ "$CROSSREF_SCORE" -lt 1 ] && CROSSREF_SCORE=1
fi

# Consistency score from structural checks
CONSISTENCY_SCORE=$(( (LINE_SCORE + FRONTMATTER_SCORE + CROSSREF_SCORE) / 3 ))

echo "METRIC consistency=$CONSISTENCY_SCORE"
echo "METRIC line_count_ok=$([ "$FACTORY_LINES" -le 500 ] && echo 1 || echo 0)"
echo "METRIC has_frontmatter=$([ "$HAS_FRONTMATTER" -ge 1 ] && echo 1 || echo 0)"

# =============================================================================
# LLM-AS-JUDGE (requires JUDGE_MODEL env var)
# =============================================================================

if [ -n "${JUDGE_MODEL:-}" ] && [ -n "$REFERENCE_SKILL" ] && [ -f "$REFERENCE_SKILL" ]; then
  FACTORY_CONTENT=$(cat "$FACTORY_SKILL")
  REFERENCE_CONTENT=$(cat "$REFERENCE_SKILL")

  JUDGE_PROMPT=$(cat <<PROMPT
You are evaluating an AI-generated skill against a human-built reference skill.
Score each dimension on a 1-10 scale. Return ONLY valid JSON.

## Dimensions
- correctness: Instructions are technically accurate. No hallucinated patterns.
- completeness: Covers the same scope as the reference. No critical gaps.
- clarity: A naive agent can follow without ambiguity.
- consistency: Aligns with existing codebase conventions and internal cross-references.
- research_quality: Shows understanding of the domain comparable to the reference.
- rubric_quality: If the skill includes evaluation criteria, they are falsifiable.
- process_quality: Follows skill conventions (frontmatter, structure, progressive disclosure).
- outcome_match: Would serve equally well as the reference for its intended purpose.

## Reference Skill (Gold Standard)
$REFERENCE_CONTENT

## Factory-Produced Skill (To Evaluate)
$FACTORY_CONTENT

## Output (JSON only, no markdown)
{"correctness":N,"completeness":N,"clarity":N,"consistency":N,"research_quality":N,"rubric_quality":N,"process_quality":N,"outcome_match":N}
PROMPT
)

  # Call LLM judge -- implementation depends on available API
  # Supports: curl to OpenAI-compatible API
  if [ -n "${JUDGE_API_BASE:-}" ] && [ -n "${JUDGE_API_KEY:-}" ]; then
    JUDGE_RESPONSE=$(curl -s "${JUDGE_API_BASE}/chat/completions" \
      -H "Authorization: Bearer $JUDGE_API_KEY" \
      -H "Content-Type: application/json" \
      -d "$(python3 -c "
import json, sys
print(json.dumps({
    'model': '${JUDGE_MODEL}',
    'temperature': 0.0,
    'messages': [{'role': 'user', 'content': sys.stdin.read()}]
}))
" <<< "$JUDGE_PROMPT")" 2>/dev/null)

    # Parse scores from response
    SCORES=$(echo "$JUDGE_RESPONSE" | python3 -c "
import json, sys, re
resp = json.load(sys.stdin)
text = resp['choices'][0]['message']['content']
# Extract JSON from response (may be wrapped in markdown)
match = re.search(r'\{[^}]+\}', text)
if match:
    scores = json.loads(match.group())
    weights = {'correctness':0.15,'completeness':0.15,'clarity':0.10,
               'consistency':0.10,'research_quality':0.15,
               'rubric_quality':0.10,'process_quality':0.10,
               'outcome_match':0.15}
    overall = sum(scores.get(k,5)/10*w for k,w in weights.items())
    for k,v in scores.items():
        print(f'METRIC {k}={v}')
    print(f'METRIC overall_score={overall:.4f}')
" 2>/dev/null)

    if [ -n "$SCORES" ]; then
      echo "$SCORES"
    else
      echo "WARNING: LLM judge response parsing failed. Using structural scores only." >&2
      echo "METRIC overall_score=$(echo "scale=4; $CONSISTENCY_SCORE / 10 * 0.10" | bc)"
    fi
  else
    echo "INFO: Set JUDGE_API_BASE and JUDGE_API_KEY for LLM-as-judge scoring." >&2
    echo "METRIC overall_score=$(echo "scale=4; $CONSISTENCY_SCORE / 10 * 0.10" | bc)"
  fi
else
  echo "INFO: Structural checks only (no JUDGE_MODEL or no reference skill)." >&2
  echo "METRIC overall_score=$(echo "scale=4; $CONSISTENCY_SCORE / 10 * 0.10" | bc)"
fi
