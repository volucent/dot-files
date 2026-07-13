#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "$0")" && pwd)"
MATT_POCOCK_SKILLS="../../mattpocock/skills"
MATT_POCOCK_ENGINEERING_SKILLS="$DOTFILES/$MATT_POCOCK_SKILLS/skills/engineering"

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

link_matt_pocock_engineering_skills() {
  if [ ! -d "$MATT_POCOCK_ENGINEERING_SKILLS" ]; then
    echo "Skipping Matt Pocock engineering skills: $MATT_POCOCK_ENGINEERING_SKILLS not found"
    return
  fi

  for skill_dir in "$MATT_POCOCK_ENGINEERING_SKILLS"/*; do
    [ -d "$skill_dir" ] || continue
    [ -f "$skill_dir/SKILL.md" ] || continue

    local skill
    local rel_skill
    skill="$(basename "$skill_dir")"
    rel_skill="$MATT_POCOCK_SKILLS/skills/engineering/$skill"

    link "$rel_skill" ~/.claude/skills/$skill
    link "$rel_skill" ~/.agents/skills/$skill
    link "$rel_skill" ~/.codex/skills/$skill
  done
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
link claude/CLAUDE.md ~/.claude/CLAUDE.md
link claude/statusline-command.sh ~/.claude/statusline-command.sh
link claude/notify-input.sh ~/.claude/notify-input.sh
link claude/session-name.sh ~/.claude/session-name.sh
mkdir -p ~/.claude/skills/weekly-report
link skills/weekly-report/SKILL.md ~/.claude/skills/weekly-report/SKILL.md
link claude/skills/create-mr.md ~/.claude/skills/create-mr.md
link claude/skills/new-task.md ~/.claude/skills/new-task.md
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
link skills/weekly-report ~/.agents/skills/weekly-report
link skills/weekly-report ~/.codex/skills/weekly-report
if [ ! -d "$MATT_POCOCK_ENGINEERING_SKILLS/grill-with-docs" ]; then
  link skills/grill-with-docs ~/.claude/skills/grill-with-docs
  link skills/grill-with-docs ~/.agents/skills/grill-with-docs
  link skills/grill-with-docs ~/.codex/skills/grill-with-docs
fi

# Matt Pocock engineering skills (shared between Claude and agent roots)
link_matt_pocock_engineering_skills

# LLM modes (shared between Claude and Codex)
for mode in drive plan build review; do
  link "skills/$mode/SKILL.md" ~/.claude/skills/$mode.md
  link "skills/$mode" ~/.agents/skills/$mode
  link "skills/$mode" ~/.codex/skills/$mode
done

echo "Done."
