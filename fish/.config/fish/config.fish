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
alias gsw='git switch'
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

    # 最初のrepoを選択（ghqでリポジトリ一覧を取得→fzyで対話的選択）
    set -l first_repo (ghq list | fzy -l 15)

    if test -z "$first_repo"
        return
    end

    set -l selected_repos $first_repo

    # 追加のrepoを選択するか確認（複数リポジトリに対応）
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

    # 各リポジトリでworktreeを作成またはsymlinkを設定
    for repo in $selected_repos
        # ghqでリポジトリの実際のパスを取得
        set -l src_path (ghq list -p | grep "$repo\$")

        # パス名を一階層化（github.com/user/repo → github-com-user-repo）
        set -l short_name (string replace -a "/" "-" "$repo" | string replace -a "." "-")
        set -l target_path "$ws_dir/$short_name"

        echo ""
        echo "Repository: $repo"
        echo "How would you like to include this repository?"
        echo "1) Create new worktree (recommended - isolated workspace)"
        echo "2) Symlink to existing repository (use current state)"
        echo "3) Skip this repository"
        read -n 1 choice
        echo

        switch $choice
            case 1
                # 既存のworktree作成ロジック
                # リモートから最新の状態を取得
                echo "Fetching $repo..."
                git -C "$src_path" fetch

                # main/masterブランチを自動判定
                set -l base_branch
                if git -C "$src_path" show-ref --verify --quiet refs/remotes/origin/main
                    set base_branch "origin/main"
                else if git -C "$src_path" show-ref --verify --quiet refs/remotes/origin/master
                    set base_branch "origin/master"
                else
                    echo "Warning: No origin/main or origin/master found, using current branch"
                    set base_branch (git -C "$src_path" rev-parse --abbrev-ref HEAD)
                end

                set -l new_branch "$ticket_id"

                echo "Creating worktree for $repo (branch: $new_branch from $base_branch) -> $short_name"
                git -C "$src_path" worktree add -b "$new_branch" "$target_path" "$base_branch"

            case 2
                # 既存リポジトリの状態を表示
                echo "Current repository status:"
                set -l current_branch (git -C "$src_path" rev-parse --abbrev-ref HEAD)
                echo "  Branch: $current_branch"

                set -l status_output (git -C "$src_path" status --porcelain)
                if test -z "$status_output"
                    echo "  Working tree: Clean"
                else
                    echo "  Working tree: Has uncommitted changes"
                    git -C "$src_path" status --porcelain | head -3
                end

                echo ""
                echo "⚠️  WARNING: This will link to the existing repository state."
                echo "   Any changes made in the workspace will affect the original repository."
                echo "   Continue? (y/N)"
                read -n 1 confirm
                echo

                if test "$confirm" = "y" -o "$confirm" = "Y"
                    echo "Creating symlink to existing repository -> $short_name"
                    ln -s "$src_path" "$target_path"
                else
                    echo "Skipped linking $repo"
                end

            case 3
                echo "Skipped $repo"

            case '*'
                echo "Invalid choice, skipping $repo"
        end
    end

    # ワークスペースに移動してClaude Codeを起動
    cd "$ws_dir"
    echo "Running: claude"
    claude
end

