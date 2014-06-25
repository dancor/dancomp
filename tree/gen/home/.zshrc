#!/bin/zsh

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
autoload -Uz compinit
compinit

bindkey -v
bindkey '^[[A' up-line-or-history
bindkey '^[[B' down-line-or-history

###
### <madness desc="to get home etc. keys to work in vi mode">
###
# create a zkbd compatible hash;
# to add other keys to this hash, see: man 5 terminfo
typeset -A key

key[Home]=${terminfo[khome]}
key[End]=${terminfo[kend]}
key[Insert]=${terminfo[kich1]}
key[Delete]=${terminfo[kdch1]}
key[Up]=${terminfo[kcuu1]}
key[Down]=${terminfo[kcud1]}
key[Left]=${terminfo[kcub1]}
key[Right]=${terminfo[kcuf1]}
key[PageUp]=${terminfo[kpp]}
key[PageDown]=${terminfo[knp]}

# setup key accordingly
[[ -n "${key[Home]}"    ]]  && bindkey  "${key[Home]}"    beginning-of-line
[[ -n "${key[End]}"     ]]  && bindkey  "${key[End]}"     end-of-line
[[ -n "${key[Insert]}"  ]]  && bindkey  "${key[Insert]}"  overwrite-mode
[[ -n "${key[Delete]}"  ]]  && bindkey  "${key[Delete]}"  delete-char
[[ -n "${key[Up]}"      ]]  && bindkey  "${key[Up]}"      up-line-or-history
[[ -n "${key[Down]}"    ]]  && bindkey  "${key[Down]}"    down-line-or-history
[[ -n "${key[Left]}"    ]]  && bindkey  "${key[Left]}"    backward-char
[[ -n "${key[Right]}"   ]]  && bindkey  "${key[Right]}"   forward-char

###
### </madness>
###

setopt appendhistory
setopt autocd
setopt autopushd
setopt extendedglob
setopt hist_ignore_all_dups
setopt nobeep
setopt nolistambiguous
setopt nomatch
setopt notify
setopt pushdignoredups

zstyle ":completion:*:commands" rehash 1

stty stop undef
mesg n

# tab completion stuff
typeset -U fpath
fpath=(~/.zsh/fun $fpath)
autoload -U ~/.zsh/fun/*(:t)
compdef _wh wh
compdef _wh cw
compdef _wh vw
compdef _vs vs
compdef _pr pr
compdef _sudo so
compdef _gitkill g
frel() {
  local f
  f=(~/.zsh/fun/*(.))
  unfunction $f:t 2> /dev/null
  autoload -U $f:t
}

source ~/.shellrc

sz() {
  source ~/.zshrc
}

_shreload() {
  if [[ "$SHRELOAD_VERSION" -lt "$(cat ~/.shreload/version 2>/dev/null)" ]]
  then
    #sz
    xdr
  fi
}

function precmd() {
  HOST_COL=32
  if [[ x"$(whoami)" == xroot ]]
  then
    HOST_COL=31
  fi
  GIT_COL=33

  HOST_PART='%{[00;'"$HOST_COL"'m%}%m:'
  GIT_PART=''
  GIT_BR="$(git-br-prompt)"
  if [[ -n "$GIT_BR" ]]
  then
    GIT_PART='%{[00;'"$GIT_COL"'m%}'"$GIT_BR"':'
  fi
  PWD_PART_PRE=''
  PWD_PART="${PWD/#\/home\/danl/~}"
  if [[ ${#PWD_PART} -gt 40 ]]
  then
    PWD_PART_PRE='..'
    PWD_PART=${PWD_PART:${#PWD_PART} - 38}
  fi
  PS1="$HOST_PART$GIT_PART$PWD_PART_PRE"'%{[00;36m%}'"$PWD_PART"'%{[00m%}> '
  # clear last executed command name from screen title
  case "$TERM" in
  screen*)
    print -n '\ek '"$@"' '"$(homify "$(pwd)")"'\e\134'
  esac
  _shreload
}

if [[ $- != *i* ]]; then
  return
fi

case "$TERM" in
screen*)
  preexec() {
    shift
    shift
    print -n '\ek '"$@"' '"$(homify "$(pwd)")"'\e\134'
    _shreload
  }
;;
*)
  preexec() {
    _shreload
  }
;;
esac

if which ghc >/dev/null
then
  function hm {
    ghc -e "interact ($*)";
  }
  function hml {
    hm "unlines.($*).lines";
  }
  function hmw {
    hml "map (unwords.($*).words)"
  }
fi

if [[ x"${CONSOLE_AUTO}" == x1 ]]
then
  N=${TTY: -1}
  if [[ x"${N}" == x6 ]]
  then
    unset CONSOLE_AUTO
    exec startx
  else
    tmux-multi-group-prune &
    tmux new-window -d -t 3"${N}"
    tmux new-session -t lalala \; select-window -t 3"${N}" || echo 'could not attach to tmux'
  fi
fi
