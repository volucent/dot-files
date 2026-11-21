---
name: weekly-report
description: Write the user's Slack weekly report of the week's work. Use when the user asks for their weekly report.
argument-hint: "[last — the previous week]"
---

# Weekly Report

A list of what I shipped and moved this week, one bullet per ticket. Scope is work under `~/repos/trend`; leave out personal projects (`~/repos/volucent`).

A week runs Sunday 00:00 to the next Sunday 00:00, local time. The window is the week containing today; when `$ARGUMENTS` is `last`, the week before it. Any other argument: say only `last` is supported, and stop. Work out `<sunday>` and `<next-sunday>` as `YYYY-MM-DD` dates and the local UTC offset (`date +%z`) first. Git takes local times directly; every other source returns UTC timestamps (`…Z`), so compare those against `<sunday>T00:00:00<offset>` and `<next-sunday>T00:00:00<offset>`, never against the bare date.

## 1. Gather

- **Git** — every clone under `~/repos/trend`. Worktrees share their clone's refs, so skip them; clones of the same remote each hold their own local branches, so read every one and dedupe commits by hash.
  ```
  git -C <repo> log --branches --remotes --author="$(git -C <repo> config user.email)" \
    --since="<sunday> 00:00" --until="<next-sunday> 00:00" --no-merges --format="%H %cd %s" --date=short
  ```
  Repos without ticket prefixes (UI, flux/infra) still belong in the report.
- **MRs** — once per distinct GitLab remote under `~/repos/trend`, with or without commits this week (git is never fetched, so an MR merged in GitLab can leave no local commit):
  ```
  glab mr list --author=@me --all --order updated_at -P 100 -F json
  ```
  An MR is work in the window when its `created_at`, `merged_at` or `closed_at` falls in it. For status, use every MR in the listing that matches a kept ticket or branch, whatever its dates.
- **Linear** — `list_issues` with `assignee: "me"` and `updatedAt: "<sunday>T00:00:00<offset>"`. Then `get_issue` every ticket ID from commits or MRs that the list did not return. Keep a ticket when its `startedAt`, `completedAt` or `canceledAt` falls in the window, or when it has a commit or MR in the window; a bare `updatedAt` bump is not work.
- **Claude sessions** — `list_sessions` with `include_archived: true` and a `limit` high enough to reach `<sunday>`. Keep sessions whose `cwd` is under `~/repos/trend` and whose `lastActivityAt` falls in the window. Titles surface investigations, incidents and reviews that left no commit; search a transcript only when a title is too vague to place.

Done when every ticket ID, every untagged commit theme and every in-window session under `~/repos/trend` is on one list with its status.

## 2. Write

Output the report in one code block, following this sample exactly:

```
Finance Platform

* FP-548 enforce plaid identity match at cash-out (MR open)
* FP-551 hide cash advance transfers without external ids from users
* FP-552 / FP-559 halve eslint run time, keep lint runs out of other agent worktrees
* BE-59 cap prisma postgres pool with PRISMA_POOL_SIZE for workers and transaction-sync
* FP-430 plaid mobile states WIP
* web signup moved to new phone verify endpoints
* staging db reset script
```

- **Sections** — one header line per repo folder under `~/repos/trend`, whatever the ticket's Linear team: `plat` → Platform, short acronyms upper-cased, the rest title-cased (`fin-plat` → Finance Platform, `email-plat` → Email Platform, `pfm` → PFM, `rev-pie` → Rev Pie). Work with no repo (a ticket with no commit or MR) goes under its Linear team's name. Blank line, then `* ` bullets. One section is normal.
- **Bullets** — ticket ID first, then a lowercase summary in the voice of the MR title, short enough for one Slack line. Untagged work gets the summary alone.
- **Merge** related tickets into one bullet as `FP-A / FP-B / FP-C <combined summary>`: a docs cleanup series, an incident response, tooling tweaks.
- **Status** — as of now. Apply these top-down; the first match wins.
  1. canceled ticket → only inside a bullet that says what replaced it (e.g. "covered by role guard"); otherwise left out
  2. ticket not started (Todo, Backlog) → left out
  3. any MR still open → `(MR open)`
  4. merged MR, pushed straight to the default branch, completed ticket, or session-only work → bare
  5. anything else (a started ticket or untagged branch work whose MRs, if any, are all closed) → `WIP`
- **Order** — product work first, then incidents and security, then infra, tooling and docs.

Output only the report. After the code block, add one line naming any source that could not be read (tool missing, MCP disconnected), and when the window holds no work, say so and suggest `last`.
