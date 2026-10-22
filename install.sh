#!/usr/bin/env bash
# Symlink every skill in ./skills into ~/.claude/skills.
set -euo pipefail

src="$(cd "$(dirname "$0")" && pwd)/skills"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

for dir in "$src"/*/; do
  name="$(basename "$dir")"
  target="$dest/$name"
  if [ -e "$target" ] && [ ! -L "$target" ]; then
    echo "skip  $name (exists and is not a symlink)"
    continue
  fi
  ln -sfn "${dir%/}" "$target"
  echo "link  $name -> $target"
done
