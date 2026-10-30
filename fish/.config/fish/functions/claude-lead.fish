# claude-lead: start (or resume) Claude Code as the listener in front of a lead.
#
# Appends ~/.claude/roles/listener.md to the default system prompt: this
# session talks with you, researches through scouts, and refines what you say
# into a brief; a `lead` agent (~/.claude/agents/lead.md) executes from that
# brief alone, so your raw phrasing never steers the execution. A plain
# `claude` stays an ordinary conversation.
#
# Resume through it too (`claude-lead -r <session>`): a resumed conversation
# keeps its recorded prompt only until it is compacted; after that the prompt
# is rebuilt from this launch's flags, and a plain `claude` would drop the role.
function claude-lead --description 'Claude Code as the listener in front of a lead agent'
    claude --append-system-prompt-file ~/.claude/roles/listener.md $argv
end
