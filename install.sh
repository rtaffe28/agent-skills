#!/usr/bin/env bash
# Symlink skills into ~/.claude/skills.
#   ./install.sh            install every group (phave, ...)
#   ./install.sh phave      install only the named group(s)
set -euo pipefail

root="$(cd "$(dirname "$0")" && pwd)"
dest="${CLAUDE_SKILLS_DIR:-$HOME/.claude/skills}"
mkdir -p "$dest"

if [ "$#" -gt 0 ]; then
  groups=("$@")
else
  groups=()
  for g in "$root"/*/skills; do groups+=("$(basename "$(dirname "$g")")"); done
fi

for group in "${groups[@]}"; do
  src="$root/$group/skills"
  [ -d "$src" ] || { echo "no such group: $group" >&2; exit 1; }
  for dir in "$src"/*/; do
    name="$(basename "$dir")"
    target="$dest/$name"
    if [ -e "$target" ] && [ ! -L "$target" ]; then
      echo "skip  $group/$name (exists and is not a symlink)"
      continue
    fi
    ln -sfn "${dir%/}" "$target"
    echo "link  $group/$name -> $target"
  done
done
