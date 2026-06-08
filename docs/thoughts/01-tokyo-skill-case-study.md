# Case Study: tokyo (production-grade) Skill

The deepest and most mature example of skill creation in the portfolio. Built across 8+ iterations with 11 parallel subagents, a 20-file research dossier, and a 12-gate quality bar.

## What Was Built

A portable, evergreen Cursor/Claude skill named `production-grade` (originally `tokyo`) that encodes principle-engineering posture: 4 meta-rules + 15 operating rules + 9 reference files. ~170 lines in the body, ~200 lines per reference.

## The Process

### Phase 1: Source Material Collection
- Operator's verbatim engineering brief distilled into 36 values (V1-V36)
- 41 observable patterns (S1-S41) extracted from 9+ years of shipped work across backend, web, mobile, devops
- 839 curated GitHub stars analyzed
- Canonical source distillation: React (react.dev, Abramov essays), Redux (Three Principles, Style Guide), GraphQL (spec, DataLoader)

### Phase 2: Research Dossier
19 research files covering:
- Source prompt and values (00)
- Engineering signature patterns (01)
- PR anatomy conventions (02)
- Organization conventions (03)
- Contrast against alternatives (04)
- Craft decisions log (05) -- 85+ entries
- Surface-to-substance mapping (06)
- Toolchain canon (08)
- Operator's skill catalogue patterns (09)
- Stars curriculum (10)
- Platform-specific anatomies: backend (11), web (15), mobile (16), devops (17)
- PO skill iteration history (12) -- private calibration reference
- Skills.sh canon survey (13) -- 35 published skills analyzed
- React/Redux/GraphQL distillation (14)
- Frontend patterns (18)
- Peer skills survey (19)

### Phase 3: Skill Drafting
- DESIGN.md written BEFORE any SKILL.md code
- Structural decisions locked: rule count, meta vs operating split, anchor citation style, reference layout
- Grill-me session on the design before drafting
- Single-pass first draft captured as SKILL.draft-1.md

### Phase 4: Autoresearch Loop
- Craft-decisions ledger (D0-D85+) logged every hypothesis/edit/measurement
- Each iteration: edit SKILL.md → measure against 12-gate quality bar → keep/revert → log
- Parallel subagent orchestration: 10 subagents (A-J) dispatched for different mining tasks
- Handoff documents when context fatigued (iter-6→7, iter-7→8)
- Honesty corrections when empirical evidence contradicted directives (S41)

### Phase 5: Quality Bar (12 Gates)
1. V coverage: every V1-V36 cited
2. S coverage: every S1-S41 cited
3. Frontmatter: name, description <= 1024 chars, license: MIT
4. Body length: target <= 280 lines
5. Hardcoded-name scan: 0 org names in body
6. Banned-phrase scan: 0 hits for marketing language
7. Cross-ref integrity: all reference links resolve
8. Currency check: no stale opinions
9. Voice: imperative third-person, no "we"/"you"
10. Idiom alignment: matches operator's published skill patterns
11. Ledger entry: every gate fail logged with fix
12. Publishability: works if dropped into any team's ~/.cursor/skills/

## Key Innovations

- **V/S anchor system**: every directive traces to empirical evidence (value or shipped-work signature)
- **Design-first process**: DESIGN.md is the contract; SKILL.md answers to it
- **Grill-me sessions**: adversarial design interrogation before committing to structure
- **Parallel subagent orchestration**: 10 concurrent subagents mining different evidence sources
- **Honesty corrections**: when evidence contradicts a directive, fix the directive
- **Currency check (M4)**: operator's own opinions are not exempt from "latest docs beat training recall"
- **Concept-slot pairing**: skill body uses generic slots ("an SMS provider"), not brand names

## Reusable Patterns for the Factory

1. **DESIGN.md before SKILL.md**: lock structural decisions before writing
2. **Research dossier as source of truth**: every claim traceable to evidence
3. **Multi-gate quality bar**: automated + structural + voice checks
4. **Craft-decisions ledger**: append-only log of every iteration
5. **Handoff documents**: preserve continuity across context windows
6. **Subagent transcript archives**: reproducible evidence gathering
7. **Grill-me pattern**: adversarial interrogation of design choices
