#!/usr/bin/env bash
# PreToolUse hook for orchestrator workers (matcher Bash|Edit|Write|NotebookEdit).
#
# Silent for every session except a registered worker. A session becomes a worker the
# first time it calls a tool from a .claude/worktrees/ checkout on a branch containing
# fp-NNN, where FP-NNN was registered with `orch start`. Its session_id is then pinned to
# the ticket, so switching branch, detaching HEAD or cd-ing elsewhere doesn't shake it off.
#
# It is a backstop for honest mistakes, not a security boundary: a determined command can
# hide from any pattern check (for example inside a double-quoted $(...)).
# Exit 2 blocks the call and shows stderr to the worker. Bash 3.2 compatible.
set -uo pipefail
ORCH_HOME="${ORCH_HOME:-$HOME/.claude/orchestrator}"
T_DIR="$ORCH_HOME/tickets"

any_tickets() { ls -d "$T_DIR"/FP-*/ >/dev/null 2>&1; }
input="$(cat)"

# Can't tell who's calling without jq or valid JSON: fail closed only while workers exist.
if ! command -v jq >/dev/null 2>&1 || ! jq -e . >/dev/null 2>&1 <<<"$input"; then
  if any_tickets; then
    echo "BLOCKED by worker guard: jq missing or hook input unreadable while orchestrator tickets are registered. Fix jq, or run 'orch done' on finished tickets." >&2
    exit 2
  fi
  exit 0
fi
any_tickets || exit 0

sid="$(jq -r '.session_id // empty' <<<"$input")"
cwd="$(jq -r '.cwd // empty' <<<"$input")"

# --- who is this? -------------------------------------------------------------
t=""
if [ -n "$sid" ]; then
  for f in "$T_DIR"/FP-*/sessions; do
    [ -e "$f" ] || continue
    if grep -qxF "$sid" "$f"; then t="$(basename "$(dirname "$f")")"; break; fi
  done
fi
if [ -z "$t" ]; then
  [[ "$cwd" == */.claude/worktrees/* ]] || exit 0
  b="$(git -C "$cwd" branch --show-current 2>/dev/null | tr '[:upper:]' '[:lower:]')"
  [[ "$b" =~ (^|[^a-z0-9])fp-([0-9]+)([^0-9]|$) ]] || exit 0
  t="FP-${BASH_REMATCH[2]}"
  [ -e "$T_DIR/$t/worker" ] || exit 0
  [ -n "$sid" ] && echo "$sid" >>"$T_DIR/$t/sessions"
fi
tnum="${t#FP-}"

block() {
  echo "BLOCKED by worker guard ($t): $1. Don't work around it. End your turn with a '$t · approval' or '$t · blocked' report instead." >&2
  exit 2
}

# --- file tools ----------------------------------------------------------------
tool="$(jq -r '.tool_name // empty' <<<"$input")"
case "$tool" in
  Edit|Write|NotebookEdit)
    path="$(jq -r '.tool_input.file_path // .tool_input.notebook_path // empty' <<<"$input")"
    [[ "$path" == "$ORCH_HOME"* || "$path" == *"/.claude/orchestrator"* ]] && block "orchestrator files are off limits"
    [[ "$path" =~ \.env[^/]*production ]] && block "production env files are off limits"
    exit 0 ;;
  Bash) ;;
  *) exit 0 ;;
esac

cmd="$(jq -r '.tool_input.command // empty' <<<"$input")"
[ -z "$cmd" ] && exit 0

# --- checks on the raw command (paths can hide anywhere) -----------------------
shopt -s nocasematch
[[ "$cmd" =~ \.claude/orch || "$cmd" =~ (~|\$HOME|\$\{HOME\}|/Users/[^/[:space:]]+)/\.c[^/[:space:]]*/o ]] && block "orchestrator files are off limits"
[[ "$cmd" =~ \.env[^/[:space:]]*production ]] && block "production env files are off limits"
shopt -u nocasematch

