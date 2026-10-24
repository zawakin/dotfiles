# tw: tmux workspaces, one file per session, dumped from the live session.
#
#   tw                 pick a running session, a saved workspace or a ghq repo
#   tw <name>          attach if running, else build from the saved workspace,
#                      else start a plain session in that repo
#   tw save [name]     dump the running session (default: current) to a file
#   tw ls              list saved workspaces (● running)
#   tw edit <name>     open the workspace file in $EDITOR
#
# Files live in ~/.config/tmux/workspaces/<session>.conf, one line per step:
#
#   window <cwd>              start a window in <cwd> (first one creates the session)
#   panes <n>                 split until the window has <n> panes
#   layout <tmux layout>      #{window_layout} of the original window; tmux scales it
#   run <pane> <command>      type <command> + Enter into pane <pane> (1-based)
#   focus <pane>              select pane <pane>
#   active                    make this the selected window
#
# The machine is the source of truth: arrange a session by hand, `tw save`,
# edit the file if a pane's command was not recorded, done.

function tw --description 'tmux workspaces: tw [name] | tw save [name] | tw ls | tw edit <name>'
    set -l dir ~/.config/tmux/workspaces
    mkdir -p $dir
    switch "$argv[1]"
        case ls
            __tw_ls $dir
        case save
            __tw_save $dir $argv[2]
        case edit
            test -n "$argv[2]"; or begin; echo "usage: tw edit <name>" >&2; return 2; end
            set -l editor (set -q EDITOR; and echo $EDITOR; or echo vim)
            $editor $dir/$argv[2].conf
        case -h --help help
            functions tw | sed -n '2,20p' | string replace -r '^# ?' ''
        case ''
            set -l pick (__tw_pick $dir)
            test -n "$pick"; or return 1
            __tw_open $dir $pick
        case '*'
            __tw_open $dir $argv[1]
    end
end

function __tw_ls -a dir
    set -l running (tmux ls -F '#S' 2>/dev/null)
    for f in $dir/*.conf
        set -l name (basename $f .conf)
        if contains -- $name $running
            echo "● $name"
        else
            echo "○ $name"
        end
    end
end

function __tw_pick -a dir
    set -l running (tmux ls -F '#S' 2>/dev/null)
    set -l lines
    for s in $running
        set -a lines "● $s"
    end
    for f in $dir/*.conf
        set -l name (basename $f .conf)
        contains -- $name $running; or set -a lines "○ $name"
    end
    for r in (ghq list 2>/dev/null)
        set -a lines "  $r"
    end
    set -l pick (printf '%s\n' $lines | fzy -l 20 -p 'tw> ')
    test -n "$pick"; or return 1
    set -l body (string sub -s 3 -- $pick)
    if string match -q '  *' -- $pick
        echo (ghq root)/$body
    else
        echo $body
    end
end

function __tw_open -a dir target
    set -l name $target
    set -l root
    if test -d $target
        set root (realpath $target)
        set name (basename $root)
    end
    if tmux has-session -t "=$name" 2>/dev/null
        __tw_attach $name
        return
    end
    if test -f $dir/$name.conf
        __tw_build $name $dir/$name.conf; or return 1
        __tw_attach $name
        return
    end
    # No workspace: start a plain session in the repo.
    if test -z "$root"
        set -l hits (ghq list -p 2>/dev/null | string match -r ".*/$name\$")
        if test (count $hits) -eq 1
            set root $hits[1]
        else if test -d (ghq root)/$name
            set root (ghq root)/$name
        else
            echo "tw: no session, workspace or ghq repo named '$name'" >&2
            return 1
        end
    end
    tmux new-session -d -s $name -c $root; or return 1
    __tw_attach $name
end

function __tw_attach -a name
    if set -q TMUX
        tmux switch-client -t "=$name"
    else
        tmux attach-session -t "=$name"
    end
end

