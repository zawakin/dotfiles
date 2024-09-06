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

set -Ua fish_user_paths "$HOME/.rye/shims"

# for voicevox
set -x DYLD_LIBRARY_PATH $HOME/.local/models/voicevox_core $DYLD_LIBRARY_PATH

# for go wasm
# set -x PATH (go env GOROOT)/misc/wasm $PATH
# set -x PATH $HOME/.cargo/bin $PATH

# source /usr/local/opt/asdf/libexec/asdf.fish
source /opt/homebrew/opt/asdf/libexec/asdf.fish

export LSCOLORS=gxfxcxdxbxegedabagacad

# -- functions
function cd_fzy_ghqlist
    set -l ghq_root (ghq root)
    set -l repo (ghq list -p | sed 's;'$ghq_root'/;;g' | fzy)
    if [ -n "$repo" ]
        cd $ghq_root'/'$repo
    end
    commandline -f repaint
end

function cd_fzy_projects
    set -l projects_dir $HOME/projects
    set -l selected_dir (find $projects_dir -maxdepth 1 -type d | fzy)
    # set -l selected_dir (find $projects_dir -maxdepth 1 -type d | sed "s|$projects_dir/||" | fzy)
    if [ -n "$selected_dir" ]
        cd $selected_dir
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
    set -l selected_branch (echo -e "$branch_info" | fzy | string match -r '^[^:]*')

    # 選択したブランチに切り替え
    if test -n "$selected_branch"
        echo "Switching to branch: $selected_branch"
        git switch $selected_branch
    else
        echo "Branch switch cancelled."
    end
    commandline -f repaint
end

bind \cG cd_fzy_ghqlist
bind \cH cd_fzy_projects
bind \cB git-switch-enhanced

set -x EDITOR vim
direnv hook fish | source

set -g direnv_fish_mode eval_on_arrow    # trigger direnv at prompt, and on every arrow-based directory change (default)
set -g direnv_fish_mode eval_after_arrow # trigger direnv at prompt, and only after arrow-based directory changes before executing command
set -g direnv_fish_mode disable_arrow    # trigger direnv at prompt only, this is similar functionality to the original behavior

set -x ASDF_GOLANG_MOD_VERSION_ENABLED true

# uv
fish_add_path "$HOME/.local/bin"

