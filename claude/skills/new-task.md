---
name: new-task
description: Start a new task from a Slack message or Asana ticket. Creates a branch off master, plans the work, and writes the plan to a markdown file.
argument-hint: <paste the task description from Slack/Asana>
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Write, Agent
---

# New Task

You are starting a new task. The user has pasted context from Slack or Asana below:

> $ARGUMENTS

## Step 1: Understand the task

Read the pasted context carefully. Identify:
- What needs to be done
- Which domain area this falls under (advance, budget, rewards, cards, pave, plaid, stripe, sweepstakes, array, underwriting, experiments, or another area)
- The type of change: `feat` (new feature), `fix` (bug fix), or `chore` (maintenance/refactor)

## Step 2: Create a branch

Branch naming convention: `<type>/<domain>/<short-description>`

Examples:
- `feat/advance/add-retry-on-repayment`
- `fix/rewards/postback-duplicate-check`
- `chore/plaid/cleanup-stale-accounts`

Rules:
- Always branch off `master`
- Use lowercase, kebab-case for the description
- Keep the description short (3-5 words max)
- Best-guess the domain from the task context
- Run: `git checkout master && git pull && git checkout -b <branch-name>`

## Step 3: Research and plan

Before writing the plan, explore the codebase to understand:
- Which files are relevant to this task
- Existing patterns and conventions in the affected domain
- Any related code that might be impacted

Use Grep, Glob, and Read to investigate. Be thorough — the plan should be grounded in actual code, not assumptions.

## Step 4: Write the plan

Create a file at `./tmp/<branch-name>.md` (e.g. `./tmp/feat-advance-add-retry-on-repayment.md`) with this structure:

```markdown
# Task: <short title>

> <original task context pasted by user>

## Branch
`<branch-name>`

## Summary
<2-3 sentence summary of what needs to be done and why>

## Domain
<domain area>

## Files to modify
- `path/to/file.ts` — what changes here and why
- `path/to/another-file.ts` — what changes here and why

## Implementation steps
1. <step>
2. <step>
3. <step>
...

## Testing
- <what to test>
- <edge cases to consider>

## Notes
- <anything worth calling out: risks, dependencies, open questions>
```

After writing the plan, present it to the user and ask if they want to proceed or adjust anything.
