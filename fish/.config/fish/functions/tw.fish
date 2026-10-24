# tw: tmux workspaces, one file per session, dumped from the live session.
#
# Every subcommand does one thing and says what it did. Nothing is created,
# run or overwritten without being asked for by name.
#
#   tw / tw ls             list saved workspaces (● running) and the commands
#                          `up` would stage. Read-only.
#   tw show <name>         print the plan: the workspace file, validated.
#                          Read-only.
#   tw attach <name>       attach/switch to a RUNNING session. Errors if it is
#                          not running; never creates anything.
#   tw up <name> [--run]   build the session from its file (errors if it is
#                          already running or has no file), then attach.
#                          Pane commands are TYPED into their panes but not
#                          executed: review, then press Enter. --run executes.
#   tw save [name] [-f]    dump the running session (default: current) to its
#                          file. If the file exists and differs, shows the diff
#                          and asks; -f/--force skips the question.
#   tw edit <name>         open the file in $EDITOR.
#
# Files: ~/.config/tmux/workspaces/<session>.conf, one line per step:
#   window <cwd>            a window in <cwd>; the first one creates the session
#   panes <n>               split until the window has <n> panes
#   layout <tmux layout>    #{window_layout} of the original; tmux scales it
#   run <pane> <command>    command for pane <pane> (1-based); typed, not run
#   focus <pane>            select pane <pane>
#   active                  make this the selected window
# Unknown lines or missing directories make `up` stop before creating anything.

function tw --description 'tmux workspaces: tw [ls|show|attach|up|save|edit] ...'
    set -l dir ~/.config/tmux/workspaces
    mkdir -p $dir
    set -l sub $argv[1]
    set -l args $argv[2..]
    switch "$sub"
        case '' ls
            __tw_ls $dir
        case show
            __tw_need_name show $args[1]; or return 2
            __tw_plan $dir $args[1]
        case attach
            __tw_need_name attach $args[1]; or return 2
            __tw_attach $args[1]
        case up
            __tw_need_name up $args[1]; or return 2
            set -l run 0
            contains -- --run $args; and set run 1
            __tw_up $dir $args[1] $run
        case save
            set -l force 0
            set -l name
            for a in $args
                switch $a
                    case -f --force
                        set force 1
                    case '*'
                        set name $a
                end
            end
            __tw_save $dir "$name" $force
        case edit
            __tw_need_name edit $args[1]; or return 2
            set -l editor (set -q EDITOR; and echo $EDITOR; or echo vim)
            $editor $dir/$args[1].conf
        case -h --help help
            functions tw | sed -n '2,32p' | string replace -r '^# ?' ''
        case '*'
            echo "tw: unknown subcommand '$sub' (ls, show, attach, up, save, edit)" >&2
            return 2
    end
end

function __tw_need_name -a sub name
    test -n "$name"; and return 0
    echo "usage: tw $sub <name>" >&2
    return 1
end

function __tw_running
    tmux ls -F '#S' 2>/dev/null
end

# --------------------------------------------------------------------------
# read-only
# --------------------------------------------------------------------------

