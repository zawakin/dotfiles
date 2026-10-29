# claude-lead: start (or resume) Claude Code as the lead of this conversation.
#
# Appends ~/.claude/roles/lead.md to the default system prompt: the session
# sizes each request, keeps a brief as the current agreement with you, brings
# goal/scope changes to you and delegates bounded work to agents. A plain
# `claude` stays an ordinary conversation.
#
# Resume through it too (`claude-lead -r <session>`): a resumed conversation
# keeps its recorded prompt only until it is compacted; after that the prompt
# is rebuilt from this launch's flags, and a plain `claude` would drop the role.
function claude-lead --description 'Claude Code as the lead of this conversation'
    claude --append-system-prompt-file ~/.claude/roles/lead.md $argv
end
