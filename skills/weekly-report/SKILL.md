---
name: weekly-report
description: Write the Slack weekly check-in report of my work from git, GitLab MRs, Linear and Claude sessions. Use when the user asks for a weekly report or check-in.
argument-hint: "[last — the previous week]"
---

# Weekly Report

A Slack-ready list of what I shipped and moved this week, one bullet per ticket. Scope is work under `~/repos/trend`; leave out personal projects (`~/repos/volucent`).

A week runs Sunday 00:00 to the next Sunday 00:00, local time. The window is the week containing today; when `$ARGUMENTS` is `last`, the week before it. Work out `<sunday>` and `<next-sunday>` as `YYYY-MM-DD` dates first, and bound every source below by them.

## 1. Gather

Collect every source before writing; each one catches work the others miss.

- **Git** — for every repo under `~/repos/trend` (worktrees and clones of the same remote count once), my commits on all branches:
  ```
  git -C <repo> log --all --author="$(git config user.name)" --since="<sunday> 00:00" --until="<next-sunday> 00:00" --no-merges --format="%ad %s" --date=short
  ```
  Repos without ticket prefixes (UI, flux/infra) still belong in the report.
- **MRs** — `glab mr list --author=@me --all` in each GitLab repo with commits, then `glab mr view <iid>` for any MR touched this week to learn merged / open / closed.
- **Linear** — `list_issues` with `assignee: "me"`, `updatedAt: "<sunday>"`: status per ticket, and tickets filed this week that have no commits yet. It has no upper bound, so for a `last` week drop tickets whose only activity is after `<next-sunday>`.
- **Claude sessions** — `list_sessions` with `include_archived: true` and a `limit` high enough to reach `<sunday>`. A session's `lastActivityAt` is UTC: convert it to local time, then keep the ones inside the window. For a `last` week, a session still active after `<next-sunday>` counts when its title or branch matches work from the window. Titles surface investigations, incidents and reviews that left no commit; search a transcript only when a title is too vague to place.

Done when every ticket ID and every untagged commit theme from the window is on one list with its status.

## 2. Write

Follow this sample exactly — plain text, pastes cleanly into Slack:

```
Finance Platform

* FP-548 enforce plaid identity match at cash-out (MR open)
* FP-551 hide cash advance transfers without external ids from users
* FP-552 / FP-559 halve eslint run time, keep lint runs out of other agent worktrees
* BE-59 cap prisma postgres pool with PRISMA_POOL_SIZE for workers and transaction-sync
* web signup moved to new phone verify endpoints
* staging db reset script
```

- **Sections** — one header line per product (Linear team or repo family), blank line, then `* ` bullets. One section is normal.
- **Bullets** — ticket ID first, then a lowercase summary in the voice of the MR title, short enough for one Slack line. Untagged work gets the summary alone.
- **Merge** related tickets into one bullet as `FP-A / FP-B / FP-C <combined summary>`: a docs cleanup series, an incident response, tooling tweaks.
- **Status** — merged work is bare. Mark `(MR open)` for an unmerged MR and `WIP` for started work with no MR. A canceled ticket appears only inside a merged bullet that explains it (e.g. "covered by role guard").
- **Order** — product work first, then incidents and security, then infra, tooling and docs.

Output only the report: no preamble, date header or sign-off.
