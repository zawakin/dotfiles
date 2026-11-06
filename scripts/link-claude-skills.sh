#!/bin/bash
# Symlink user-scoped agent skills from their own ghq-managed repos into $HOME.
#
# Each skill ships inside its source repo as a directory (e.g. skills/<skill>/
# or .claude/skills/<skill>/). This resolves <repo> to a local path via ghq
# (cloning if missing) and creates symlinks for both Claude Code and agents at:
#   ~/.claude/skills/<skill> -> that directory
#   ~/.agents/skills/<skill> -> that directory
# The links go straight into $HOME, not through a stow package: those
# directories also hold skills the apps sync or create, which must not land in
# this repo. The links are regenerated per machine (ghq paths differ).
#
# A single repo can ship multiple skills: add another "<repo> <dir>" pair below.
# <dir> is the skill directory inside the repo; its basename is the skill name.
#
# Usage: scripts/link-claude-skills.sh
set -euo pipefail

# "<repo> <dir>" pairs, one skill per line.
SKILLS=(
  "github.com/lanegrid/git-workflow skills/git-workflow"
  "github.com/lanegrid/rep .claude/skills/rep"
)

DEST_DIRS=(
  "$HOME/.claude/skills"
  "$HOME/.agents/skills"
)
mkdir -p "${DEST_DIRS[@]}"

for entry in "${SKILLS[@]}"; do
  read -r repo dir <<<"$entry"
  skill="${dir##*/}"

  path="$(ghq list --full-path --exact "$repo" || true)"
  if [[ -z "$path" ]]; then
    echo "  cloning $repo ..."
    ghq get "$repo"
    path="$(ghq list --full-path --exact "$repo")"
  fi

  src="$path/$dir"
  if [[ -z "$path" || ! -d "$src" ]]; then
    echo "  ! skill not found: $repo:$skill ($src)" >&2
    continue
  fi

  for dest_dir in "${DEST_DIRS[@]}"; do
    dst="$dest_dir/$skill"
    # Replace only our own links; never delete a real skill directory.
    if [[ -e "$dst" && ! -L "$dst" ]]; then
      echo "  ! not a symlink, left alone: $dst" >&2
      continue
    fi
    ln -sfn "$src" "$dst"
    echo "  ${dst/#"$HOME"/~} -> $src"
  done
done
