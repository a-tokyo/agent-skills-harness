# Factory Self-Test Design

## Purpose

Validate the create-skill-autoresearch factory by running it on the case studies that inspired its design. The factory should produce skills of comparable quality to the manually-built originals.

## Test Strategy

The factory is both the subject and the tool. To avoid circular validation:

1. **Gold standards are fixed** -- the manually-built skills are the immutable reference
2. **Evaluation is independent** -- the LLM judge scores factory output vs reference without knowing which is which
3. **The factory's own pipeline is the process** -- we're testing whether the pipeline produces good results, not whether we can hand-tune a good skill

## What We're Testing

- Does the interview phase ask the right questions?
- Does the research phase produce a useful dossier?
- Does the draft phase follow conventions?
- Does the autoresearch loop improve the skill?
- Does the verification phase catch real issues?
- Does the final skill match the reference quality?

## What We're NOT Testing

- Whether the factory can build skills for completely novel domains (no reference exists)
- Whether the factory is faster than manual building (speed is not a goal)
- Whether the factory's consensus protocol matches human reviewer judgment (would need human eval)

## Success Criteria

- Overall score >= 0.80 on the committed public case (`tokyo-production-grade`); additional private cases were used during the factory's original development
- No dimension scores below 5/10 on any case study
- The factory follows its own pipeline without manual intervention
- Research dossier covers key patterns identified in case study notes
