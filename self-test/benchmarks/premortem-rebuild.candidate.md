---
name: premortem
description: >
  Runs a structured pre-mortem analysis on a plan or implementation before execution.
  Imagines the work has already failed, enumerates plausible failure modes, surfaces
  hidden assumptions and unspoken risks, then VERIFIES each candidate risk against the
  actual plan or code to eliminate false positives. Classifies survivors by severity and
  requires an explicit user decision (accept / mitigate / research) before work proceeds.
  Based on Gary Klein's pre-mortem technique. Use before implementing a plan, before
  writing significant new code, or during PR review when a change carries non-trivial
  risk.
---

# Pre-mortem skill

Run this skill before executing any plan or significant implementation. The goal is to
surface real risks—not theoretical ones—and ensure the user makes a conscious decision
about each before work begins.

## When to invoke

- Agent is about to execute a multi-step plan
- Agent is about to write or refactor a significant block of code
- PR review reveals changes that touch shared infrastructure, auth, data migrations,
  external integrations, or performance-sensitive paths
- User says "let's build X" and no pre-mortem has been run in this session

---

## Workflow

### Step 0 — Gather the artifact

Identify what is being pre-mortemed. Collect:
- The written plan, ticket, or spec (or summarize what the agent is about to do)
- Any existing code that will be modified
- Known constraints (deadlines, third-party dependencies, team size)

If the artifact is ambiguous, ask one clarifying question before proceeding.

---

### Step 1 — Failure imagination (divergent)

**Perspective:** "It is six months from now. This project shipped and failed spectacularly.
The post-mortem is being written. What went wrong?"

Generate a candidate list covering all of these lenses. Aim for 8–15 candidates.

| Lens | Prompt |
|------|--------|
| **Technical correctness** | What edge cases were missed? What invariants were silently broken? |
| **Integration** | Which upstream/downstream system behaved differently than assumed? |
| **State & data** | What data was corrupted, lost, or migrated incorrectly? |
| **Security** | What attack surface opened up? What was exposed that shouldn't be? |
| **Performance** | What load, latency, or resource constraint was underestimated? |
| **Reversibility** | What decision made rollback impossible or painful? |
| **Assumptions** | What did the team believe that turned out to be false? |
| **Coordination** | What did a human, team, or external party fail to do or communicate? |
| **Observability** | What failure went undetected because there was no alert or log? |
| **Scope creep / drift** | What grew beyond its original design, causing fragility? |

Label each candidate with its lens and write one sentence describing the failure mode.

---

### Step 2 — Verification (eliminate false positives)

**This step is mandatory.** Do not report a risk you have not verified against the actual
plan or code.

For each candidate from Step 1:

1. **Locate the relevant artifact section** — point to the specific plan step, function,
   config value, or dependency where the risk would manifest.
2. **Test the claim** — ask: "Is there concrete evidence in the artifact that this failure
   mode is possible, or am I pattern-matching from generic experience?"
3. **Disposition:**
   - `CONFIRMED` — the artifact contains a real gap or exposure that enables this failure
   - `MITIGATED` — the artifact already addresses this (document how, then drop it)
   - `SPECULATIVE` — no evidence in the artifact; the risk is plausible but ungrounded — drop it or downgrade to a note

Only `CONFIRMED` risks advance to Step 3. Speculative risks that are high-stakes may be
retained as a note with explicit uncertainty.

---

### Step 3 — Classify severity

Rate each confirmed risk on two axes, then combine:

**Impact** (if the failure occurs):
- `HIGH` — data loss, security breach, production outage, irreversible state corruption
- `MED` — degraded UX, partial data loss, recoverable failure, missed SLA
- `LOW` — cosmetic, easily patched, no user-visible effect

**Likelihood** (given the current plan):
- `HIGH` — the plan has no guard against this; it would likely trigger under normal load
- `MED` — requires an unusual condition or a second failure to trigger
- `LOW` — requires multiple unlikely conditions to align

**Combined severity:**

| Impact \ Likelihood | HIGH | MED | LOW |
|---------------------|------|-----|-----|
| HIGH                | CRITICAL | HIGH | MED |
| MED                 | HIGH | MED | LOW |
| LOW                 | MED | LOW | LOW |

---

### Step 4 — Structured output

Present findings in this exact format:

