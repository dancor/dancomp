#!/bin/zsh

# 10ms for key sequences
KEYTIMEOUT=1

HISTFILE=~/.histfile
HISTSIZE=1000
SAVEHIST=1000
autoload -Uz compinit
compinit

setopt appendhistory
setopt autopushd
setopt extendedglob
setopt hist_ignore_all_dups
setopt nobeep
setopt nolistambiguous
setopt nomatch
setopt notify
setopt pushdignoredups

zstyle ":completion:*:commands" rehash 1

# tab completion stuff
typeset -U fpath
fpath=(~/.zsh/fun $fpath)
autoload -U ~/.zsh/fun/*(:t)
compdef _c c
compdef _wh wh
compdef _wh cw
compdef _wh vw
compdef _vs vs
compdef _sudo so
compdef _gitkill g
compdef _optirun optirun
compdef _optirun gpu
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
  }
;;
esac
