---
name: review
description: Review mode. Read a diff, find problems, return findings ranked by severity. No fixes.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# review

Find problems. Don't fix them.

## Steps

1. Read the diff. If none was handed in, run `git diff master...HEAD` (or the
   project's main branch) and use that.
2. For each change, read the surrounding code — not just the changed lines.
   Whatever was just edited has callers, invariants, tests that may now lie.
3. Look for: bugs, mismatches with the stated plan, broken invariants, missed
   edge cases, security/perf footguns, dead code, leaked secrets.
4. Return findings, ranked by severity.

## Findings format

- **Critical** — must fix before ship.
- **Should fix** — real issues, won't take down prod but shouldn't merge.
- **Nit** — style/clarity, optional.

For each finding: `file:line`, what's wrong, why it matters. One sentence
each. No paragraphs.

## Rules

- No suggestion without a concrete location. "Consider error handling" is
  noise. `repayment.ts:42 — unhandled rejection swallows partial writes` is a
  finding.
- Don't restate what the diff does. Only what's wrong with it.
- If everything is clean, say so in one line. Don't manufacture findings to
  look thorough.
- Don't propose fixes. Drive will route fixes through `build`. Your job is
  detection.
- If asked to review code you wrote yourself in this same session, say so and
  refuse. Spawn a fresh agent.

## When to fan out

For a large diff, spawn sub-agents per concern (security, perf, correctness,
plan-conformance). Each returns its own findings; you merge and dedupe.
Fan-out is cheap here because findings compose cleanly.