```
## Pre-mortem report

**Artifact:** <one-line description of what was analyzed>
**Candidate risks generated:** <N>
**After verification:** <M confirmed>, <K mitigated>, <J speculative dropped>

---

### Confirmed risks

#### [1] <Short title>
- **Lens:** <lens from Step 1>
- **Severity:** <CRITICAL / HIGH / MED / LOW>
- **Failure mode:** <One sentence — what goes wrong and when>
- **Evidence:** <Quote or point to the specific artifact location>
- **Options:**
  - Accept: <consequence of accepting this risk>
  - Mitigate: <concrete change that would reduce the risk>
  - Research: <what would need to be proven before proceeding safely>

[Repeat for each confirmed risk, sorted CRITICAL → HIGH → MED → LOW]

---

### Notes (speculative but high-stakes)

- <risk> — <why it is speculative, what would make it confirmed>

---

### Decision required

For each risk above, the user must choose one of:
  [ ] Accept   [ ] Mitigate (specify change)   [ ] Research (specify question)

No implementation begins until all CRITICAL and HIGH risks have a decision.
```

---

### Step 5 — Gate

- If any `CRITICAL` risk has no decision: **stop**. State clearly that work cannot proceed
  until the user resolves it.
- If all `CRITICAL` and `HIGH` risks are decided: summarize accepted risks, list agreed
  mitigations, then proceed (or hand off to the user to proceed).
- `MED` and `LOW` risks may proceed with the user's acknowledgment.

---

## Severity thresholds for escalation

| Severity | Agent behavior |
|----------|---------------|
| CRITICAL | Block. Do not proceed. Require explicit resolution. |
| HIGH     | Surface prominently. Require a decision before implementation. |
| MED      | Include in report. Proceed if user acknowledges. |
| LOW      | List at the bottom. Proceed without blocking. |

---

## Worked example (condensed)

**Scenario:** The plan is to add a background job that deletes user records older than
90 days, running nightly via a cron job.

**Step 1 candidates (sample):**
1. `Data` — The job deletes rows that are soft-deleted but still referenced by a foreign
   key in an audit table, causing FK violations.
2. `Reversibility` — Deleted records cannot be recovered once the job runs; there is no
   archive step.
3. `Performance` — The DELETE query runs without a LIMIT and locks the table for minutes
   under high row counts.
4. `Observability` — If the job silently errors, no alert fires and deletion stops
   without anyone noticing.
5. `Assumptions` — The team assumes "older than 90 days" is measured from `created_at`,
   but the spec says `last_active_at`; the code uses `created_at`.

**Step 2 verification:**
1. CONFIRMED — schema shows `audit_log.user_id` with no CASCADE rule.
2. CONFIRMED — the plan has no backup or archive step before deletion.
3. CONFIRMED — the draft query has no LIMIT clause.
4. CONFIRMED — the job has a try/catch that swallows exceptions.
5. CONFIRMED — code draft uses `created_at`; spec says `last_active_at`.

**Step 3 severity:**
1. FK violation → Impact HIGH, Likelihood HIGH → **CRITICAL**
2. No recovery → Impact HIGH, Likelihood HIGH → **CRITICAL**
3. Table lock → Impact MED, Likelihood MED → **MED**
4. Silent failure → Impact MED, Likelihood HIGH → **HIGH**
5. Wrong column → Impact HIGH, Likelihood HIGH → **CRITICAL**

**Step 4 output (abbreviated):**

```
## Pre-mortem report

Artifact: Nightly job to delete user records older than 90 days
Candidate risks generated: 5
After verification: 5 confirmed, 0 mitigated, 0 speculative dropped

### Confirmed risks

#### [1] FK violation on audit_log
- Lens: Data
- Severity: CRITICAL
- Failure mode: DELETE fails with FK error because audit_log.user_id has no CASCADE.
- Evidence: schema.sql line 42 — no ON DELETE CASCADE on audit_log.user_id.
- Options:
  - Accept: nightly job will error and no records are deleted (silent failure).
  - Mitigate: add ON DELETE CASCADE or archive audit rows before deleting users.
  - Research: confirm whether audit rows should be retained for compliance.

[Decision required before proceeding]
```

**Step 5:** Two CRITICAL risks remain undecided → agent blocks and waits.

---

## Anti-patterns to avoid

- **Do not list risks without verifying them** — unverified risks erode trust and waste
  the user's decision bandwidth.
- **Do not invent risks from general coding knowledge** that have no foothold in the
  actual artifact.
- **Do not proceed past a CRITICAL block** even if the user is impatient.
- **Do not skip the decision gate** — an acknowledged risk is safer than an invisible one.
- **Do not conflate severity with probability** — a LOW-likelihood CRITICAL risk still
  requires a decision.
