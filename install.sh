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

echo "Installing dotfiles..."

# Fonts
echo "Installing fonts..."
mkdir -p ~/.local/share/fonts
cp "$DOTFILES"/fonts/intel-one-mono/*.ttf ~/.local/share/fonts/
fc-cache -f

# Kitty
link kitty/kitty.conf ~/.config/kitty/kitty.conf

# Claude Code
link claude/settings.json ~/.claude/settings.json
link claude/statusline-command.sh ~/.claude/statusline-command.sh
mkdir -p ~/.claude/skills/weekly-report
link claude/skills/weekly-report/SKILL.md ~/.claude/skills/weekly-report/SKILL.md

echo "Done."
