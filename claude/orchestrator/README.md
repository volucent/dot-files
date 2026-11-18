# One chat, many tickets: an orchestrator for Claude Code desktop

Status: sketch, Nov 17 2026. `orch` and the guard hook pass scripted tests in a scratch home under macOS's bash 3.2. The end-to-end loop hasn't been run in the app yet. Read "Verified vs. assumed" first. [explainer.html](explainer.html) walks through every part in plain words.

## The idea

- **One main session you talk to**: the orchestrator. It never writes code. It starts workers, shows you their questions and routes your answers.
- **One worker session per ticket**, each in its own desktop worktree. A worker stops at a real decision and ends its turn with a short report, instead of guessing.
- **An attention queue.** Reports from all workers land in one queue. The orchestrator shows them one at a time, labeled: "FP-412 · question · …".
- **You answer in the main chat.** The orchestrator sends your answer to that worker as a cross-session message, and the worker carries on.
- **Rules for when to interrupt**: scope questions, tradeoff choices, gated actions, failing checks a worker can't fix, and "MR ready". Workers decide everything else.
- **MRs:** workers push their own branch and open draft MRs themselves. Your "go" is what takes an MR out of draft, and the orchestrator does that. Merging stays yours.

## What the desktop app gives you for free

| CLI kit | Desktop kit |
|---|---|
| `claude -p` background runs, `--session-id`, `--resume` | `start_session` worker sessions. They stay alive, so there's nothing to resume |
| Worker ends its run with JSON matching a schema | Worker ends its turn with `wrap_up`. The recap is the report |
| Launcher script turns the result into a queue file | The app wakes the orchestrator with a side-session note (first ~400 characters of the worker's turn). The orchestrator queues it with `orch add` |
| `claude -p --resume <id> "HUMAN ANSWER…"` | `SendMessage` to the worker's `local_…` id |
| `say "FP-412 needs you"`, UserPromptSubmit nudge hook | `PushNotification`, which also reaches your phone over Remote Control |
| `git worktree add` + `npm ci` | Worktree made by `start_session` from `master`. The worker renames its branch to the Linear name |
| `--allowedTools` per run, `--go` adds push rights | Workers inherit the orchestrator's permission mode. The guard hook blocks gated commands and non-draft MRs |
| `reviewer` subagent | The worker runs your `code-review` skill before mr-ready |
| `claude --agent orchestrator` | The **Orchestrator** output style on a normal desktop session |
| `/ticket`, `/next`, `/answer`, `/board` skills | Plain speech: "start FP-412 …", "next", "B", "go", "board" |

## Files (in dot-files)

- `claude/output-styles/orchestrator.md`: the orchestrator's persona and procedures. Pick it in the session's Output style menu. As an output style it stays in the system prompt, so compaction can't drop it.
- `claude/skills/ticket-worker/SKILL.md`: the worker protocol, covering when to stop, the report format, draft MRs, and how answers arrive. The repo's AGENTS.md still owns code, commit, check and MR conventions.
- `claude/orchestrator/bin/orch`: the ticket registry and the queue, as plain files under `~/.claude/orchestrator/`. That folder is a real directory, not a link, so queue state never lands in this repo. Commands are `start`, `link`, `add`, `next`, `answered`, `go`, `list`, `board`, `count` and `done`. Report and answer text goes on stdin.
- `claude/orchestrator/hooks/worker-guard.sh`: a PreToolUse hook for Bash, Edit, Write and NotebookEdit.
  - **Who it watches:** a session becomes a worker on its first tool call from a `.claude/worktrees/` checkout whose branch names a ticket that `orch start` registered. Its session ID is then pinned, so switching branch or `cd`-ing elsewhere doesn't shake it off. Every other session passes straight through.
  - **What it blocks for workers:**
    - pushing anything but its own ticket branch, and force pushes
    - non-draft MRs, and un-drafting
    - merging and approving MRs
    - `glab api`, CI triggers, `glab release` and `glab variable`
    - DB clients, and `prisma migrate deploy|reset|resolve` and `prisma db push|execute|seed`
    - `npm run start:migrator` and `migrate*` scripts
    - `kubectl`, `helm` and `terraform`
    - `rm -r`, `reset --hard`, `clean -f`, `--no-verify`
    - `eval` and `bash -c`
    - production `.env` files and the orchestrator's own files
  - **How it reads commands:** it splits each command on `;`, `&&`, `|` and so on, and ignores quoted text and heredoc bodies, so commit messages and greps don't trip it.
  - **Limits:** it's a backstop for honest mistakes, not a security boundary. A command hidden inside a double-quoted `$(…)` gets past it.

## Install

1. `install-mac.sh` links `orch` and the guard into a real `~/.claude/orchestrator/`, and links the output style and the skill.
2. `claude/settings.json` registers the guard as a PreToolUse hook. It allows `orch`, and asks before `orch go` under both the `~/` and the `/Users/pasha/` spellings.
3. Restart the Claude app.
4. Optional: set `ORCH_MAX_WORKERS` (default 4) in your shell profile.

## First run

1. Open a new session on the repo's main checkout (not a worktree, not a separate folder) and name it "Orchestrator". `start_session` cuts worker worktrees from the orchestrator's own repo, so it has to sit in the repo the tickets are for. It passes `source_branch: master`, so it doesn't matter which branch that checkout is on.
2. In the session menu, set **Output style → Orchestrator** and **Permission mode → Auto**. Workers inherit the mode. If the modes differ, the app holds the orchestrator's messages for approval and answers stall.
3. Optional: turn on Remote Control for it, so `PushNotification` reaches your phone.

## Voice walkthrough

1. "Start FP four twelve, soft delete users. Admin can soft-delete, list and API hide them." Reply: "FP-412 started. I'll tell you when it needs you."
2. "Start four fifteen, retry failed webhooks with backoff." Reply: "FP-415 started."
3. Walk away. Your phone buzzes: "FP-412 needs you."
4. "Next." Reply:
   - FP-412 · question
   - Users list and API hide deleted users; the admin export still includes them.
   - Should the export include soft-deleted users?
   - A) Exclude, like the API. B) Include with deleted_at. C) Separate ticket.
   - I'd pick B: support uses it for deletion requests. 1 more waiting.
