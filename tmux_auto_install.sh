#!/bin/bash

if [ $(uname) == "Darwin" ]; then
  echo "Dectect MacOS"

  if command -v brew >/dev/null 2>&1; then 
    echo 'brew detected, skip install brew' 
  else 
    echo 'no exists brew, installing' 
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  if command -v git >/dev/null 2>&1; then 
    echo 'git detected, skip install git' 
  else 
    echo 'no exists git, installing' 
    brew install git
  fi

  if command -v tmux >/dev/null 2>&1; then
    echo 'tmux detected, skip install tmux'
  else
    echo 'no exist tmux, installing'
    brew install tmux
  fi

elif [ $(uname) == "Linux" ]; then
  echo "Detect Linux"

  if command -v git >/dev/null 2>&1; then 
    echo 'git detected, skip install git' 
  else 
    echo 'no exists git, installing' 
    sudo apt install git
  fi

  if command -v tmux >/dev/null 2>&1; then
    echo 'tmux detected, skip install tmux'
  else
    echo 'no exist tmux, installing'
    sudo apt install tmux
  fi

# simple script
cp -r ./tmux/tmux.conf ~/.tmux.conf
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
bash ~/.tmux/plugins/tpm/bin/install_plugins
