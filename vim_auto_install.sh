#!/bin/bash
SUDO_PREFIX=$1

# We only support neovim here
if [ $(uname) == "Darwin" ]; then
  echo "Dectect MacOS"
  if command -v brew >/dev/null 2>&1; then 
    echo 'brew detected, skip install brew' 
  else 
    echo 'no exists brew, installing' 
    /usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # installing neovim
  if command -v nvim >/dev/null 2>&1; then
    echo "neovim detected"
  else
    echo 'no existing neovim, installing'
    brew install update
    brew install utf8proc
    brew install --HEAD neovim
  fi

  if command -v git >/dev/null 2>&1; then 
    echo 'git detected, skip install git' 
  else 
    echo 'no exists git, installing' 
    brew install git
  fi

  if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
    echo 'pip3 detected, skip install pip'
  else
    echo 'no exists pip, installing'
    if command -v python3 >/dev/null 2>&1; then
      python3 get-pip.py
    fi
    if command -v python2 >/dev/null 2>&1; then
      python get-pip.py
    fi
  fi


elif [ $(uname) == "Linux" ]; then
  echo "Detect Linux"

  # installing neovim
  if command -v nvim >/dev/null 2>&1; then
    echo "neovim detected"
  else
    echo 'no existing neovim, installing'
    ${SUDO_PREFIX} apt-add-repository ppa:neovim-ppa/unstable --yes # if you want to install latest version change `stable` to `unstable`
    ${SUDO_PREFIX} apt update
    ${SUDO_PREFIX} apt-get install neovim --yes
  fi

  if command -v git >/dev/null 2>&1; then 
    echo 'git detected, skip install git' 
  else 
    echo 'no exists git, installing' 
    brew install git
  fi

  if command -v pip3 >/dev/null 2>&1; then
    echo 'pip3 detected, skip install pip'
  else
    echo 'no exists pip, installing'
    ${SUDO_PREFIX} apt-get install python3-pip
  fi

else
  echo "Scripts do not support $(uname)"
fi

echo "Add python support"
pip3 install pynvim

echo "Copy the Configure Files"
if [ -f "~/.vim" ]; then
  echo "backup existing vim config file"
  cp -rf ~/.vim ~/.vimrc_bak
  echo "deleting existing vim config file"
  rm -rf ~/.vim
fi

if [ -f "~/.vimrc" ]; then
  echo "backup existing vimrc"
  cp ~/.vimrc ~/.vimrc.bak
  echo "deleting existing vimrc"
  rm ~/.vimrc
fi

cp -rf ./vim ~/.vim
cp -rf ./vim/vimrc ~/.vimrc

echo "Changing relevant linking"

if [ -f "~/.config/nvim" or -d "~/.config/nvim" ]; then
  echo "deleting existing nvim config file"
  rm -rf ~/.config/nvim
  mkdir ~/.config/nvim
fi

if [ -f "~/.config/nvim/init.vim" ]; then
  echo "deleting existing nvim config file"
  rm ~/.config/nvim/init.vim
fi

if [ -d "~/.config/" ]; then
  echo "No ~/.config file creating"
  mkdir ~/.config/
fi

echo "Creating link to nvim configfile"
ln -sf ~/.vim ~/.config/nvim
ln -sf ~/.vimrc ~/.config/nvim/init.vim


if [ $(uname) == "Darwin" ]; then
  # maychange to install node without sudo
  brew install --HEAD universal-ctags/universal-ctags/universal-ctags

elif [ $(uname) == "Linux" ]; then
  echo "Install node for coc"
  ${SUDO_PREFIX} add-apt-repository ppa:chris-lea/node.js --yes
  ${SUDO_PREFIX} apt-get update
  ${SUDO_PREFIX} apt-get install nodejs npm --yes
  ${SUDO_PREFIX} npm config set registry https://registry.npm.taobao.org
  ${SUDO_PREFIX} npm config list
  ${SUDO_PREFIX} npm install n -g
  ${SUDO_PREFIX} n stable
  ${SUDO_PREFIX} node -v
  echo "Install latest node finished"

fi

echo "Installing ctags for Vista"
if [ $(uname) == "Darwin" ]; then
  brew install --HEAD universal-ctags/universal-ctags/universal-ctags

elif [ $(uname) == "Linux" ]; then
  echo "install autoconf autogen"
  ${SUDO_PREFIX} apt-get install autoconf autogen

  echo "Install ctags"
  git clone https://github.com/universal-ctags/ctags.git --depth=1 /tmp/ctags
  cd /tmp/ctags
  ./autogen.sh ./configure
  make
  ${SUDO_PREFIX} make install
fi

echo "Installing Pylint autopep8 jedi flake8"
pip3 install pylint autopep8 jedi
pip3 install flake8 flake8-mypy flake8-bugbear flake8-comprehensions flake8-executable flake8-pyi mccabe pycodestyle pyflakes

echo "We have deprecated coc, so we are Good to Go with simple :PlugInstall"
echo "If configure is not set up correctly, please check out if ~/.config/nvim and ~/.config/nvim/init.vim are generated properly"
