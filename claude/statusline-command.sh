#!/usr/bin/env bash

input=$(cat)

# Working directory (basename only)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -n "$cwd" ]; then
  parent=$(dirname "$cwd")
  base=${cwd##*/}
  if [ "$parent" != "/" ] && [ -n "$parent" ]; then
    dir_str="📂${parent##*/}/$base"
  else
    dir_str="📂$base"
  fi
else
  dir_str=""
fi

# Git branch
git_branch=$(git -C "$(echo "$input" | jq -r '.workspace.current_dir // empty')" \
  --no-optional-locks branch --show-current 2>/dev/null)
[ -n "$git_branch" ] && branch_str="🌿$git_branch" || branch_str=""

# Context window usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
[ -n "$used_pct" ] && ctx_str="💭${used_pct}%" || ctx_str=""

# API cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost_str="💲$(printf '%.2f' "$cost")"
else
  cost_str=""
fi

# Model - short name (e.g. "opus" from "claude-opus-4-6[1m]")
model=$(echo "$input" | jq -r '.model.id // empty' | sed 's/^claude-//; s/-[0-9].*$//')
[ -n "$model" ] && model_str="🧠${model}" || model_str=""

# Effort level (from settings, not in payload — read from config)
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
[ -n "$effort" ] && effort_str="⚡${effort}" || effort_str=""

# Assemble
parts=()
[ -n "$dir_str"    ] && parts+=("$dir_str")
[ -n "$branch_str" ] && parts+=("$branch_str")
[ -n "$ctx_str"    ] && parts+=("$ctx_str")
[ -n "$cost_str"   ] && parts+=("$cost_str")
[ -n "$model_str"  ] && parts+=("$model_str")
[ -n "$effort_str" ] && parts+=("$effort_str")

IFS=' '
echo "${parts[*]}"
