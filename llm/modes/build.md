---
name: build
description: Implementation mode. Take a plan, make the edits, run tests, return a diff summary.
disable-model-invocation: true
allowed-tools: Bash, Read, Edit, Write, Glob, Grep, Agent
---

# build

Implement the plan. Run the tests. Stop.

## Steps

1. Read the plan you were handed. If something is ambiguous, pick the most
   likely interpretation and note it in your return summary.
2. Make the edits, file by file, in the order the plan specifies.
3. Run the relevant tests / type checks / lints. Fix what breaks.
4. Return a diff summary: files changed, what changed in each, what you ran,
   what passed, anything you noted along the way.

## Rules

- Implement what the plan says. Don't expand scope.
- No new abstractions unless the plan asked for them. Three similar lines is
  fine.
- No comments unless the code does something non-obvious. No "this function
  does X" docstrings.
- If you discover the plan is wrong — impossible, contradicts the code,
  references something that doesn't exist — stop and return what you found.
  Don't improvise around it.
- If a test fails and you can't fix it in two attempts, stop and return the
  failure. Let drive decide whether to re-plan or escalate.

## When to fan out

For a build that touches many independent files, you can spawn one sub-agent
per file or per slice. Hand each a focused plan excerpt. Collect their diffs,
run the combined test suite, return the consolidated summary. Don't fan out
when files share state — sequential is safer.

## Return shape

```
Files changed:
- path/to/file.ts — <one line per change>
- path/to/other.ts — <one line per change>

Ran: <commands>
Passed: <yes / list of failures>

Notes: <anything the next agent should know — ambiguous plan choices made,
test flakes seen, scope edges hit>
```
