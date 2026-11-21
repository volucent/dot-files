---
name: weekly-report
description: Write the user's Slack weekly report when they ask for it.
argument-hint: "[last — the previous week]"
---

# Weekly Report

A list of what the user shipped and moved this week, one bullet per ticket, covering work under `~/repos/trend`.

## 0. Window

A week runs Sunday 00:00 to the next Sunday 00:00, local time. Report the week containing today, or the week before when the user asks for last week (argument `last`). For any other range, say only this week and last week are supported, and stop.

Get the dates from the shell, not by hand:

```
s=$(date -v-$(date +%w)d +%F)              # this week's Sunday; GNU: date -d "-$(date +%w) days" +%F
date -j -v+7d -f %F "$s" +%F               # GNU: date -d "$s +7 days" +%F
date -j -v-7d -f %F "$s" +%F               # GNU: date -d "$s -7 days" +%F
date +%z                                   # <offset>; write a leading + as %2B inside a URL
```

This week: `<sunday>` is `$s` and `<next-sunday>` is `$s` + 7 days. Last week: `<sunday>` is `$s` − 7 days and `<next-sunday>` is `$s`.

Git takes `<sunday> 00:00` as local time. Every other source returns UTC timestamps (`…Z`); compare those against `<sunday>T00:00:00<offset>` and `<next-sunday>T00:00:00<offset>`, never against the bare date.

## 1. Gather

- **Git** — every clone under `~/repos/trend`. Worktrees share their clone's refs, so skip them; clones of the same remote each hold their own local branches, so read every one and dedupe commits by hash.
  ```
  git -C <repo> log --branches --remotes --source --author="$(git -C <repo> config user.email)" \
    --since="<sunday> 00:00" --until="<next-sunday> 00:00" --no-merges --format="%h %S %cd %s" --date=short
  ```
  Then list the default-branch commits on their own with the same command, `origin/HEAD` in place of `--branches --remotes --source`. For these, ignore `%S` (it often names a stale, unrelated branch): take the ticket from the subject only, and count them as pushed to the default branch. Every other commit is branch work; `%S` names a branch that holds it, so one with no ticket in its subject takes the ticket in that branch name or its MR.
- **MRs** — one call covers every GitLab project; run it inside any GitLab clone under `~/repos/trend` so glab picks the right host:
  ```
  glab api "merge_requests?scope=created_by_me&state=all&updated_after=<sunday>T00:00:00<offset>&per_page=100" \
    | jq -r '.[] | [.references.full, .state, .source_branch, .created_at, .merged_at, .closed_at, .title] | @tsv'
  ```
  An MR is work in the window when its `created_at`, `merged_at` or `closed_at` falls in it. Every listed MR also feeds status for the ticket or branch it matches.
- **Linear** — `list_issues` with `assignee: "me"` and `updatedAt: "<sunday>T00:00:00<offset>"`. Then `get_issue` every ticket ID from commits or MRs that the list did not return; when the looked-up title plainly does not fit the work (a typo'd ID), the work joins its related bullet or goes untagged, and the wrong ID appears only in the closing line. Keep a ticket when it has a commit, MR or session in the window, or when its `startedAt` falls in it. A ticket only closed in the window (`completedAt`, nothing else) folds into the bullet of the ticket whose work closed it, or is left out; a bare `updatedAt` bump is not work.
- **Claude sessions** — `list_sessions` with `include_archived: true` and a `limit` high enough to reach `<sunday>`. Keep sessions whose `cwd` is under `~/repos/trend` and whose `lastActivityAt` falls in the window. Sessions have no start time, so for last week also look at sessions active after the window and keep those whose MR, branch or title places their work inside it. A session folds into the ticket bullet it worked on: match it by `prNumber` or `branch` first, then by title. A session run in a main checkout carries whatever MR was checked out, so when its title plainly does not fit that MR, the title wins. It earns its own bullet only when it is an investigation, incident or review with an outcome worth telling the team; setup, how-to and tooling chats are dropped. Search a transcript only when a title is too vague to place.

Done when every ticket, every untagged commit, every in-window MR and every in-window session is placed: headed for a bullet, or dropped by a rule in this file (the Status rules below drop some).

## 2. Write

Output the report in one code block, following this sample exactly:

```
Finance Platform

* FP-548 enforce plaid identity match at cash-out (MR open)
* FP-551 hide cash advance transfers without external ids from users
* FP-430 plaid mobile states WIP
* investigated nov 20 account takeover attempts
* FP-564 / FP-565 lock down offer-promotion pushes (covered by role guard), cap verification code guesses
* FP-563 reject plaid webhooks that plaid did not sign (MR open)
* BE-59 cap prisma postgres pool with PRISMA_POOL_SIZE for workers and transaction-sync
* staging db reset script
* FP-552 / FP-559 halve eslint run time, keep lint runs out of other agent worktrees
```

- **Sections** — one header line per repo folder under `~/repos/trend`, whatever the ticket's Linear team: `fin-plat` → Finance Platform, `email-plat` → Email Platform, `pfm` → PFM, `rev-pie` → Rev Pie, `hey-pros` → Hey Pros, `ci` → CI, `exp` → Exp, `trend` → Trend. Work with no repo (a ticket with no commit or MR) goes under its Linear team's name. Header, blank line, `* ` bullets; a blank line between sections. One section is normal.
- **Bullets** — ticket ID first, then a lowercase summary in the voice of the MR title, short enough for one Slack line. Untagged work gets the summary alone: untagged commits group into one bullet per piece of work, and a commit undone by its own revert, or an operational toggle (scaling an environment down and back up, reverting an auto-release), is dropped.
- **Merge** related tickets into one bullet as `FP-A / FP-B / FP-C <combined summary>`: a docs cleanup series, an incident response, tooling tweaks. Only tickets with the same status merge (a folded canceled ticket aside); keep a related ticket with a different status as its own bullet next to them.
- **Status** — as of now. Apply these top-down; the first match wins.
  1. canceled ticket → when it had work in the window, fold it into the related bullet with the reason it was dropped in parentheses, as FP-564 in the sample; otherwise left out
  2. ticket not started (Todo, Backlog) → left out
  3. any MR still open → `(MR open)`
  4. merged MR, pushed straight to the default branch, completed ticket, or a ticketless session bullet → bare, even while Linear still says started
  5. anything else (a started ticket or branch work whose MRs, if any, are all closed) → `WIP`
- **Order** — product work first, then incidents and security, then infra, tooling and docs.

After the code block, add one line naming any source that could not be read (tool missing, MCP disconnected); when the window holds no work, say so and suggest last week.
