#!/bin/bash
SUDO_PREFIX=$1
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

# os check
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

  if command -v zsh >/dev/null 2>&1; then
    echo 'zsh detected, skip install zsh'
  else
    echo 'no exist zsh, installing'
    brew install zsh
    chsh -s /bin/zsh
  fi

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo 'no exist oh my zsh, installing'
    git clone https://github.com/robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh
  else
    echo 'oh my zsh detected, skip installing'
  fi

elif [ $(uname) == "Linux" ]; then
  echo "Detect Linux"

  if command -v git >/dev/null 2>&1; then
    echo 'git detected, skip install git'
  else
    echo 'no exists git, installing'
    ${SUDO_PREFIX} apt install git make
  fi

  if command -v zsh >/dev/null 2>&1; then
    echo 'zsh detected, skip install zsh'
  else
    echo 'no exist zsh, installing'
    ${SUDO_PREFIX} apt install zsh
    chsh -s /bin/zsh
  fi

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo 'no exist oh my zsh, installing'
    git clone https://github.com/robbyrussell/oh-my-zsh.git ${HOME}/.oh-my-zsh
  else
    echo 'oh my zsh detected, skip installing'
  fi

else
  echo "Scripts do not support $(uname)"
fi

echo "Copy the Configure Files"

cp ./zshrc ~/.zshrc
cp -rf ${SCRIPTPATH}/.zsh-config ${HOME}/.zsh-config

echo "Installing Plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting ${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-autosuggestions ${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions

echo "Installing Themes"
git clone https://github.com/iplaces/astro-zsh-theme.git /tmp/astro-zsh-theme
cp /tmp/astro-zsh-theme/astro.zsh-theme ${HOME}/.oh-my-zsh/themes/

echo "Install Finished, Please manually change default bash to zsh"
