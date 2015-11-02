# Zshrc script

PATH=$PATH:$HOME/Bin

# If not running interactively, don't do anything
[ -z "$PS1" ] && return

# make less more friendly for non-text input files, see lesspipe(1)
[ -x /usr/bin/lesspipe ] && eval "$(SHELL=/bin/sh lesspipe)"

# set variable identifying the chroot you work in (used in the prompt below)
if [ -z "$debian_chroot" ] && [ -r /etc/debian_chroot ]; then
    debian_chroot=$(cat /etc/debian_chroot)
fi

# enable color support of ls and also add handy aliases
if [ -x /usr/bin/dircolors ]; then
    test -r ~/.dircolors && eval "$(dircolors -b ~/.dircolors)" || eval "$(dircolors -b)"
    alias ls='ls --color=auto'
    alias grep='grep --color=auto'
    alias fgrep='fgrep --color=auto'
    alias egrep='egrep --color=auto'
fi

export EDITOR=vi
export GTK2_RC_FILES="$HOME/.gtkrc-2.0"
export LESS="-M -R -W -X"

# Lines configured by zsh-newuser-install

HISTFILE=~/.histfile
HISTSIZE=10000
SAVEHIST=10000
#HIST_IGNORE_ALL_DUPS=1
#HIST_FCNTL_LOCK=1
#HIST_REDUCE_BLANKS=1
#HIST_IGNORE_SPACE
setopt appendhistory extendedglob nomatch histignorealldups histfcntllock histreduceblanks histnostore histignorespace
unsetopt autocd beep notify
# End of lines configured by zsh-newuser-install

# The following lines were added by compinstall
zstyle :compinstall filename '/home/jfleray/.zshrc'

autoload -Uz compinit
compinit
# End of lines added by compinstall

PS1='%F{yellow}%n%f@%F{green}%m%f:%F{cyan}%c%f%F{yellow}[%!]%f%# ' 
RPS1='%F{red}<%?> %F{cyan}%T%f'

precmd () {print -Pn "\e]2;%T   %n@%m:%c\a"}
function title() {print -Pn "\e]2;$1\a"}

alias h=' fc -l -50'
alias ll='ls -l'
alias lh='ls -lh'
alias lgrep='ls -l | grep'
alias hgrep=' fc -l 0 | grep'
alias pgrep='ps -eo 'pid,comm,user,%cpu,%mem,nice,pri,start,time,args' | grep -e '%CPU' -e'
alias purge=" find ~ -type f -name '*~' -print -exec rm {} \;"
alias em='emacs --no-window-system --no-splash'
alias mine='(cd ~/Minetest/minetest; bin/minetest > /dev/null 2>&1)'