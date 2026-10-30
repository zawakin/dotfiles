# Global Instructions

These apply to every project, unless a repository's own `CLAUDE.md` overrides them.

## Rules

- **Load the `git-workflow` skill before the first git write.** That is the first branch,
  commit, push, PR, merge, `gw` mutation or worktree-pool operation in a session. Read-only
  work, questions and reviews don't need it. Each repo's flow (`pr` or `trunk`) is set by
  `git config gw.flow` and shown by `gw status`; don't restate it in a CLAUDE.md.
- **Whoever starts a work item publishes it.** The one who wrote its brief (or ran `gw new`,
  or acquired its pool worktree) owns push, PR, merge, `gw await`, cleanup and the worktree
  release. If you were handed the item (by a spawn prompt, a brief, or a message from another
  session), commit on its branch but don't publish, unless the brief says `publish: you`.
  Questions that change goal or scope go back to whoever handed you the item.
- **Merge your own PRs in `zawakin/*` and `lanegrid/*` repositories; never elsewhere.** Once
  CI has passed on the PR's head (or the change has no CI and the repo's verify passed
  locally), the owner merges with a standalone
  `gh pr merge -R <owner>/<repo> <n> --match-head-commit <sha>` (no `cd … &&`), using the
  repo's merge method, and leaves cleanup to `gw await`. A hook allows exactly that command
  for those two owners; in any other org a human merges.
- **Model and effort come from the agent definitions; don't override them.** The definitions
  in `~/.claude/agents/` pin them per role (`scout` sonnet/low, `worker` sonnet/medium,
  `reviewer` opus/medium), so spawn those without `model` / `effort`, even
  when the user is waiting. Only for an agent without a definition (e.g. `general-purpose`)
  choose them yourself rather than letting it inherit the session's slow, deep setting:
  - Mechanical work (reading, searching, extracting, running commands, simple edits):
    a fast, lighter model at low effort.
  - Work the user is waiting on: a fast model at medium effort, with the task narrowed so
    little reasoning is needed (compute what can be computed before handing it over).
  - Unattended work where depth matters more than time: a more capable model at high effort.
  - Never the highest effort for a subagent unless the user asks.
  State the model and effort in one line when spawning. (`subagent_type: "fork"` inherits the
  session model and cannot be overridden — prefer non-fork agents when the work doesn't need
  the full conversation context.)
- **An agent lives as long as its work item.** A work item ends when its result is accepted,
  dropped or handed off, not when a report lands. Send follow-ups (review findings, fixes,
  scope changes) with SendMessage to the agent that already holds the context. Spawn a fresh
  agent only when independence is the point: a fresh-eyes review or parallel variants. An
  idle agent costs nothing, and TaskStop can't be undone (a stopped agent can't be messaged
  again), so use TaskStop only to abort running work that is no longer wanted.
- **Exchange agent work through files, not messages.** Messages to and from agents get
  truncated. Each work item has a brief in the session scratchpad: `owner`, `publish`,
  `rev: N`, goal, scope (in / out), acceptance, decisions, open questions. To change direction,
  edit the brief, bump `rev`, and message only "brief rev N: <one line>". Agents write results
  to files, state the rev they worked from, and reply with the path plus a one- or two-line
  summary. This holds in both directions, for whoever hands off.
- **Keep personal identifiers out of outbound requests.** No personal name, personal email,
  account handle, or private repository name/URL in User-Agents, URLs, or payloads. If a
  service asks for a contact, use only the public contact the repository defines, through
  its User-Agent helper when it has one.
