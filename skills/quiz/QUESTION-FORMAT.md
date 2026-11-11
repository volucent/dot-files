# Question format

How to lay out a multiple-choice question for the user. Shared by `/quiz` and `/review-sub`; a change here changes both.

## The question text

Each question **stands alone**, since the dialog may hide everything else, and stays **compact**: three blocks, one blank line between them, bullets instead of prose.

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
- **Bullets:** one short clause each. Swap a label for one that fits better (`Issue`, `Why`, `Spec`, `Ticket`, `Cost`); add a third bullet only when the call needs it.
- **Code:** any code a bullet mentions carries its `file:line`.

## The options

- **2–4 real options**, your recommendation first with a label ending in `(Recommended)`. "Other" is added automatically.
- **Label:** 1–5 plain words, no punctuation clutter.
- **Description:** one line with the consequence: what changes, what it costs or risks.
- **`preview`** when options differ in code, a schema or wording: show only the lines that differ, with a blank line around them, so the user compares the actual text.
- **`multiSelect`** only when the options can combine.
- **Header:** a 12-character tag for the finding (`Retry days`, `Null guard`).

## Without `AskUserQuestion`

Write the questions in markdown with the same spacing: a `---` rule between questions, each question under a `### Q1 · <finding>` heading, options as a list with **A.**, **B.** …, and the recommendation marked `(recommended)`. Then wait for the reply.
