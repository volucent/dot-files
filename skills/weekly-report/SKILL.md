---
name: weekly-report
description: Write my Slack weekly report of the week's work. Use when the user asks for their weekly report.
argument-hint: "[last — the previous week]"
---

# Weekly Report

A list of what I shipped and moved this week, one bullet per ticket. Scope is work under `~/repos/trend`; leave out personal projects (`~/repos/volucent`).

A week runs Sunday 00:00 to the next Sunday 00:00, local time. The window is the week containing today; when `$ARGUMENTS` is `last`, the week before it. Any other argument: say only `last` is supported, and stop. Work out `<sunday>` and `<next-sunday>` as `YYYY-MM-DD` dates and the local UTC offset (`date +%z`) first, and bound every source below by them.

## 1. Gather

- **Git** — every clone under `~/repos/trend`. Worktrees share their clone's refs, so skip them; clones of the same remote each hold their own local branches, so read every one and dedupe commits by hash.
  ```
  git -C <repo> log --branches --remotes --author="$(git -C <repo> config user.email)" \
    --since="<sunday> 00:00" --until="<next-sunday> 00:00" --no-merges --format="%H %cd %s" --date=short
  ```
  Repos without ticket prefixes (UI, flux/infra) still belong in the report.
- **MRs** — in each GitLab repo with commits:
  ```
  glab mr list --author=@me --all --order updated_at -P 100 -F json
  ```
  Keep MRs whose `updated_at` falls in the window, and read `state` and `merged_at` from the same output.
- **Linear** — `list_issues` with `assignee: "me"` and `updatedAt: "<sunday>T00:00:00<offset>"`. Then `get_issue` every ticket ID from commits or MRs that the list did not return. Keep a ticket when its `createdAt`, `startedAt`, `completedAt` or `canceledAt` falls in the window, or when it has a commit or MR in the window; a bare `updatedAt` bump is not work.
- **Claude sessions** — `list_sessions` with `include_archived: true` and a `limit` high enough to reach `<sunday>`. Keep sessions whose `cwd` is under `~/repos/trend` and whose `lastActivityAt`, converted from UTC to local time, falls in the window. Titles surface investigations, incidents and reviews that left no commit; search a transcript only when a title is too vague to place.

Done when every ticket ID, every untagged commit theme and every in-window session under `~/repos/trend` is on one list with its status.

## 2. Write

Follow this sample exactly; it is plain text for Slack:

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

- **Sections** — one header line per repo family (`fin-plat` → Finance Platform), whatever the ticket's Linear team; blank line, then `* ` bullets. One section is normal.
- **Bullets** — ticket ID first, then a lowercase summary in the voice of the MR title, short enough for one Slack line. Untagged work gets the summary alone.
- **Merge** related tickets into one bullet as `FP-A / FP-B / FP-C <combined summary>`: a docs cleanup series, an incident response, tooling tweaks.
- **Status** — as of now. The MR decides; Linear decides only for tickets with no MR.
  - merged MR, or pushed straight to the default branch → bare
  - any MR still open → `(MR open)`
  - started ticket with no MR → `WIP`
  - closed unmerged MR, or canceled ticket → only inside a bullet that says what replaced it (e.g. "covered by role guard")
  - ticket not started (Todo, Backlog) → left out
- **Order** — product work first, then incidents and security, then infra, tooling and docs.

Output only the report. When a source could not be read (tool missing, MCP disconnected), add one last line naming it.
