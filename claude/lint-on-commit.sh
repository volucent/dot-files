#!/bin/bash
# PreToolUse hook (matcher: Bash). Before an agent `git commit`, runs the repo's own
# prettier --write and eslint --fix on the files being committed and re-stages them,
# so the fixes land in that same commit.
# - Skips repos without node_modules/.bin/prettier or eslint.
# - Skips partially staged files (re-staging would pull in unstaged hunks).
# - Blocks the commit (exit 2) only when eslint reports errors it can't fix.

INPUT=$(cat)
CMD=$(echo "$INPUT" | jq -r '.tool_input.command // empty' 2>/dev/null)
CWD=$(echo "$INPUT" | jq -r '.cwd // empty' 2>/dev/null)

echo "$CMD" | grep -Eq '(^|[;&|[:space:]])git[[:space:]]+commit([[:space:]]|$)' || exit 0
[ -n "$CWD" ] || exit 0
ROOT=$(git -C "$CWD" rev-parse --show-toplevel 2>/dev/null) || exit 0
cd "$ROOT" || exit 0

PRETTIER="$ROOT/node_modules/.bin/prettier"
ESLINT="$ROOT/node_modules/.bin/eslint"
[ -x "$PRETTIER" ] || [ -x "$ESLINT" ] || exit 0

STAGED=$(git diff --cached --name-only --diff-filter=ACMR)
UNSTAGED=$(git diff --name-only --diff-filter=ACMR)
if echo "$CMD" | grep -Eq 'git[[:space:]]+commit.*[[:space:]](-[a-zA-Z]*a[a-zA-Z]*|--all)([[:space:]]|$)'; then
  # commit -a: tracked changes get committed whole, so they all count as staged.
  STAGED=$(printf '%s\n%s\n' "$STAGED" "$UNSTAGED" | sort -u)
  UNSTAGED=""
fi

FILES=()
while IFS= read -r f; do
  [ -n "$f" ] && [ -f "$f" ] || continue
  echo "$UNSTAGED" | grep -Fxq "$f" && continue
  FILES+=("$f")
done <<< "$STAGED"
[ ${#FILES[@]} -gt 0 ] || exit 0

if [ -x "$PRETTIER" ]; then
  "$PRETTIER" --write --ignore-unknown --log-level warn "${FILES[@]}" >/dev/null 2>&1
fi

LINT_FILES=()
for f in "${FILES[@]}"; do
  case "$f" in *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs|*.mts|*.cts) LINT_FILES+=("$f") ;; esac
done

if [ -x "$ESLINT" ] && [ ${#LINT_FILES[@]} -gt 0 ]; then
  OUT=$("$ESLINT" --fix "${LINT_FILES[@]}" 2>&1)
  STATUS=$?
  git add -- "${FILES[@]}"
  if [ "$STATUS" -eq 1 ]; then
    # 1 = lint errors left after --fix. 2 = config or crash: don't block on that.
    echo "eslint --fix left errors in staged files; fix them, then commit again:" >&2
    echo "$OUT" >&2
    exit 2
  fi
else
  git add -- "${FILES[@]}"
fi
exit 0
