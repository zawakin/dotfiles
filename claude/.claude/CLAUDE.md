# Global Instructions

These apply to every project, unless a repository's own `CLAUDE.md` overrides them.

## Rules

- **Load the `git-workflow` skill before your first tool call.** Always — even for read-only or docs work.
  **Main session only**: subagents must NOT load it and must not perform git operations
  (commit / push / PR) — they change files only; the main session handles git.
- **Subagents run on Opus, not Fable.** When spawning subagents (Agent tool / workflow
  agents), pass `model: "opus"` unless the user explicitly asks for another model.
  (`subagent_type: "fork"` inherits the session model and cannot be overridden — prefer
  non-fork agents when the work doesn't need the full conversation context.)
- **Close agents when done.** Once a spawned agent's result is collected and no follow-up
  message to it is planned, TaskStop it in the same turn. In a fan-out, stop each agent
  as its report lands — never leave idle agents lingering for the user to clean up.
- **Exchange agent work through files, not messages.** Messages to and from subagents
  (Agent prompts, SendMessage, final reports) get truncated, so never put the substance
  there. Write the full content — task details, findings, diffs, logs — to a file in the
  session scratchpad directory and pass its path. Keep the message itself to the minimum:
  the file path(s) plus a one- or two-line summary. This applies in both directions:
  the main session hands work to agents via files, and agents report back via files.
