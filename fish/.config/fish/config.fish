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

bind \cG cd_fzy_ghqlist
bind \cH cd_fzy_projects
bind \cB git-switch-enhanced

set -x EDITOR vim

# Open URLs in Chrome "PR" profile (used by mise run git:open-pr)
set -gx OPEN_URL_CMD "$HOME/dotfiles/scripts/open-chrome-pr.sh"
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

export PATH="$HOME/.local/bin:$PATH"
