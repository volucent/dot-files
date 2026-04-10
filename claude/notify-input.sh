#!/bin/bash
# Notify user when Claude Code needs input.
# Used as a Stop hook in Claude Code settings.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)
LAST_MSG=$(echo "$INPUT" | jq -r '.last_assistant_message // empty' 2>/dev/null)

NAME=$(bash "$SCRIPT_DIR/session-name.sh" "$SESSION_ID")

# parent/dir format
if [ -n "$CWD" ]; then
  DIR=$(echo "$CWD" | awk -F/ '{if(NF>1) print $(NF-1)"/"$NF; else print $NF}')
else
  DIR=""
fi

# First line of last message, truncated
FIRST_LINE=$(echo "$LAST_MSG" | head -n1 | cut -c1-80)

BODY="${NAME}"
[ -n "$DIR" ] && BODY="$BODY  $DIR"
[ -n "$FIRST_LINE" ] && BODY="$BODY
$FIRST_LINE"

notify-send -u normal -h int:transient:1 "Claude Code" "$BODY"
printf '\a'
