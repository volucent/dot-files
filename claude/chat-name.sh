#!/bin/bash
# SessionStart hook (matcher: startup). Injects the chat-naming rules and the
# session start time into context for sessions under ~/repos.
# Subagents don't fire SessionStart, so they never propose names.

INPUT=$(cat)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
case "$CWD" in
  "$HOME/repos"|"$HOME/repos/"*) ;;
  *) exit 0 ;;
esac

START=$(date +'%m/%d %H:%M')

cat <<EOF
Chat naming. Session start time: $START.
In your first response, propose a name: the line \`Suggested name:\` then a fenced code block tagged \`text\` holding only \`/rename <name>\` (copyable in one click; not \`bash\`, whose Run button would send it to a shell), then carry on. Never wait for the rename.
- Format: \`<ID> <action> <MM/DD HH:mm>\`. ID is the ticket (e.g. FP-123), else the MR (\`MR !1234\`), else omitted. Action is lowercase and brief (\`review\`, \`fix login redirect\`); with no ID the action alone must say what is done (\`review payments branch\`).
- The timestamp is the start time above and never changes.
- If this chat came from a handoff doc that carries a name, reuse that name and its timestamp exactly.
- When the ticket (or, without one, the MR) this work belongs to is found or created mid-chat, propose a rename with it as the ID. Tickets mentioned only as context don't count.
Examples: \`FP-123 review 11/03 14:05\`, \`MR !1234 review 11/03 09:30\`, \`fix login redirect loop 11/03 11:15\`, \`investigate qa-staging slow query 11/03 16:42\`.
EOF