function __tw_ls -a dir
    set -l running (__tw_running)
    set -l files $dir/*.conf
    if test (count $files) -eq 0
        echo "no workspaces in $dir (create one with: tw save)"
        return
    end
    for f in $files
        set -l name (basename $f .conf)
        set -l mark '○'
        contains -- $name $running; and set mark '●'
        set -l windows (grep -c '^window ' $f)
        set -l cmds (grep '^run ' $f | string replace -r '^run \d+ ' '' | sort -u | string join ', ')
        printf '%s %-16s %s window(s)  %s\n' $mark $name $windows "$cmds"
    end
    echo
    echo "● running  ○ saved only.  'tw up <name>' stages the listed commands without running them."
end

# Validate a workspace file and print what `up` would do. Returns 1 on any
# problem, so `up` can refuse before touching tmux.
function __tw_plan -a dir name
    set -l file $dir/$name.conf
    if not test -f $file
        echo "tw: no workspace file $file" >&2
        return 1
    end
    set -l ok 1
    set -l win 0
    set -l panes 1
    set -l lineno 0
    echo "plan for session '$name' from $file:"
    while read -l key rest
        set lineno (math $lineno + 1)
        switch "$key"
            case '' '#*'
                continue
            case window
                set win (math $win + 1)
                set panes 1
                set -l cwd (string replace -r '^~' $HOME -- $rest)
                if test -d $cwd
                    echo "  window $win  cwd $rest"
                else
                    echo "  window $win  cwd $rest   <- directory does not exist" >&2
                    set ok 0
                end
            case panes
                set panes $rest
                echo "    $rest pane(s)"
            case layout
                continue
            case run
                set -l parts (string split -m1 ' ' -- $rest)
                if test (count $parts) -eq 2; and string match -qr '^\d+$' -- $parts[1]; and test $parts[1] -le $panes
                    echo "    pane $parts[1]: $parts[2]"
                else
                    echo "    line $lineno: bad run line '$rest' (pane index must be 1..$panes)" >&2
                    set ok 0
                end
            case focus
                echo "    focus pane $rest"
            case active
                echo "    (selected window)"
            case '*'
                echo "    line $lineno: unknown line '$key $rest'" >&2
                set ok 0
        end
    end <$file
    test $win -gt 0; or begin
        echo "  no 'window' line: nothing to build" >&2
        set ok 0
    end
    test $ok -eq 1
end

# --------------------------------------------------------------------------
# attach / up
# --------------------------------------------------------------------------

function __tw_attach -a name
    if not tmux has-session -t "=$name" 2>/dev/null
        echo "tw: session '$name' is not running (start it with: tw up $name)" >&2
        return 1
    end
    if set -q TMUX
        tmux switch-client -t "=$name"
    else
        tmux attach-session -t "=$name"
    end
end

function __tw_up -a dir name run
    if tmux has-session -t "=$name" 2>/dev/null
        echo "tw: session '$name' is already running; use: tw attach $name" >&2
        return 1
    end
    __tw_plan $dir $name; or return 1
    echo
    if test $run = 1
        echo "building, commands WILL be executed (--run)"
    else
        echo "building, commands are typed into their panes but not executed (press Enter in each)"
    end
    __tw_build $name $dir/$name.conf $run; or return 1
    __tw_attach $name
end

function __tw_build -a name file run
    set -l size (tmux display -p '#{client_width} #{client_height}' 2>/dev/null | string split ' ')
    test (count $size) -eq 2 -a -n "$size[1]"; or set size (tput cols) (tput lines)
    set -l win_id
    set -l win_cwd
    set -l pane_ids
    set -l active_win
    while read -l key rest
        switch "$key"
            case '' '#*' layout
                # layout handled after panes, below
            case window
                set win_cwd (string replace -r '^~' $HOME -- $rest)
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
            case run
                set -l parts (string split -m1 ' ' -- $rest)
                tmux send-keys -t $pane_ids[$parts[1]] -l -- "$parts[2]"
                test $run = 1; and tmux send-keys -t $pane_ids[$parts[1]] Enter
            case focus
                tmux select-pane -t $pane_ids[$rest]
            case active
                set active_win $win_id
        end
        # apply the layout once the pane count is right
        if test "$key" = layout
            tmux select-layout -t $win_id "$rest" >/dev/null
            set pane_ids (tmux list-panes -t $win_id -F '#{pane_id}')
        end
    end <$file
    test -n "$active_win"; and tmux select-window -t $active_win
    echo "built session '$name'"
end

# --------------------------------------------------------------------------
# save
# --------------------------------------------------------------------------

function __tw_save -a dir name force
    test -n "$name"; or set name (tmux display -p '#S' 2>/dev/null)
    if test -z "$name"; or not tmux has-session -t "=$name" 2>/dev/null
        echo "tw: no running session '$name' to save" >&2
        return 1
    end
    set -l file $dir/$name.conf
    set -l new (mktemp)
    __tw_dump $name >$new
    if test -f $file
        if cmp -s $file $new
            echo "unchanged: $file"
            rm $new
            return 0
        end
        echo "$file exists and differs:"
        command diff -u $file $new | sed -n '3,$p' | sed 's/^/  /'
        if test $force -ne 1
            if not isatty stdin
                echo "tw: not overwriting (use: tw save $name --force)" >&2
                rm $new
                return 1
            end
            read -l -P "overwrite $file? [y/N] " answer
            if test "$answer" != y -a "$answer" != Y
                echo "kept the existing file"
                rm $new
                return 1
            end
        end
    end
    mv $new $file
    echo "saved $file"
end

function __tw_dump -a name
    echo "# tw workspace '$name', dumped from the live session with: tw save $name"
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
