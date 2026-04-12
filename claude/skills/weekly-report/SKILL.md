---
name: weekly-report
description: Generate a weekly check-in report from git history. Outputs a concise bullet list of what happened this week.
argument-hint: [optional: number of days to look back, default 7]
allowed-tools: Bash, Read, Glob, Grep
---

# Weekly Report

Generate a brief bullet-point summary of work done this week for the team check-in.

## Step 1: Gather git history

Run the following to get commits from the past week (or `$ARGUMENTS` days if provided, default 7):

```
git log --author="$(git config user.name)" --since="$DAYS days ago" --oneline --no-merges
```

Also run:
```
git log --author="$(git config user.name)" --since="$DAYS days ago" --no-merges --format="%s"
```

## Step 2: Group and summarize

- Group commits by theme (feature, fix, infra, cleanup, etc.)
- Collapse related commits into a single bullet (e.g. 5 commits about retry logic = 1 bullet)
- Drop noise: version bumps, typo fixes, trivial formatting — unless that's all there is

## Step 3: Output the report

Output using markdown

```
*Week of <Mon DD - Mon DD>*
_Repository Title_
<entry>
<entry>
<entry>
```

Example 

```
Jan 1 - Jan 7

Emailing Platform
Migrated psql subscription tables to small int channel ids for future-proofing
Implemented channel tuples on psql emails table + backfilled

Marketing Platform
Worked with on simplifying prisma 7 + pglite setup
Fixed new repayment orchestration logic to correctly handle M-Th

General
Debugged stripe scraper
```

Rules:
- Use plain language, no jargon inflation ("added X" not "implemented a robust X solution")
- No preamble, no sign-off, no "let me know if you have questions"
- Just the list
