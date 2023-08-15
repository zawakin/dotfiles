if status is-interactive
    # Commands to run in interactive sessions can go here
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

set -x GOPATH $HOME/go $GOPATH
set -x PATH $GOPATH/bin $PATH

# for go wasm
# set -x PATH (go env GOROOT)/misc/wasm $PATH
# set -x PATH $HOME/.cargo/bin $PATH

source /usr/local/opt/asdf/libexec/asdf.fish

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

bind \cG cd_fzy_ghqlist
