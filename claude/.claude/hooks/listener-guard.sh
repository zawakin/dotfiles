#!/bin/bash
# PreToolUse hook: in a claude-lead session, keep the listener (the main
# conversation) to talking with the person and with its lead:
#   human - listener - lead - agents
#
# Applies only when CLAUDE_ROLE=listener (set by claude-lead) and only to the
# main conversation; calls made inside agents carry agent_id and pass through.
# The listener may spawn `lead` agents, message and stop them, ask the person,
# load deferred tools, and read or write briefs and reports in the scratchpad.
# Everything else is denied with a pointer to the lead.
set -euo pipefail

[[ "${CLAUDE_ROLE:-}" == "listener" ]] || exit 0

input=$(cat)
[[ -z "$(jq -r '.agent_id // empty' <<<"$input")" ]] || exit 0

tool=$(jq -r '.tool_name // ""' <<<"$input")

deny() {
  jq -n --arg r "$1" '{
    hookSpecificOutput: {
      hookEventName: "PreToolUse",
      permissionDecision: "deny",
      permissionDecisionReason: $r
    }
  }'
  exit 0
}

case "$tool" in
  SendMessage | AskUserQuestion | TaskStop | ToolSearch | ListAgents)
    exit 0
    ;;
  Agent | Task)
    [[ "$(jq -r '.tool_input.subagent_type // ""' <<<"$input")" == "lead" ]] && exit 0
    deny "listener: only the lead starts other agents. Spawn a lead (subagent_type: lead) with the brief, or ask the lead you have with SendMessage; it sends scouts and workers."
    ;;
  Read | Write | Edit)
    path=$(jq -r '.tool_input.file_path // ""' <<<"$input")
    case "$path" in
      */scratchpad/* | *-scratchpad/*) exit 0 ;;
    esac
    deny "listener: you read and write only briefs and reports in the scratchpad. Ask the lead (SendMessage) to find this out; it sends scouts."
    ;;
esac

deny "listener: you don't run $tool. Put what you need in the brief, or ask the lead with SendMessage; the lead delegates to scouts and workers."
