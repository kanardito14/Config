#!/bin/bash

homefiles="bashrc conkyrc emacs gitconfig zshrc dircolors \
           environ profile tmux.conf"
emacsfiles="init.el"
confdir=Documents/Config
h=$(hostname)

for f in $homefiles ; do

    if [ -f $f.$h ] ; then
	echo "Link $f.$h to ~/.$f"
	ln -sf $confdir/$f.$h ~/.$f
    else
	echo "Link $f to ~/.$f"
	ln -sf $confdir/$f ~/.$f
    fi

done

for f in $emacsfiles ; do

    echo "Link $f to ~/.emacs.d/$f"
    ln -sf $confdir/$f ~/.emacs.d/$f

done
