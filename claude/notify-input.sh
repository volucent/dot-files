#!/bin/bash
# Notify user when Claude Code needs input.
# Used as a Stop hook in Claude Code settings.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
INPUT=$(cat)
SESSION_ID=$(echo "$INPUT" | jq -r '.session_id // empty' 2>/dev/null)

NAME=$(bash "$SCRIPT_DIR/session-name.sh" "$SESSION_ID")

notify-send -u normal -h int:transient:1 "Claude Code" "$NAME needs you"
printf '\a'
