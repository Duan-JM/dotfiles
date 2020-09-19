#!/bin/bash
#
# Author: Duan-JM
# e-mail: vincent.duan95@gmail.com
# Install neovim & its relevant dependencies

SUDO_PREFIX='sudo'

#######################################
# Output error messages with time
# Globals:
#   error messages
# Arguments:
#   None
#######################################
err() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&2
}

#######################################
# Output info messages with time
# Globals:
#   info messages
# Arguments:
#   None
#######################################
info() {
  echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')]: $*" >&1
}

if [[ $(uname) == "Darwin" ]]; then
  info "Dectect MacOS"
  if command -v brew >/dev/null 2>&1; then 
    info 'brew detected, skip install brew' 
  else 
    info 'no exists brew, installing' 
    /usr/bin/ruby -e \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # install node for coc
  if command -v node > /dev/null 2>&1; then
    echo 'node existing, plz manually check its version'
    node -v
  else
    echo "installing node >= 10.12"
    curl -sL install-node.now.sh/lts | bash
    node -v
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


elif [ "$(uname)" == "Linux" ]; then
  echo "Detect Linux"

  # installing neovim
  if command -v nvim >/dev/null 2>&1; then
    echo "neovim detected"
  else
    echo 'no existing neovim, installing'
    ${SUDO_PREFIX} apt-add-repository ppa:neovim-ppa/unstable --yes # if you want to install latest version change `stable` to `unstable`
    ${SUDO_PREFIX} apt update -y
    ${SUDO_PREFIX} apt-get install neovim --yes
  fi

  # install node for coc
  if command -v node > /dev/null 2>&1; then
    echo 'node existing, plz manually check its version'
    node -v
  else
    echo "installing node >= 10.12"
    ${SUDO_PREFIX} apt-get install nodejs npm -y
    ${SUDO_PREFIX} npm install n -g --registry https://registry.npm.taobao.org
    ${SUDO_PREFIX} n stable
    ${SUDO_PREFIX} node -v
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
    ${SUDO_PREFIX} apt-get install python3-pip -y
  fi

else
  echo "Scripts do not support $(uname)"
fi

echo "Add python support"
pip3 install pynvim

echo "Copy the Configure Files"
if [ -f "${HOME}/.vim" ]; then
  echo "backup existing vim config file"
  cp -rf "${HOME}"/.vim "${HOME}"/.vimrc_bak
  echo "deleting existing vim config file"
  rm -rf "${HOME}"/.vim
fi

if [ -f "${HOME}/.vimrc" ]; then
  echo "backup existing vimrc"
  cp "${HOME}"/.vimrc "${HOME}"/.vimrc.bak
  echo "deleting existing vimrc"
  rm "${HOME}"/.vimrc
fi

cp -rf ../vim "${HOME}"/.vim
cp -rf ./vimrc "${HOME}"/.vimrc

echo "Changing relevant linking"

if [ -d "${HOME}/.config/" ]; then
  echo "Existing ${HOME}/.config file"
else
  echo "No ${HOME}/.config dir creating"
  mkdir "${HOME}"/.config/
fi

if [ -f "${HOME}/.config/nvim" ] || [ -d "${HOME}/.config/nvim" ]; then
  echo "deleting existing nvim config file"
  rm -rf "${HOME}"/.config/nvim
  mkdir "${HOME}"/.config/nvim
fi

if [ -f "${HOME}/.config/nvim/init.vim" ]; then
  echo "deleting existing nvim config file"
  rm "${HOME}"/.config/nvim/init.vim
fi

echo "Creating link to nvim configfile"
ln -s "${HOME}"/.vim "${HOME}"/.config/nvim
ln -s "${HOME}"/.vimrc "${HOME}"/.config/nvim/init.vim

echo "Installing ctags for Vista"
if [ "$(uname)" == "Darwin" ]; then
  brew tap universal-ctags/universal-ctags
  brew install --with-jansson --HEAD universal-ctags/universal-ctags/universal-ctags

elif [ "$(uname)" == "Linux" ]; then
  echo "install autoconf autogen"
  ${SUDO_PREFIX} apt-get install autoconf autogen pkg-config

  echo "Install ctags"
  ${SUDO_PREFIX} apt-get install libjansson-dev
  git clone https://github.com/universal-ctags/ctags.git --depth=1 /tmp/ctags
  cd /tmp/ctags || exit
  ${SUDO_PREFIX} ./autogen.sh 
  ${SUDO_PREFIX} ./configure
  ${SUDO_PREFIX} make
  ${SUDO_PREFIX} make install
fi

echo "Installing rg for Leaderf"
if [ "$(uname)" == "Darwin" ]; then
  echo "install ripgrep for MacOS"
  brew install ripgrep

elif [ "$(uname)" == "Linux" ]; then
  echo "install ripgrep for Linux"
  ${SUDO_PREFIX} apt-get install ripgrep
fi

echo "Installing Pylint autopep8 jedi flake8"
pip3 install flake9 mypy pylint pylint-quotes pycodestyle autopep8

echo "Installing Plugins"
vim -c PlugInstall +qa

echo "Install Coc-plugins"
vim -c 'CocInstall coc-clangd coc-python coc-json coc-snippets' +qa

echo "We are good to go now, Happy Vimming"
echo "If configure is not set up correctly, please check out if ${HOME}/.config/nvim and ${HOME}/.config/nvim/init.vim are generated properly"
