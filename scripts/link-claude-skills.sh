#!/bin/bash
# Symlink Claude Code skills from their own ghq-managed repos into dotfiles.
#
# Each skill ships inside its source repo at <repo>/.claude/skills/<skill>/.
# This resolves <repo> to a local path via ghq (cloning if missing) and creates
# a symlink at claude/.claude/skills/<skill> -> that path. The symlinks are
# git-ignored and regenerated per machine, so dotfiles stays portable while the
# skills stay in sync with their upstream repos.
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
  "github.com/lanegrid/wf wf"
)

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST_DIR="$DOTFILES_DIR/claude/.claude/skills"
mkdir -p "$DEST_DIR"

for entry in "${SKILLS[@]}"; do
  read -r repo skill <<<"$entry"

  path="$(ghq list --full-path --exact "$repo" || true)"
  if [[ -z "$path" ]]; then
    echo "  cloning $repo ..."
    ghq get "$repo"
    path="$(ghq list --full-path --exact "$repo")"
  fi

  src="$path/.claude/skills/$skill"
  dst="$DEST_DIR/$skill"
  if [[ -z "$path" || ! -d "$src" ]]; then
    echo "  ! skill not found: $repo:$skill ($src)" >&2
    continue
  fi

  rm -rf "$dst"
  ln -sfn "$src" "$dst"
  echo "  $skill -> $src"
done