# --- split into simple commands ------------------------------------------------
# Drop heredoc bodies and quoted strings (so commit messages and grep patterns don't trip
# rules), then split on ; && || | newlines ( ) $( and backticks.
segments="$(perl -0777 -e '
  my $s = do { local $/; <STDIN> };
  $s =~ s/(<<-?\s*([\x27"]?)(\w+)\2)([^\n]*)\n.*?\n[ \t]*\3[ \t]*(?=\n|$)/H$4/gs;
  my ($o, $q, $esc) = ("", "", 0);
  for my $c (split //, $s) {
    if ($q eq "\x27") { if ($c eq "\x27") { $q = ""; $o .= "Q" } next }
    if ($q eq "\"") {
      if ($esc) { $esc = 0; next }
      if ($c eq "\\") { $esc = 1; next }
      if ($c eq "\"") { $q = ""; $o .= "Q" }
      next;
    }
    if ($c eq "\x27" || $c eq "\"") { $q = $c; next }
    $o .= $c;
  }
  $o =~ s/(\&\&|\|\||[;|\n()`]|\$\()/\n/g;
  print $o;
' <<<"$cmd")"

own_branch() { git -C "$1" branch --show-current 2>/dev/null; }

check_git() { # args after "git"
  local dir="$cwd" sub=""
  while [ $# -gt 0 ]; do
    case "$1" in
      -C) dir="$(cd "$cwd" 2>/dev/null && cd "${2:-.}" 2>/dev/null && pwd)"; dir="${dir:-$cwd}"; shift 2 ;;
      -c|--git-dir|--work-tree|--namespace) shift 2 ;;
      -*) shift ;;
      *) sub="$1"; shift; break ;;
    esac
  done
  local a
  for a in "$@"; do [ "$a" = "--no-verify" ] && block "--no-verify skips the repo's hooks"; done
  case "$sub" in
    push)
      local own; own="$(own_branch "$dir")"
      [[ "$(tr '[:upper:]' '[:lower:]' <<<"$own")" =~ (^|[^a-z0-9])fp-$tnum([^0-9]|$) ]] \
        || block "you can only push your own $t branch, and the current branch is '${own:-detached HEAD}'"
      local pos=() skipnext=""
      for a in "$@"; do
        if [ -n "$skipnext" ]; then skipnext=""; continue; fi
        case "$a" in
          -f|--force|--force-with-lease*|--force-if-includes|--mirror|--all|--tags|--delete|-d|--prune)
            block "git push $a: push only your own branch, without force" ;;
          -o|--push-option|--repo|--receive-pack|--exec) skipnext=1 ;;
          -*) ;;
          *) pos+=("$a") ;;
        esac
      done
      local i src dst
      for ((i = 1; i < ${#pos[@]}; i++)); do
        a="${pos[$i]}"
        [[ "$a" == +* ]] && block "force refspec '$a'"
        if [[ "$a" == *:* ]]; then src="${a%%:*}"; dst="${a#*:}"; else src="$a"; dst="$a"; fi
        [ -z "$src" ] || [ -z "$dst" ] && block "deleting a remote branch"
        [ "$dst" = "HEAD" ] && dst="$own"
        dst="${dst#refs/heads/}"
        [ "$dst" = "$own" ] || block "you can only push to your own branch '$own', not '$dst'"
      done ;;
    branch)
      for a in "$@"; do
        case "$a" in -d|-D|--delete|-f|--force|-M|-C) block "git branch $a (deleting or force-moving branches)" ;; esac
      done ;;
    reset) for a in "$@"; do [ "$a" = "--hard" ] && block "git reset --hard throws work away"; done ;;
    clean) for a in "$@"; do [[ "$a" =~ ^-[a-zA-Z]*f ]] && block "git clean -f throws work away"; done ;;
    commit) for a in "$@"; do [ "$a" = "-n" ] && block "git commit -n skips the repo's hooks"; done ;;
    filter-branch|filter-repo|update-ref) block "git $sub rewrites refs" ;;
  esac
}

check_glab() { # args after "glab"
  local a
  case "${1:-} ${2:-}" in
    "api "*) block "glab api (raw API calls)" ;;
    "mr merge"|"mr approve") block "merging or approving MRs is yours" ;;
    "mr create"|"mr new")
      for a in "$@"; do case "$a" in --draft|--wip) return 0 ;; esac; done
      block "open the MR as a draft (add --draft); the orchestrator marks it ready on your go" ;;
    "mr update")
      for a in "$@"; do
        case "$a" in -r|--ready|--draft=false|--wip=false) block "only the orchestrator takes an MR out of draft" ;; esac
      done ;;
    "ci run"|"ci run-trig"|"ci trigger"|"ci retry") block "starting CI jobs (manual jobs deploy)" ;;
    "release "*|"variable "*) block "glab ${1} changes project settings" ;;
  esac
}

while IFS= read -r seg; do
  # shellcheck disable=SC2086
  set -f; set -- $seg; set +f
  # skip env assignments and wrappers
  while [ $# -gt 0 ]; do
    case "$1" in
      *=*) [[ "$1" =~ ^[A-Za-z_][A-Za-z0-9_]*= ]] && { shift; continue; }; break ;;
      sudo|command|exec|time|nohup|env|then|do|else|"!"|"{") shift ;;
      *) break ;;
    esac
  done
  [ $# -eq 0 ] && continue
  w="$(basename -- "$1")"; shift
  case "$w" in
    npx|bunx|pnpx) [ $# -gt 0 ] || continue; w="$(basename -- "$1")"; shift ;;
  esac
  case "$w" in
    git) check_git "$@" ;;
    glab) check_glab "$@" ;;
    rm) for a in "$@"; do [[ "$a" =~ ^-[a-zA-Z]*[rR] || "$a" == "--recursive" ]] && block "recursive rm"; done ;;
    psql|mysql|mongosh|redis-cli) block "database clients" ;;
    kubectl|helm|terraform) block "cluster and infra tools" ;;
    eval) block "eval hides the real command from the guard; run it directly" ;;
    bash|sh|zsh) for a in "$@"; do [ "$a" = "-c" ] && block "$w -c hides the real command from the guard; run it directly"; done ;;
    prisma)
      case "${1:-} ${2:-}" in
        "migrate deploy"|"migrate reset"|"migrate resolve"|"db push"|"db execute"|"db seed")
          block "prisma $1 $2 applies changes to a database" ;;
      esac ;;
    npm|pnpm|yarn)
      if [ "${1:-}" = "run" ] || [ "${1:-}" = "run-script" ]; then shift; fi
      case "${1:-}" in start:migrator|migrate*) block "npm run ${1} applies migrations" ;; esac ;;
  esac
done <<<"$segments"
exit 0
