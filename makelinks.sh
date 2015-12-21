#!/bin/bash

files="bashrc conkyrc emacs gitconfig zshrc dircolors \
       environ profile tmux.conf"
confdir=Documents/Config
h=$(hostname)

for f in $files ; do

    if [ -f $f.$h ] ; then
	echo "Link $f.$h to ~/.$f"
	ln -sf $confdir/$f.$h ~/.$f
    else
	echo "Link $f to ~/.$f"
	ln -sf $confdir/$f ~/.$f
    fi

done
