#!/bin/bash
# Symlink user-scoped agent skills from their own ghq-managed repos into dotfiles.
#
# Each skill ships inside its source repo at <repo>/.claude/skills/<skill>/.
# This resolves <repo> to a local path via ghq (cloning if missing) and creates
# symlinks for both Claude Code and agents at:
#   claude/.claude/skills/<skill> -> that path
#   agents/.agents/skills/<skill> -> that path
# The symlinks are git-ignored and regenerated per machine, so dotfiles stays
# portable while the skills stay in sync with their upstream repos.
#
# A single repo can ship multiple skills (e.g. its own "release" skill): just
# add another "<repo> <skill>" pair below. Each pair uniquely pins one skill.
#
# Usage: scripts/link-claude-skills.sh
set -euo pipefail

# "<repo> <skill>" pairs, one skill per line.
SKILLS=(
  "github.com/lanegrid/git-workflow git-workflow"
  "github.com/lanegrid/git-workflow team-spawn"
  "github.com/lanegrid/rep rep"
)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIRS=(
  "$DOTFILES_DIR/claude/.claude/skills"
  "$DOTFILES_DIR/agents/.agents/skills"
)
mkdir -p "${DEST_DIRS[@]}"

for entry in "${SKILLS[@]}"; do
  read -r repo skill <<<"$entry"

  path="$(ghq list --full-path --exact "$repo" || true)"
  if [[ -z "$path" ]]; then
    echo "  cloning $repo ..."
    ghq get "$repo"
    path="$(ghq list --full-path --exact "$repo")"
  fi

  src="$path/.claude/skills/$skill"
  if [[ -z "$path" || ! -d "$src" ]]; then
    echo "  ! skill not found: $repo:$skill ($src)" >&2
    continue
  fi

  for dest_dir in "${DEST_DIRS[@]}"; do
    dst="$dest_dir/$skill"
    rm -rf "$dst"
    ln -sfn "$src" "$dst"
    echo "  ${dst#"$DOTFILES_DIR/"} -> $src"
  done
done
