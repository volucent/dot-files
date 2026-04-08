#!/usr/bin/env bash

input=$(cat)

# Working directory (basename only)
cwd=$(echo "$input" | jq -r '.workspace.current_dir // empty')
if [ -n "$cwd" ]; then
  parent=$(dirname "$cwd")
  base=${cwd##*/}
  if [ "$parent" != "/" ] && [ -n "$parent" ]; then
    dir_str="${parent##*/}/$base"
  else
    dir_str="$base"
  fi
else
  dir_str=""
fi

# Git branch + dirty marker
git_dir=$(echo "$input" | jq -r '.workspace.current_dir // empty')
git_branch=$(git -C "$git_dir" --no-optional-locks branch --show-current 2>/dev/null)
if [ -n "$git_branch" ]; then
  dirty=$(git -C "$git_dir" --no-optional-locks status --porcelain 2>/dev/null | head -1)
  [ -n "$dirty" ] && branch_str="[${git_branch}*]" || branch_str="[${git_branch}]"
else
  branch_str=""
fi

# Context window usage
used_pct=$(echo "$input" | jq -r '.context_window.used_percentage // empty')
[ -n "$used_pct" ] && ctx_str="${used_pct}%" || ctx_str=""

# API cost
cost=$(echo "$input" | jq -r '.cost.total_cost_usd // empty')
if [ -n "$cost" ]; then
  cost_str="\$$(printf '%.2f' "$cost")"
else
  cost_str=""
fi

# Model - short name (e.g. "opus" from "claude-opus-4-6[1m]")
model=$(echo "$input" | jq -r '.model.id // empty' | sed 's/^claude-//; s/-[0-9].*$//')
[ -n "$model" ] && model_str="$model" || model_str=""

# Effort level (from settings, not in payload — read from config)
effort=$(jq -r '.effortLevel // empty' ~/.claude/settings.json 2>/dev/null)
[ -n "$effort" ] && effort_str="$effort" || effort_str=""

# Model.effort combined
if [ -n "$model_str" ] && [ -n "$effort_str" ]; then
  model_effort="${model_str}.${effort_str}"
elif [ -n "$model_str" ]; then
  model_effort="$model_str"
else
  model_effort=""
fi

# Assemble: dir[branch*] ctx cost model.effort
parts=()
loc="${dir_str}${branch_str}"
[ -n "$loc"          ] && parts+=("$loc")
[ -n "$ctx_str"      ] && parts+=("$ctx_str")
[ -n "$cost_str"     ] && parts+=("$cost_str")
[ -n "$model_effort" ] && parts+=("$model_effort")

IFS=' '
echo "${parts[*]}"
