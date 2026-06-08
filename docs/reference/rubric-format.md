# Rubric Format Reference

The evaluation rubric defines how a skill is scored against gold standards. It's a YAML file that specifies dimensions, weights, criteria, and scoring parameters.

## Schema

```yaml
name: <skill-name>-rubric       # identifier
dimensions:                       # 5-10 scored dimensions
  - name: <string>                # lowercase, underscores (e.g., content_accuracy)
    weight: <float>               # 0.0-1.0, must sum to 1.0 across all dimensions
    scale: "1-10"                 # scoring scale
    criteria: <string>            # falsifiable statement of what this measures
target_score: <float>             # normalized 0.0-1.0 (e.g., 0.85 = 85%)
max_iterations: <int>             # experiment budget (default: 20)
plateau_window: <int>             # consecutive failures before plateau alert (default: 5)
```

## Universal Dimensions

Every rubric includes these four dimensions. Adjust weights per domain (default total: 0.60).

| Dimension | Default Weight | Criteria |
|-----------|---------------|----------|
| correctness | 0.20 | Instructions are technically accurate and executable. No hallucinated APIs, wrong syntax, or incorrect behavior. |
| completeness | 0.15 | All necessary sections present. Edge cases addressed. No critical workflow gaps. |
| clarity | 0.15 | A naive agent can follow without ambiguity. Consistent terminology. Concrete examples. |
| consistency | 0.10 | Aligns with existing codebase conventions, naming patterns, and integration points. |

## Domain-Specific Dimensions

Add 3-6 domain-specific dimensions using the remaining weight (default: 0.40).

### Writing Good Criteria

Criteria must be **falsifiable** -- a judge can determine TRUE or FALSE by examining the artifact.

**Good**:
- "Every gold standard pattern appears in the skill output"
- "No org-specific names or hardcoded references appear in the body"
- "All file references resolve to existing files"
- "Output length is within 20% of reference length"

**Bad**:
- "The skill is well-written" (subjective)
- "Output is high quality" (vague)
- "Follows best practices" (which practices?)

## Overall Score Computation

```
overall_score = sum(dimension_score / scale_max * weight) for each dimension
```

Example with a 1-10 scale:
- correctness: 8/10 * 0.20 = 0.16
- completeness: 7/10 * 0.15 = 0.105
- clarity: 9/10 * 0.15 = 0.135
- consistency: 8/10 * 0.10 = 0.08
- coverage: 7/10 * 0.20 = 0.14
- actionability: 8/10 * 0.20 = 0.16
- **overall_score = 0.78**

## Example Rubric

```yaml
name: code-behavior-rubric
dimensions:
  - name: correctness
    weight: 0.20
    scale: "1-10"
    criteria: "Rules are technically accurate. Code examples compile and run correctly."
  - name: completeness
    weight: 0.10
    scale: "1-10"
    criteria: "All relevant coding scenarios covered. Edge cases addressed."
  - name: clarity
    weight: 0.15
    scale: "1-10"
    criteria: "Rules are unambiguous. A naive agent follows them without misinterpretation."
  - name: consistency
    weight: 0.10
    scale: "1-10"
    criteria: "Matches existing project conventions and coding standards."
  - name: coverage
    weight: 0.15
    scale: "1-10"
    criteria: "Every pattern from gold standard source material appears in the skill."
  - name: actionability
    weight: 0.15
    scale: "1-10"
    criteria: "Rules are concrete and executable, not abstract platitudes."
  - name: portability
    weight: 0.15
    scale: "1-10"
    criteria: "Works across projects without hardcoded names or project-specific assumptions."
target_score: 0.85
max_iterations: 20
plateau_window: 5
```

See [rubric-templates.md](../../.agents/skills/create-skill-autoresearch/references/rubric-templates.md) in the factory skill for additional domain templates (workflow skills, pipeline skills).

## Judge Variance

From case study experience (extensive experiments with multiple judge models):

- Typical judge variance: 0.2-0.3 points on a 1-10 scale
- Improvements must exceed judge variance to be meaningful
- Different judge models have different characteristics:
  - Lower variance models give more consistent but potentially less nuanced scores
  - Stricter models produce lower baselines but may detect subtler issues
- Multiple judges improve confidence but increase evaluation cost

When plateau detection triggers, check whether the plateau falls within judge variance -- the skill may already be at the measurement ceiling.
