#!/bin/bash
SUDO_PREFIX=$1
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

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
    ${SUDO_PREFIX} apt install git
  fi

  if command -v tmux >/dev/null 2>&1; then
    echo 'tmux detected, skip install tmux'
  else
    echo 'no exist tmux, installing'
    ${SUDO_PREFIX} apt install tmux
  fi
fi

# simple script
cp -rf ${SCRIPTPATH}/tmux.conf ${HOME}/.tmux.conf
cp -rf ${SCRIPTPATH}/tmux ${HOME}/.tmux
git clone https://github.com/tmux-plugins/tpm ${HOME}/.tmux/plugins/tpm
bash ${HOME}/.tmux/plugins/tpm/bin/install_plugins
