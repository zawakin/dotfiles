#!/bin/bash
# PreToolUse(Bash) hook: let the agent run `gh pr merge` on GitHub repositories
# owned by zawakin or lanegrid.
#
# For any other repository the hook says nothing, so the normal permission flow
# (auto-mode classifier / prompt) decides exactly as it would without this hook.
# Only a single plain `gh pr merge ...` command is judged; anything chained,
# with shell expansion, or naming the PR by URL is left to the normal flow too.
#
# The target repository comes from `-R/--repo OWNER/REPO` when given, else from
# the origin remote of the hook's cwd.
set -euo pipefail

ALLOWED_OWNERS=(zawakin lanegrid)

input=$(cat)
cmd=$(jq -r '.tool_input.command // ""' <<<"$input")
cwd=$(jq -r '.cwd // ""' <<<"$input")

[[ "$cmd" =~ ^gh[[:space:]]+pr[[:space:]]+merge([[:space:]]|$) ]] || exit 0
case "$cmd" in
  *[\;\&\|\`\$\(\)\<\>]* | *$'\n'* | *://*) exit 0 ;;
esac

if [[ "$cmd" =~ (^|[[:space:]])(-R|--repo)(=|[[:space:]]+)([^[:space:]]+) ]]; then
  repo="${BASH_REMATCH[4]}"
  # HOST/OWNER/REPO form: only github.com counts.
  if [[ "$repo" == */*/* ]]; then
    [[ "${repo%%/*}" == "github.com" ]] || exit 0
    repo="${repo#*/}"
  fi
else
  [[ -n "$cwd" ]] || exit 0
  url=$(git -C "$cwd" remote get-url origin 2>/dev/null) || exit 0
  case "$url" in
    git@github.com:*) repo="${url#git@github.com:}" ;;
    https://github.com/*) repo="${url#https://github.com/}" ;;
    ssh://git@github.com/*) repo="${url#ssh://git@github.com/}" ;;
    *) exit 0 ;;
  esac
  repo="${repo%.git}"
fi

owner="${repo%%/*}"
for allowed in "${ALLOWED_OWNERS[@]}"; do
  if [[ "$owner" == "$allowed" ]]; then
    jq -n --arg repo "$repo" '{
      hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "allow",
        permissionDecisionReason: ("gh pr merge on " + $repo + ": owner allowed for agent merges")
      }
    }'
    exit 0
  fi
done
exit 0
