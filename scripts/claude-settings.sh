#!/bin/bash
#
# Claude Code user settings: the part of ~/.claude/settings.json that is safe to
# publish lives in claude-settings.json and is merged into the live file.
#
#   scripts/claude-settings.sh         apply: merge claude-settings.json into
#                                      ~/.claude/settings.json, writing only when
#                                      something differs (make claude-settings)
#   scripts/claude-settings.sh check   report drift, change nothing
#                                      (make claude-settings-check)
#
# ~/.claude/settings.json itself stays untracked. Claude Code rewrites it, and
# it collects permission rules ("always allow" saves whole commands) and
# autoMode notes that name private repositories and local paths. This
# repository is public, so claude-settings.json holds only keys that are safe
# to publish: leave permissions.allow/deny and autoMode out of it, and don't
# add hooks that need scripts this repository doesn't ship.
#
# Merge rule: objects merge key by key; any other value is replaced by the one
# in claude-settings.json, so a hook event listed there (an array) is owned by
# it. Keys it doesn't mention are left alone.
#
# The machine is the source of truth: when you change a tracked setting (via
# /config or by hand) and want to keep it, run `make claude-settings-check`,
# copy the "now" value into claude-settings.json and commit.
#
# CLAUDE_SETTINGS overrides the target file (for testing).

set -euo pipefail

MODE=${1:-apply}
DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SHARED="$DOTFILES_DIR/claude-settings.json"
LIVE=${CLAUDE_SETTINGS:-$HOME/.claude/settings.json}

# Leaf paths of claude-settings.json: descend objects, stop at any other value.
LEAVES='def leaves($p):
  if type == "object" and length > 0
  then to_entries[] as $e | $e.value | leaves($p + [$e.key])
  else $p end;'

live_json() {
  if [[ -f "$LIVE" ]]; then cat "$LIVE"; else echo '{}'; fi
}

# Print one line per tracked setting whose live value differs.
drift() {
  jq -r --argjson live "$(live_json)" "$LEAVES"'
    leaves([]) as $p
    | getpath($p) as $want | ($live | getpath($p)) as $now
    | select($want != $now)
    | "  \($p | join(".")): want=\($want | tojson) now=\($now | tojson)"' "$SHARED"
}

check() {
  local lines
  lines=$(drift)
  if [[ -z "$lines" ]]; then
    echo "claude settings: no drift ($LIVE)"
  else
    echo "claude settings: differs from claude-settings.json ($LIVE)"
    echo "$lines"
  fi
}

apply() {
  local merged
  merged=$(live_json | jq --slurpfile shared "$SHARED" '. * $shared[0]')
  if [[ "$(jq -S . <<<"$merged")" == "$(live_json | jq -S .)" ]]; then
    echo "claude settings: up to date ($LIVE)"
    return
  fi
  drift
  mkdir -p "$(dirname "$LIVE")"
  # Rewrite in place so the file keeps its inode and permissions.
  jq . <<<"$merged" >"$LIVE.tmp.$$"
  cat "$LIVE.tmp.$$" >"$LIVE"
  rm -f "$LIVE.tmp.$$"
  echo "claude settings: updated $LIVE"
}

jq empty "$SHARED"
case "$MODE" in
  apply) apply ;;
  check) check ;;
  *) echo "usage: $0 [apply|check]" >&2; exit 2 ;;
esac