5. "B." Reply: "Sent to FP-412." Then the next item: "FP-415 · mr-ready · Draft !1130, checks green, review clean. Title: [FP-415] retry failed webhook deliveries with backoff -ad. Go?"
6. "Go." The ask rule on `orch go` pops a confirm box. Say "click Allow". `!1130` comes out of draft. Later: "FP-415 · done · !1130 is ready for review. OK?"
7. "Board" at any time gives one line per ticket.
8. "415 merged." It offers to archive the worker session, which removes its worktree. After you say yes and the archive goes through, it runs `orch done FP-415`.

## Limits

- **Permission prompts inside a worker don't reach you.** A prompt in a worker is not a finished turn, so no note fires. Auto mode plus the guard makes prompts rare. "Board" flags a worker that has been running a long time and links it, and that's the one case where you open the worker.
- **The note is about 400 characters.** That's why the worker's recap holds the whole question, capped at 300. The orchestrator can read the worker's full closing message if you ask for detail.
- **Notes pause after a while.** After a long run of notes with no reply from you, the app stops waking the orchestrator, so no phone ping fires. Say anything and it catches up: on every message it checks idle workers for reports it hasn't queued.
- **The queue lives in files** (`~/.claude/orchestrator/queue/`), so it survives compaction and app restarts. An item you skip comes back once nothing newer is waiting.
- **Approval items aren't delegated.** The guard blocks DB writes and the like even after a yes, so the answer is "I'll do it" or "find another way". That's deliberate: the orchestrator never asks a worker to do what its own permissions would block.
- **One orchestrator at a time.** The queue and ticket list are shared by every repo.
- **Keep it to 3–5 tickets.** Your attention is the bottleneck.

## Verified vs. assumed

Verified from the desktop app's own tool definitions:

- `start_session` takes `use_worktree`, `source_branch`, `branch_name` (the app adds your prefix and a suffix), `name`, `prompt` and `background` (80+ characters), and omitting `permission_mode` inherits the caller's.
- When a started session ends a turn, the starter gets a note with the first ~400 characters of its wrap-up recap and closing message. An idle starter is woken, until a long run of such wake-ups with no user message.
- `wrap_up` takes at most two reply buttons.
- `SendMessage` to a session in a different permission mode is held for that session's user to approve.
- `list_sessions` reports `isRunning` but no "waiting on input" state.
- `archive_session` removes the worktree and asks you first.
- `PushNotification` goes to your phone when Remote Control is on, and skips itself when you're at the screen.
- `glab 1.108`: `mr create --draft`, `mr update --ready` (`-r`), and `new` as an alias of `create`.

Tested in a scratch home:

- **`orch`:**
  - the cap ignores finished tickets
  - go is refused unless an mr-ready report with `!NNN` is waiting
  - a failed `glab` call leaves the item unanswered
  - skipped items come back
  - `$(…)` in report text stays literal
  - same-second items don't collide
- **Guard (68 cases):**
  - It allows the normal push plus draft-MR command, and quoted text mentioning push, main, psql or merge.
  - It blocks pushes to `qa`, `HEAD:refs/heads/master` and another branch after a detach or branch switch, plus `glab mr new` without `--draft`, `--ready`, `start:migrator`, globbed paths into the orchestrator's folder, and `bash -c`.
  - It ignores sessions outside `.claude/worktrees/` and unregistered tickets.
  - It fails closed on unreadable input only while tickets are registered.

Assumed, check on first run:

- The desktop Output style menu lists styles from `~/.claude/output-styles/`, and `keep-coding-instructions: false` is honored.
- PreToolUse hook input carries `session_id` in desktop worker sessions, and subagents a worker spawns share it.
- User-level PreToolUse hooks fire in worktree sessions the app starts. Your existing `lint-on-commit.sh` hook suggests they do.
- The `ask` rule on `orch go` still prompts in Auto mode.
- `git branch -m` inside an app-made worktree doesn't confuse the app's branch or MR tracking.
- `list_events` shows a worker's latest turn well enough for the catch-up sweep.
- Workers reliably end their turn with the report instead of waiting.
