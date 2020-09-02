#!/bin/bash

###############
#  CONFIGURE  #
###############

DOT_FILE=`pwd`


##########################
#  BACKUP VIM CONFIGURE  #
##########################
# back up to dotfiles
cp -rf ~/.vim/fonts $DOT_FILE/vim
cp -rf ~/.vim/colors $DOT_FILE/vim
cp -rf ~/.vim/autoload $DOT_FILE/vim
cp ~/.vimrc $DOT_FILE/vim/vimrc


###########################
#  BACKUP TMUX CONFIGURE  #
###########################
cp -rf ~/.tmux.conf $DOT_FILE/tmux/tmux.conf
rm -rf $DOT_FILE/tmux/tmux
cp -rf ~/.tmux $DOT_FILE/tmux/tmux


##############
#  BACK ZSH  #
##############
# back up zsh to dotfiles
# plugin should install with command below
# git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
cp ~/.zshrc $DOT_FILE/zsh/zshrc
cp -rf ~/.zsh-config/* $DOT_FILE/zsh/zsh-config/


#####################
#  Pylint & flake8  #
#####################
cp ~/.pylintrc $DOT_FILE/rc-files/pylintrc

