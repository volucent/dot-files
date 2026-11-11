---
name: quiz
description: Settle open judgement calls by putting them to the user as multiple-choice questions. Use when the user says "quiz me" about findings, review comments, spec or ticket gaps, or any other decisions still pending.
argument-hint: '[optional: which findings or topic to quiz on]'
---

# Quiz

Turn every open **judgement call** in the conversation into a multiple-choice question, and keep asking until each one has an answer. The user decides; you supply the facts, the options and a recommendation.

## 1. Collect the judgement calls

Build the list from what is already on the table: review findings, spec or ticket ambiguities, implementation trade-offs, "it depends" notes, anything you flagged as uncertain. If the user named a topic, take only the calls under it.

A judgement call qualifies when its answer changes what happens next and only the user can make it. Facts are yours: look them up in code, tickets, logs or docs (dispatch a subagent for a wide search) and fold them into the question as context. Drop calls that have an obvious default nobody would argue with, and say in one line which ones you dropped and what you assumed.

Done when every pending call is either on the list or named as assumed.

## 2. Ask in rounds

The **frontier** is every call whose prerequisites are settled. Ask the whole frontier, highest impact first, with the `AskUserQuestion` tool: up to 4 questions per call, more calls if the frontier is bigger. A call that depends on an answer still open waits for a later round.

Each question **stands alone**, since the dialog may hide everything else, and stays **compact**: three blocks, one blank line between them, bullets instead of prose. Lay out the `question` text like this:

```
[*]  <finding, 3–6 words>  ·  <where>

  • Now:  <what is true now>
  • Risk:  <what goes wrong either way>

-->  <The question itself?>
```

Example:

```
[*]  Retry skips the 16th  ·  repay.scheduler.ts:42

  • Now:  debit cards retry on Thursdays and Fridays only
  • Risk:  users paid on the 16th may wait six days for a retry

-->  Keep the 16th as an extra retry day?
```

- **Where:** a ticket ID or spec section, or `file:line` when the call is about code. Leave it out when the finding names its place on its own.
- **Bullets:** one short clause each. Swap `Risk` for a label that fits better (`Spec`, `Ticket`, `Cost`); add a third bullet only when the call needs it.
- **Code:** any code a bullet mentions carries its `file:line`.

The options carry the same calm:

- **2–4 real options**, your recommendation first with a label ending in `(Recommended)`. "Other" is added automatically.
- **Label:** 1–5 plain words, no punctuation clutter.
- **Description:** one line with the consequence: what changes, what it costs or risks.
- **`preview`** when options differ in code, a schema or wording: show only the lines that differ, with a blank line around them, so the user compares the actual text.
- **`multiSelect`** only when the options can combine.
- **Header:** a 12-character tag for the finding (`Retry days`, `Null guard`).

If `AskUserQuestion` is unavailable, write the round in markdown with the same spacing: a `---` rule between questions, the question under a `### Q1 · <finding>` heading, options as a list with **A.**, **B.** …, and the recommendation marked `(recommended)`. Then wait for the reply.

## 3. Absorb the answers

After each round:

- An "Other" answer or notes that leave the call open get a follow-up question in the next round.
- Answers can settle other calls, make them moot or raise new ones. Update the list and recompute the frontier.
- Look up any fact an answer points at before asking the questions that depend on it.

Repeat step 2 until the frontier is empty: every call on the list answered or made moot.

## 4. Close out

Print a decision list: one line per call, `**<call>** → <choice>`, with a short reason where the user gave one.

Then go back to the task that raised the calls and apply the decisions: implement the fix, edit the spec, update the plan. If that task was only a review or a read, the decision list is the result. Recording the decisions on a ticket or MR goes to an outside system, so offer that and wait for a yes.