function claude_workspace_cleanup
    # ワークスペースディレクトリ内のディレクトリを列挙
    set -l ws_base "$HOME/ws"

    if not test -d "$ws_base"
        echo "No workspace directory found at $ws_base"
        return
    end

    set -l ws_dirs (find "$ws_base" -mindepth 1 -maxdepth 1 -type d | sort)

    if test (count $ws_dirs) -eq 0
        echo "No workspaces found"
        return
    end

    # fzyで削除対象のワークスペースを選択
    set -l selected_ws (printf "%s\n" $ws_dirs | sed "s|$ws_base/||" | fzy -l 15)

    if test -z "$selected_ws"
        echo "No workspace selected"
        return
    end

    set -l ws_dir "$ws_base/$selected_ws"

    echo "Workspace: $selected_ws"
    echo "Path: $ws_dir"
    echo ""

    # 各リポジトリのgit statusを表示
    echo "=== Git Status for each repository ==="
    for dir in "$ws_dir"/*
        if test -d "$dir"
            set -l repo_name (basename "$dir")
            echo "--- $repo_name ---"

            # symlinkかworktreeかを判定
            if test -L "$dir"
                echo "  Type: Symlink to existing repository"
                set -l target_path (readlink "$dir")
                echo "  Target: $target_path"
            else
                echo "  Type: Git worktree"
            end

            if test -f "$dir/.git" -o -d "$dir/.git"
                # 現在のブランチを取得
                set -l current_branch (git -C "$dir" rev-parse --abbrev-ref HEAD 2>/dev/null)
                echo "  Branch: $current_branch"

                # ベースブランチを判定
                set -l base_branch
                if git -C "$dir" show-ref --verify --quiet refs/remotes/origin/main
                    set base_branch "origin/main"
                else if git -C "$dir" show-ref --verify --quiet refs/remotes/origin/master
                    set base_branch "origin/master"
                else
                    set base_branch ""
                end

                # ベースブランチからの差分を表示
                if test -n "$base_branch"
                    echo "  Base: $base_branch"

                    # ahead/behind情報を取得
                    set -l ahead_behind (git -C "$dir" rev-list --left-right --count "$base_branch"..."$current_branch" 2>/dev/null | string split \t)
                    if test (count $ahead_behind) -eq 2
                        set -l behind $ahead_behind[1]
                        set -l ahead $ahead_behind[2]
                        if test "$ahead" -gt 0 -a "$behind" -gt 0
                            echo "  Diverged: $ahead commits ahead, $behind commits behind"
                        else if test "$ahead" -gt 0
                            echo "  Ahead: $ahead commits"
                        else if test "$behind" -gt 0
                            echo "  Behind: $behind commits"
                        else
                            echo "  Up to date with $base_branch"
                        end
                    else
                        echo "  Could not compare with $base_branch"
                    end
                else
                    echo "  No origin/main or origin/master found"
                end

                # 作業ディレクトリの状態を確認
                set -l status_output (git -C "$dir" status --porcelain 2>/dev/null)
                if test -z "$status_output"
                    echo "  Working tree: Clean (no changes)"
                else
                    echo "  Working tree: Has uncommitted changes!"
                    git -C "$dir" status --porcelain | head -5
                    set -l total_changes (git -C "$dir" status --porcelain | wc -l | string trim)
                    if test "$total_changes" -gt 5
                        echo "  ... and (math $total_changes - 5) more changes"
                    end
                end
            else
                echo "  Not a git repository"
            end
            echo ""
        end
    end

    echo "Are you sure you want to delete this workspace? (y/N)"
    read -n 1 confirm
    echo

    if test "$confirm" != "y" -a "$confirm" != "Y"
        echo "Cancelled"
        return
    end

    # ワークスペース内の各ディレクトリでworktreeまたはsymlinkを削除
    for dir in "$ws_dir"/*
        if test -d "$dir"
            if test -L "$dir"
                # symlinkの場合
                echo "Removing symlink: $dir"
                rm "$dir"
            else
                # worktreeの場合
                echo "Removing worktree: $dir"
                if test -f "$dir/.git"
                    # worktreeを削除（-fで強制削除）
                    set -l git_dir (cat "$dir/.git" | sed 's/gitdir: //')
                    set -l repo_dir (dirname (dirname "$git_dir"))
                    git -C "$repo_dir" worktree remove -f "$dir" 2>/dev/null || true
                end
            end
        end
    end

    # ワークスペースディレクトリを削除
    echo "Removing workspace directory: $ws_dir"
    rm -rf "$ws_dir"

    echo "Workspace $selected_ws has been deleted"
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

# GitHub CLI profile switching
function use-gh-zawakin
    set -gx GH_CONFIG_DIR ~/.config/gh/zawakin
    echo "Switched gh to zawakin (for zawakin / knowledge-work)"
end

# Auto-switch gh profile based on current directory
function __auto_gh_profile --on-variable PWD
    set -l current_dir (pwd)

    if string match -q "*/go/src/github.com/zawakin/*" -- $current_dir
        set -gx GH_CONFIG_DIR ~/.config/gh/zawakin
    else if string match -q "*/go/src/github.com/knowledge-work/*" -- $current_dir
        set -gx GH_CONFIG_DIR ~/.config/gh/zawakin
    else
        # Default to zawakin profile
        set -gx GH_CONFIG_DIR ~/.config/gh/zawakin
    end
end


# Initialize gh profile on shell startup
__auto_gh_profile

# Robust ghq get wrapper
function ghqget
    # Set GHQ_ROOT if not already set
    set -q GHQ_ROOT; or set -l GHQ_ROOT ~/go/src

    if test (count $argv) -eq 0
        echo "Usage: ghqget <repo>..."
        echo "Examples:"
        echo "  ghqget zawakin/repo"
        echo "  ghqget github.com/zawakin/repo"
        echo "  ghqget https://github.com/zawakin/repo"
        return 1
    end

    for repo_input in $argv
        set -l repo $repo_input
        set -l owner ""
        set -l name ""

        # Parse URL format
        if string match -qr '^https://github\.com/([^/]+)/(.+?)(?:\.git)?$' -- $repo
            set matches (string match -r '^https://github\.com/([^/]+)/(.+?)(?:\.git)?$' -- $repo)
            set owner $matches[2]
            set name $matches[3]
        else if string match -qr '^git@github\.com[:-]([^/]+)/(.+?)(?:\.git)?$' -- $repo
            set matches (string match -r '^git@github\.com[:-]([^/]+)/(.+?)(?:\.git)?$' -- $repo)
            set owner $matches[2]
            set name $matches[3]
        else if string match -qr '^(?:github\.com/)?([^/]+)/(.+?)(?:\.git)?$' -- $repo
            # Simple format: owner/repo or github.com/owner/repo
            set matches (string match -r '^(?:github\.com/)?([^/]+)/(.+?)(?:\.git)?$' -- $repo)
            set owner $matches[2]
            set name $matches[3]
        else
            echo "Error: Cannot parse repository: $repo_input"
            continue
        end

        echo "Cloning $owner/$name..."

        # Construct target directory
        set -l target_dir "$GHQ_ROOT/github.com/$owner/$name"

        # Check if already exists
        if test -d "$target_dir"
            echo "Already exists: $target_dir"
            continue
        end

        # Create parent directory
        mkdir -p (dirname "$target_dir")

        # Clone repository using HTTPS
        set -l clone_url "https://github.com/$owner/$name.git"
        if git clone "$clone_url" "$target_dir"
            echo "Successfully cloned to: $target_dir"
        else
            echo "Error: Failed to clone $clone_url"
        end
    end
end

alias gg='ghqget'

