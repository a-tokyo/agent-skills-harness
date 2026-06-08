# Skill-Authoring Conventions

Conventions our factory must follow. The authority is Anthropic's official
[Skill authoring best practices](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices);
these are also compatible with Cursor's `create-skill`. The enforceable distillation the factory
ships lives in `.agents/skills/create-skill-autoresearch/references/skill-authoring-best-practices.md`.

## Frontmatter (Required)

```yaml
---
name: skill-name          # lowercase, hyphens, alnum, <= 64 chars, matches folder name
                          # no reserved words (anthropic/claude); gerund form preferred
description: >-           # 1-1024 chars, third-person, WHAT + WHEN
  Specific capabilities in third person. Use when [trigger conditions].
disable-model-invocation: true  # Optional, default true
---
```

## Directory Structure

```
skill-name/
├── SKILL.md        # REQUIRED, < 500 lines
├── reference.md    # Optional -- flat sibling, not nested
├── examples.md     # Optional
└── scripts/        # Optional -- executable utilities
```

Note: create-skill prescribes FLAT sibling files, not `references/` directory. Our production-grade
skill uses `references/` (a documented extension). Factory should support both.

## Description Rules

1. Third person (no "I can..." or "You can...")
2. Include WHAT (capabilities) + WHEN (trigger scenarios)
3. Use "Use when..." pattern for triggers
4. Include domain-specific keywords for discovery
5. <= 1024 chars

## Body Rules

1. < 500 lines
2. Progressive disclosure: essential in SKILL.md, detail in reference files
3. File references ONE LEVEL DEEP only
4. Concrete examples over abstract instructions
5. Consistent terminology throughout

## Anti-Patterns to Reject

- Windows-style paths
- Too many options without defaults
- Time-sensitive information without deprecation notes
- Vague skill names (helper, utils, tools)
- Verbose explanations the agent already knows

## Workflow Phases

1. Discovery -- purpose, location, triggers, constraints
2. Design -- name, description, sections, supporting files
3. Implementation -- directory, SKILL.md, references, scripts
4. Verification -- 500 lines, description quality, terminology, links, discoverability

## Common Patterns

- Template pattern: output format templates
- Examples pattern: input/output pairs
- Workflow pattern: checklists + step-by-step
- Conditional workflow: decision branches
- Feedback loop: validate → fix → re-validate