function __tw_build -a name file
    set -l size (tmux display -p '#{client_width} #{client_height}' 2>/dev/null | string split ' ')
    test (count $size) -eq 2 -a -n "$size[1]"; or set size (tput cols) (tput lines)
    set -l win_id
    set -l win_cwd
    set -l pane_ids
    set -l active_win
    while read -l key rest
        switch "$key"
            case '' '#*'
                continue
            case window
                set win_cwd (string replace -r '^~' $HOME -- $rest)
                if not test -d $win_cwd
                    echo "tw: $file: directory not found: $win_cwd" >&2
                    tmux kill-session -t "=$name" 2>/dev/null
                    return 1
                end
                if test -z "$win_id"
                    tmux new-session -d -s $name -c $win_cwd -x $size[1] -y $size[2]; or return 1
                    set win_id (tmux list-windows -t "=$name" -F '#{window_id}')[1]
                else
                    set win_id (tmux new-window -d -P -F '#{window_id}' -t "=$name:" -c $win_cwd)
                end
                set pane_ids (tmux list-panes -t $win_id -F '#{pane_id}')
            case panes
                for i in (seq 2 $rest)
                    tmux split-window -d -t $win_id -c $win_cwd
                end
                set pane_ids (tmux list-panes -t $win_id -F '#{pane_id}')
            case layout
                tmux select-layout -t $win_id "$rest" >/dev/null
                set pane_ids (tmux list-panes -t $win_id -F '#{pane_id}')
            case run
                set -l parts (string split -m1 ' ' -- $rest)
                tmux send-keys -t $pane_ids[$parts[1]] -l -- "$parts[2]"
                tmux send-keys -t $pane_ids[$parts[1]] Enter
            case focus
                tmux select-pane -t $pane_ids[$rest]
            case active
                set active_win $win_id
            case '*'
                echo "tw: $file: unknown line: $key $rest" >&2
        end
    end <$file
    test -n "$active_win"; and tmux select-window -t $active_win
    return 0
end

function __tw_save -a dir name
    test -n "$name"; or set name (tmux display -p '#S')
    tmux has-session -t "=$name" 2>/dev/null; or begin
        echo "tw: no running session '$name'" >&2
        return 1
    end
    set -l file $dir/$name.conf
    begin
        echo "# tw workspace '$name', dumped "(date '+%Y-%m-%d')" from the live session"
        echo "# window <cwd> | panes <n> | layout <tmux layout> | run <pane> <cmd> | focus <pane> | active"
        for w in (tmux list-windows -t "=$name" -F '#{window_id} #{window_panes} #{window_layout} #{window_active}')
            set -l wf (string split ' ' -- $w)
            set -l panes (tmux list-panes -t $wf[1] -F '#{pane_id} #{pane_active} #{pane_current_path}')
            set -l first (string split -m2 ' ' -- $panes[1])
            set -l win_cwd $first[3]
            echo
            echo "window "(string replace -r "^$HOME" '~' -- $win_cwd)
            echo "panes $wf[2]"
            echo "layout $wf[3]"
            set -l n 0
            set -l focus 1
            for p in $panes
                set n (math $n + 1)
                set -l pf (string split -m2 ' ' -- $p)
                if test "$pf[3]" != "$win_cwd"
                    echo "run $n cd "(string escape -- (string replace -r "^$HOME" '~' -- $pf[3]))
                end
                set -l cmdline (__tw_pane_command $pf[1])
                if test -n "$cmdline"
                    if string match -qr '^(claude|codex|mise run|npm|pnpm|yarn|bun|cargo (run|watch)|go run|make|uv run|docker compose|node|python3?)( |$)' -- $cmdline
                        echo "run $n $cmdline"
                    else
                        echo "# pane $n was running: $cmdline  (turn into 'run $n ...' to restore)"
                    end
                end
                test "$pf[2]" = 1; and set focus $n
            end
            echo "focus $focus"
            test "$wf[4]" = 1; and echo active
        end
    end >$file
    echo "saved $file"
end

# The command running in a pane, as something you could type again. Looks at
# every process on the pane's tty (not just children of the shell: the claude
# launcher re-parents the real binary) and picks the one tmux reports as the
# foreground command. Empty when the pane is just sitting at a prompt.
function __tw_pane_command -a pane_id
    set -l info (tmux display -t $pane_id -p '#{pane_tty} #{pane_pid} #{pane_current_command}' | string split ' ')
    set -l tty (string replace '/dev/' '' -- $info[1])
    set -l shell_pid $info[2]
    set -l fg $info[3]
    set -l fallback
    for line in (ps -t $tty -o pid= -o command= | string trim)
        set -l parts (string split -m1 ' ' -- $line)
        set -l pid $parts[1]
        set -l cmdline (string trim -- $parts[2])
        test "$pid" = "$shell_pid"; and continue
        set -l argv0 (string split -m1 ' ' -- $cmdline)[1]
        set -l base (basename $argv0)
        # a bare shell (nested fish, login shell) is not a command worth replaying
        if string match -qr '^-?(fish|bash|zsh|sh)$' -- $base; and test (count (string split ' ' -- $cmdline)) -eq 1
            continue
        end
        # the versioned claude binary shows up as e.g. "2.1.310"
        string match -q '*/claude/versions/*' -- $argv0; and set base claude
        set -l short (string replace -r '^\S*/' '' -- $cmdline | string replace -r '^\S+' $base)
        if test "$base" = "$fg"
            echo $short
            return
        end
        if test "$base" = claude; and string match -qr '^\d+\.\d+\.\d+$' -- $fg
            echo $short
            return
        end
        test -z "$fallback"; and set fallback $short
    end
    echo $fallback
end
