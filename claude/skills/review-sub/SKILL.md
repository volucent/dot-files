---
name: review-sub
description: Spin up a fresh sub-agent (on a chosen model) to review the current branch against master, then either walk the user through each finding one by one, or (--no-prompt) summarize and ask once which fixes to apply.
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
- **Mode** — default is **prompt** (step 5a). `--no-prompt` (or phrasing
  like "no prompt", "don't ask one by one") → **no-prompt** (step 5b).

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

## Step 4: Verify and show the findings

Before presenting, check each finding yourself against the cited code. Mark
any you think is wrong as such — don't silently drop it.

Print the list (numbered, ranked by severity). If it's clean, say so in one
line and stop.

## Step 5a: Prompt mode — one by one

Go through the findings in order, one at a time. For each, call
`AskUserQuestion` with a single question:

- Question: `#N <severity> file:line — <issue>`
- Options (first one is your recommendation, marked `(Recommended)`):
  - **Fix** — apply the suggested resolution (concrete preview of the change
    in `preview`).
  - **Alternative fix** — only when there's a real second approach.
  - **Skip** — not an issue / won't fix.
  - **Defer** — no change now; note it in the summary.

Treat it as a conversation, not a form. If the user answers under "Other",
asks a question, or pushes back, discuss it until the finding is settled,
then act on the decision (make the edit, or note skip/defer) before moving to
the next finding.

## Step 5b: No-prompt mode — one question

Behave like a normal review reply: no per-finding questions. Summarize, e.g.
"Found 5 issues. #1, #2 and #5 are easy fixes; #3 needs a decision on X; #4
looks like a false positive." Then ask **one** question — whether to apply
the easy fixes — and wait. Do what the user answers; don't edit before that.

## Step 6: Summary

After acting, one line per finding: `#N — fixed | skipped | deferred —
<short note>`. Don't commit unless asked.
