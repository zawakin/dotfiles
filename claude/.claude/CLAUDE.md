# Global Instructions

These apply to every project, unless a repository's own `CLAUDE.md` overrides them.

## Rules

- **Load the `git-workflow` skill before your first tool call.** Always — even for read-only or docs work.
  **Main session only**: subagents must NOT load it and must not perform git operations
  (commit / push / PR) — they change files only; the main session handles git.
- **Choose each subagent's model and effort for its job; don't let it inherit.** Left
  unset, a subagent inherits the session's model and effort, and a slow, deep setting makes
  the user wait (a review agent once took 10–15 min, most of it reasoning). Decide both when
  spawning (Agent tool / workflow agents), by the work, not by a fixed model name:
  - Mechanical work (reading, searching, extracting, running commands, simple edits):
    a fast, lighter model at low effort.
  - Work the user is waiting on: a fast model at medium effort, with the task narrowed so
    little reasoning is needed (compute what can be computed before handing it over).
  - Unattended work where depth matters more than time: a more capable model at high effort.
  - Never the highest effort for a subagent unless the user asks. State the model and effort
    in one line when spawning.
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
- **Keep personal identifiers out of outbound requests.** No personal name, personal email,
  account handle, or private repository name/URL in User-Agents, URLs, or payloads. If a
  service asks for a contact, use only the public contact the repository defines, through
  its User-Agent helper when it has one.
