# llm

Modes — concise operational instructions for LLM agents (Claude, Codex).

## What's a mode

A md file that tells an agent how to operate in a turn. Not a persona. The
model doesn't need to think it "is" a project manager — it needs precise rules
for what to do and what not to do.

Personas drift after ~100k tokens. Precise rules don't.

## Modes here

- `drive` — orchestrator. Delegates plan/build/review to sub-agents. Doesn't
  read files or write code itself.
- `plan` — reads code, writes a concrete plan, stops.
- `build` — takes a plan, makes the edits, runs tests, returns a diff summary.
- `review` — reads a diff, returns findings ranked by severity, no fixes.

## How they compose

`drive` runs the loop: plan → build → review → loop until done or capped.
Each step is a fresh sub-agent. Only summaries return to drive. The
orchestrator's context stays clean even across 30+ minute runs.

```
user
 └─ drive (clean context, only sees summaries)
     ├─ plan agent  (gone after returning a plan)
     ├─ build agent (gone after returning a diff)
     ├─ review agent (gone after returning findings)
     └─ loop
```

Each master mode can itself spawn focused sub-agents — plan might fan out
research, build might split per-file, review might split per-concern (security,
perf, correctness).

## Installed as skills

Source lives at `llm/modes/`. The install scripts symlink each mode into
`~/.claude/skills/` and `~/.codex/skills/`. Invoke with `/drive`, `/plan`,
`/build`, `/review`.

## Principles

- Concise > verbose. Padding wastes context.
- No personas. "You are a project manager" doesn't help the model and burns
  tokens that compete with the actual task.
- One responsibility per mode. Orchestration lives in `drive`.
- Sub-agents are Mr. Meeseeks — one job, then gone. Context hygiene wins over
  cleverness.
- Hooks become skills. If a phrase is useful enough to repeat, make it a
  callable skill, not a sentence you keep retyping.
