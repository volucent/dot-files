---
name: review-sub
description: Spin up a fresh sub-agent (on a chosen model) to review the current branch against master, then walk the user through resolving each finding one by one (or just report with --no-prompt).
argument-hint: [model: fable|opus|sonnet|haiku] [--no-prompt]
disable-model-invocation: true
allowed-tools: Bash, Read, Glob, Grep, Edit, Write, Agent, AskUserQuestion
---

# review-sub

Arguments: `$ARGUMENTS`

## Step 1: Parse arguments

- **Model** — first word matching `fable`, `opus`, `sonnet`, or `haiku`
  (phrases like "a fable sub agent" count). None given → omit the `model`
  param so the agent inherits the current model.
- **No prompt** — `--no-prompt` (or phrasing like "no prompt", "don't ask",
  "just report") → report findings and stop after step 4.

## Step 2: Collect the diff

Always review against `master`.

```bash
base=$(git merge-base master HEAD)
git diff --stat "$base"
```

`git diff "$base"` covers committed and uncommitted work. If it's empty, say
so in one line and stop.

## Step 3: Spawn the reviewer

Launch one `Agent` (`subagent_type: general-purpose`, `model` from step 1)
and wait for it. The reviewer gets no context from this conversation, so the
prompt must carry everything:

- Repo path, the merge-base SHA, and the command to get the diff
  (`git diff <sha>`). Don't paste the diff; let it run the command.
- Instruction to follow the review rules in `~/.claude/skills/review.md`
  (read it first): read surrounding code, not just changed lines; find bugs,
  broken invariants, missed edge cases, security/perf footguns, dead code,
  leaked secrets; no fixes; no manufactured findings.
- Required output: a numbered list ranked by severity. Each item:
  `severity (Critical / Should fix / Nit) — file:line — what's wrong — why it
  matters — suggested resolution (one line)`.

Don't tell it what you think is wrong. You want an unanchored read.

## Step 4: Show the findings

Print the reviewer's list as-is (numbered, ranked). If it's clean, say so and
stop. In no-prompt mode, stop here too — make no edits.

## Step 5: Resolve one by one

For each finding, in order, call `AskUserQuestion` with a single question:

- Question: `#N <severity> file:line — <issue>`
- Options (first one is your recommendation, marked `(Recommended)`):
  - **Fix** — apply the suggested resolution (put a concrete preview of the
    change in `preview`).
  - **Alternative fix** — only when there's a real second approach.
  - **Skip** — not an issue / won't fix.
  - **Defer** — leave a note in the final summary, no change now.

Before asking, verify the finding yourself by reading the cited code. If it's
wrong, say so in the question and recommend **Skip**.

Act on the answer before moving to the next finding: make the edit, or note
the skip/defer. If the user types something under "Other", follow it.

## Step 6: Summary

One line per finding: `#N — fixed | skipped | deferred — <short note>`.
Don't commit unless asked.
