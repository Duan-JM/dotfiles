#!/bin/bash

###############
#  CONFIGURE  #
###############


DOT_FILE='/Users/deamov/Documents/Github/VDeamoV-dotfiles'
VIMRC_FILE='/Users/deamov/Documents/Github/VDeamoV-vimrc'


##########################
#  BACKUP VIM CONFIGURE  #
##########################
# back up to dotfiles
cp -rf ~/.vim/fonts $DOT_FILE/vim
cp -rf ~/.vim/colors $DOT_FILE/vim
cp -rf ~/.vim/autoload $DOT_FILE/vim
cp ~/.vimrc $DOT_FILE/vim/vimrc
cp ~/.vim/coc-settings.json $DOT_FILE/vim/coc-settings.json

# back up to vimrc
cp -rf ~/.vim/fonts $VIMRC_FILE
cp -rf ~/.vim/colors $VIMRC_FILE
cp -rf ~/.vim/autoload $VIMRC_FILE
cp ~/.vimrc $VIMRC_FILE/vimrc
cp ~/.vim/coc-settings.json $VIMRC_FILE/coc-settings.json


###########################
#  BACKUP TMUX CONFIGURE  #
###########################
cp -rf ~/.tmux.conf $DOT_FILE/tmux/tmux.conf


##############
#  BACK ZSH  #
##############
# back up zsh to dotfiles
# plugin should install with command below
# git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
cp ~/.zshrc $DOT_FILE/zsh/zshrc
cp -rf ~/.zsh-config $DOT_FILE/zsh

