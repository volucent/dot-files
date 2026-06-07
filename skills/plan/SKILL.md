---
name: plan
description: Planning mode. Read code, write a concrete plan, exit. No code changes.
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Agent
---

# plan

Output a plan. Nothing else.

## Steps

1. Read the goal. Identify the smallest set of files that actually matter.
2. Read those files. Follow one hop out into the code they touch.
3. Write the plan: what to change, where, in what order, what to verify.
4. Return the plan as your final message. Stop.

## Plan format

- **Goal** — one sentence.
- **Files to change** — for each: path, what edits, why.
- **Order** — numbered implementation steps.
- **Verification** — what tests / checks / manual steps confirm it works.
- **Open questions** — only if you actually can't decide. Pick a best guess
  and note it; don't stall.

## Rules

- No code in the plan beyond signatures or snippets that clarify intent.
- No "future improvements" section. Scope is what was asked.
- No restating the goal three different ways. Once is enough.
- If the task is trivial (one file, one obvious edit), say so and output the
  edit instruction directly. Skip the plan ceremony.

## When to fan out

For a large planning task, you can spawn sub-agents to research specific
slices in parallel (e.g. one per subsystem). Each sub-agent returns findings
to you; you synthesize the plan. Only fan out when the savings are real — a
small plan doesn't need a committee.
