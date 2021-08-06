# General config
bindkey -e # emacs
export LANGUAGE="ja_JP.UTF-8"
export LANG="${LANGUAGE}"
export LC_ALL="${LANGUAGE}"
export EDITOR=vim
export CLICOLOR=1

# General zsh config
setopt correct           # コマンドのスペルチェック
setopt auto_list         # 補完候補が複数ある時に、一覧表示
setopt auto_menu         # 補完キー（Tab, Ctrl+I) を連打するだけで順に補完候補を自動で補完
setopt no_list_types     # auto_list の補完候補一覧で、ls -F のようにファイルの種別をマーク表示しない
setopt magic_equal_subst # コマンドラインの引数で --prefix=/usr などの = 以降でも補完できる
setopt auto_param_slash  # ディレクトリ名の補完で末尾の / を自動的に付加し、次の補完に備える
setopt mark_dirs         # ファイル名の展開でディレクトリにマッチした場合末尾に / を付加する
setopt auto_param_keys   # 自動補完される余分なカンマなどを適宜削除してスムーズに入力できるように
setopt rc_expand_param   # {}をbash ライクに展開
setopt list_packed       # 補完候補を詰めて表示
setopt print_eight_bit   # 8 ビット目を通すようになり、日本語のファイル名を表示可能
LISTMAX=0                # 補完は画面表示を超える時にだけ聞く

# General zsh config (histories)
setopt extended_history   # 履歴ファイルに時刻を記録
setopt hist_no_store      # history コマンドをヒストリにいれない
setopt hist_reduce_blanks # 履歴から冗長な空白を除く
setopt hist_no_functions  # 関数定義をヒストリに入れない

# Misc config
export PATH=/usr/local/opt/coreutils/libexec/gnubin:/usr/local/opt/gnu-sed/libexec/gnubin:/usr/local/opt/grep/libexec/gnubin:/usr/local/opt/findutils/libexec/gnubin:$PATH
export PATH=$PATH:/usr/local/sbin:$HOME/.nodebrew/current/bin:$GOPATH/bin
export HOMEBREW_NO_AUTO_UPDATE="1"

# Misc aliases
alias ls='ls --color -F'
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

# ===== Functions =====
# Ctrl-g: Cd-to-ghq-repository
function cd-fzy-ghqlist() {
  local GHQ_ROOT=$(ghq root)
  local REPO=$(ghq list -p | sed -e 's;'${GHQ_ROOT}/';;g' | fzy)
  if [ -n "${REPO}" ]; then
    BUFFER="cd ${GHQ_ROOT}/${REPO}"
  fi
  zle accept-line
}
zle -N cd-fzy-ghqlist
bindkey '^G' cd-fzy-ghqlist

alias chrome="open -a 'Google Chrome'"

export GOPATH=$HOME/go
export GOROOT="$(brew --prefix golang)/libexec"
export PATH="$PATH:${GOPATH}/bin:${GOROOT}/bin"

# export PATH=$PATH:$HOME/google-cloud-sdk/bin
