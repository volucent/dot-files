#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"

link() {
  local src="$DOTFILES/$1"
  local dst="$2"

  mkdir -p "$(dirname "$dst")"

  if [ -L "$dst" ]; then
    rm "$dst"
  elif [ -e "$dst" ]; then
    echo "  backup $dst -> ${dst}.bak"
    mv "$dst" "${dst}.bak"
  fi

  ln -s "$src" "$dst"
  echo "  $dst -> $src"
}

echo "Installing dotfiles (macOS)..."

# Fonts (macOS auto-discovers fonts in ~/Library/Fonts; no fc-cache needed)
echo "Installing fonts..."
mkdir -p ~/Library/Fonts
cp "$DOTFILES"/fonts/intel-one-mono/*.ttf ~/Library/Fonts/

# Ghostty (uses XDG path on macOS too)
link ghostty/config ~/.config/ghostty/config

# Zsh (work config; source from your personal ~/.zshrc)
link .zshrc-trend-mac ~/.zshrc-trend

# Claude Code
link claude/settings.json ~/.claude/settings.json
link claude/statusline-command.sh ~/.claude/statusline-command.sh
link claude/notify-input.sh ~/.claude/notify-input.sh
link claude/session-name.sh ~/.claude/session-name.sh
mkdir -p ~/.claude/skills/weekly-report
link claude/skills/weekly-report/SKILL.md ~/.claude/skills/weekly-report/SKILL.md
link claude/skills/create-mr.md ~/.claude/skills/create-mr.md
link claude/skills/new-task.md ~/.claude/skills/new-task.md
mkdir -p ~/.claude/skills/grill-with-docs
link claude/skills/grill-with-docs/SKILL.md ~/.claude/skills/grill-with-docs/SKILL.md
link claude/skills/grill-with-docs/ADR-FORMAT.md ~/.claude/skills/grill-with-docs/ADR-FORMAT.md
link claude/skills/grill-with-docs/CONTEXT-FORMAT.md ~/.claude/skills/grill-with-docs/CONTEXT-FORMAT.md
mkdir -p ~/.claude/skills/caveman
link claude/skills/caveman/SKILL.md ~/.claude/skills/caveman/SKILL.md
mkdir -p ~/.claude/skills/handoff
link claude/skills/handoff/SKILL.md ~/.claude/skills/handoff/SKILL.md
mkdir -p ~/.claude/skills/write-a-skill
link claude/skills/write-a-skill/SKILL.md ~/.claude/skills/write-a-skill/SKILL.md

# Codex
link codex/hooks.json ~/.codex/hooks.json
link codex/notify-input.sh ~/.codex/notify-input.sh
link codex/session-name.sh ~/.codex/session-name.sh
mkdir -p ~/.codex/skills/weekly-report
link codex/skills/weekly-report/SKILL.md ~/.codex/skills/weekly-report/SKILL.md

# LLM modes (shared between Claude and Codex)
for mode in drive plan build review; do
  link "llm/modes/$mode.md" ~/.claude/skills/$mode.md
  link "llm/modes/$mode.md" ~/.codex/skills/$mode/SKILL.md
done

echo "Done."
