if status is-interactive
    # Commands to run in interactive sessions can go here
    eval (/opt/homebrew/bin/brew shellenv)
end

alias la='ls -a'
alias ll='ls -alG'
alias l='ls -alG'
alias vi='vim'
alias diff='colordiff -u'
alias grep='grep --color'
alias less='less -NR'
alias dc='docker-compose'
alias gf='git fetch'
alias gco='git checkout'
alias gs='git status -sb'
alias gd='git diff'
alias gw='git switch'
alias gp='git pull'
alias gb='git branch --sort=-committerdate --format="%(refname:short)%09%(color:blue)%(committerdate:relative)%09%(color:green)%(contents:subject)%(color:yellow)(%(authorname))"'
alias ga='git commit -n --amend'
alias gc='git commit -n'
alias gm='git commit -n -m'
alias gl='git log --graph --pretty=format:\'%x09%C(auto) %h %Cgreen %ar %Creset%x09by"%C(cyan ul)%an%Creset" %x09%C(auto)%s %d\''
alias gr='cd (git rev-parse --show-toplevel)'

set -x GOPATH $HOME/go $GOPATH
set -x PATH $GOPATH/bin $PATH

# for voicevox
set -x DYLD_LIBRARY_PATH $HOME/.local/models/voicevox_core $DYLD_LIBRARY_PATH

# for go wasm
# set -x PATH (go env GOROOT)/misc/wasm $PATH
# set -x PATH $HOME/.cargo/bin $PATH

mise activate fish | source

export LSCOLORS=gxfxcxdxbxegedabagacad

# -- functions
function cd_fzy_ghqlist
    set -l selected_repo (ghq list | fzy -l 15)
    if [ -n "$selected_repo" ]
        cd (ghq root)/$selected_repo
    end
    commandline -f repaint
end

function cd_fzy_projects
    # Set projects_dir directly to ~/experimental
    set -l projects_dir $HOME/experimental/experimental

    set -l selected_dir (find $projects_dir -mindepth 1 -maxdepth 3 -type d | sed "s|$projects_dir/||" | fzy -l 15)
    if [ -n "$selected_dir" ]
        cd $projects_dir/$selected_dir
    end
    commandline -f repaint
end

function git-switch-enhanced
    set -l branches (git for-each-ref --sort=-committerdate refs/heads/ --format='%(refname:short)' | head -n 30)

    set -l branch_info ""

    for branch in $branches
        set commits (git log --pretty=format:'%C(auto)%h - %s' -n 1 $branch --)
        set branch_info "$branch_info$branch: $commits\n"
    end

    # fzyを使ってブランチを選択し、出力からブランチ名だけを抽出
    set -l selected_branch (echo -e "$branch_info" | fzy -l 15 | string match -r '^[^:]*')

    # 選択したブランチに切り替え
    if test -n "$selected_branch"
        echo "Switching to branch: $selected_branch"
        git switch $selected_branch
    else
        echo "Branch switch cancelled."
    end
    commandline -f repaint
end

function pvim
    vim -nR \
        -c "set nowrap" \
        $argv
end

function claude_workspace
    # チケットIDを入力
    echo "Enter ticket ID:"
    read ticket_id
    
    if test -z "$ticket_id"
        echo "Ticket ID is required"
        return
    end
    
    # ワークスペースディレクトリを作成
    set -l ws_dir "$HOME/ws/$ticket_id"
    mkdir -p "$ws_dir"
    
    # 最初のrepoを選択
    set -l first_repo (ghq list | fzy -l 15)
    
    if test -z "$first_repo"
        return
    end
    
    set -l selected_repos $first_repo
    
    # 追加のrepoを選択するか確認
    while true
        echo "Selected repos: $selected_repos"
        
        echo "Add more repos? (y/n/q)"
        read -n 1 choice
        echo
        
        switch $choice
            case y Y
                set -l next_repo (ghq list | fzy -l 15)
                if test -n "$next_repo"
                    set selected_repos $selected_repos $next_repo
                end
            case n N
                break
            case q Q
                return
            case '*'
                echo "Invalid choice. Use y/n/q"
        end
    end
    
    # 各リポジトリでworktreeを作成
    for repo in $selected_repos
        set -l src_path (ghq list -p | grep "$repo\$")
        
        # fetch して最新の状態にする
        echo "Fetching $repo..."
        git -C "$src_path" fetch
        
        # main/master ブランチを特定
        set -l base_branch
        if git -C "$src_path" show-ref --verify --quiet refs/remotes/origin/main
            set base_branch "origin/main"
        else if git -C "$src_path" show-ref --verify --quiet refs/remotes/origin/master
            set base_branch "origin/master"
        else
            echo "Warning: No origin/main or origin/master found, using current branch"
            set base_branch (git -C "$src_path" rev-parse --abbrev-ref HEAD)
        end
        
        set -l new_branch "$base_branch-$ticket_id"
        # origin/main の場合は main-ticket_id にする
        set new_branch (echo $new_branch | sed 's/^origin\///')
        
        echo "Creating worktree for $repo (branch: $new_branch from $base_branch)"
        git -C "$src_path" worktree add -b "$new_branch" "$ws_dir/$repo" "$base_branch"
    end
    
    # Claude設定を作成
    mkdir -p "$ws_dir/.claude"
    echo "{}" > "$ws_dir/.claude/settings.json"
    
    cd "$ws_dir"
    echo "Running: claude"
    claude
end

bind \cG cd_fzy_ghqlist
bind \cH cd_fzy_projects
bind \cB git-switch-enhanced
bind \cL claude_workspace

set -x EDITOR vim
direnv hook fish | source

set -g direnv_fish_mode eval_on_arrow    # trigger direnv at prompt, and on every arrow-based directory change (default)
set -g direnv_fish_mode eval_after_arrow # trigger direnv at prompt, and only after arrow-based directory changes before executing command
set -g direnv_fish_mode disable_arrow    # trigger direnv at prompt only, this is similar functionality to the original behavior

set -x ASDF_GOLANG_MOD_VERSION_ENABLED true

# uv
fish_add_path "$HOME/.local/bin"

