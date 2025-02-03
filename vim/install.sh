#!/bin/bash
#
# Author: Duan-JM
# e-mail: vincent.duan95@gmail.com
# Install neovim & its relevant dependencies

COMMAND_PREFIX=$1
SCRIPT=$(readlink -f $0)
SCRIPTPATH=`dirname $SCRIPT`

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

#######################################
# Prepare env for MacOS
# Arguments:
#   None
#######################################
macos_basic_env_install() {
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
    info 'node existing, plz manually check its version'
    node -v
  else
    info "installing node >= 10.12"
    brew install nodejs
    node -v || ! err "node install failed" || exit
  fi

  # installing neovim
  if command -v nvim >/dev/null 2>&1; then
    info "neovim detected"
  else
    info 'no existing neovim, installing'
    brew update
    brew install utf8proc
    brew install --HEAD neovim
    nvim -v || ! err "neovim installed failed" || exit
  fi

  if command -v git >/dev/null 2>&1; then
    info 'git detected, skip install git'
  else
    info 'no exists git, installing'
    brew install git
    git -v || ! err "git install failed" || exit
  fi

  if command -v pip3 >/dev/null 2>&1 || command -v pip >/dev/null 2>&1; then
    info 'pip3 detected, skip install pip'
  else
    info 'no exists pip, installing'
    if command -v python3 >/dev/null 2>&1; then
      python3 get-pip.py
    fi
    if command -v python2 >/dev/null 2>&1; then
      python get-pip.py
    fi
  fi

  info "Installing ctags for Vista"
  brew tap universal-ctags/universal-ctags
  brew install --HEAD universal-ctags/universal-ctags/universal-ctags
  ctags --version || ! err "ctags installed failed" || exit
}

#######################################
# Prepare env for MacOS
# Arguments:
#   None
#######################################
ubuntu_basic_env_install() {
  info "Detect Linux"

  # installing basic tools
  if command -v curl >/dev/null 2>&1; then
    info 'curl exist, skipping'
  else
    info 'no curl found, installing'
    ${COMMAND_PREFIX} apt-get install curl make --yes
  fi

  # installing neovim
  ${COMMAND_PREFIX} apt-add-repository ppa:neovim-ppa/stable --yes # if you want to install latest version change `stable` to `unstable`
  ${COMMAND_PREFIX} apt update --yes
  if command -v nvim >/dev/null 2>&1; then
    info "neovim detected"
  else
    info 'no existing neovim, installing'
    ${COMMAND_PREFIX} apt-get install neovim --yes
  fi

  # install node for coc
  if command -v node > /dev/null 2>&1; then
    info 'node existing, plz manually check its version'
    node -v
  else
    info "installing node == 16.x"
    # deb settings from Digital Ocean
    # https://www.digitalocean.com/community/tutorials/how-to-install-node-js-on-ubuntu-20-04
    curl -sL https://deb.nodesource.com/setup_16.x -o /tmp/nodesource_setup.sh
    ${COMMAND_PREFIX} bash /tmp/nodesource_setup.sh
    ${COMMAND_PREFIX} apt-get install nodejs --yes
    node -v || ! err "node install failed" || exit
  fi

  if command -v git >/dev/null 2>&1; then
    info 'git detected, skip install git'
  else
    info 'no exists git, installing'
    brew install git
  fi

  if command -v pip3 >/dev/null 2>&1; then
    info 'pip3 detected, skip install pip'
  else
    info 'no exists pip, installing'
    ${COMMAND_PREFIX} apt-get install python3-pip -y
  fi

  info "Installing autoconf autogen"
  ${COMMAND_PREFIX} apt-get install autoconf autogen pkg-config
  info "Installing ctags for Vista"
  ${COMMAND_PREFIX} apt-get install libjansson-dev
  git clone https://github.com/universal-ctags/ctags.git --depth=1 /tmp/ctags
  cd /tmp/ctags || exit
  ${COMMAND_PREFIX} ./autogen.sh
  ${COMMAND_PREFIX} ./configure
  ${COMMAND_PREFIX} make
  ${COMMAND_PREFIX} make install
  ctags --version || ! err "ctags installed failed" || exit
}


info "===========> -------------------------------------------- <============"
info "===========> Start Installing Vim and Other Prerequisites <============"
info "===========> -------------------------------------------- <============"
if [[ $(uname) == "Darwin" ]]; then
    macos_basic_env_install
fi

if [ "$(uname)" == "Linux" ]; then
    ubuntu_basic_env_install
else
  err "Scripts do not support $(uname)"
fi


info "===========> ------------------------------------- <============"
info "===========> Start Installing Python Prerequisites <============"
info "===========> ------------------------------------- <============"

info "Add python support"
python3 -m pip install --user pynvim --break-system-packages

info "Installing Pylint autopep8 jedi flake8"
python3 -m pip install --user flake8 autopep8 jedi --break-system-packages


info "===========> --------------------- <============"
info "===========> Start Configuring Vim <============"
info "===========> --------------------- <============"
info "Backup the Original VIM Configure Files"
if [ -f "${HOME}/.vim" ]; then
  info "backup existing vim config file"
  cp -rf "${HOME}"/.vim "${HOME}"/.vimrc_bak || ! err "Backup failed interrupt" || exit
  info "deleting existing vim config file"
  rm -rf "${HOME}"/.vim
fi

if [ -f "${HOME}/.vimrc" ]; then
  info "backup existing vimrc"
  cp "${HOME}"/.vimrc "${HOME}"/.vimrc.bak || ! err "Backup failed interrupt" || exit
  info "deleting existing vimrc"
  rm "${HOME}"/.vimrc
fi

info "Backup the NeoVIM Configure Files"
if [ -f "${HOME}/.config/nvim" ]; then
  info "backup existing vim config file"
  cp -rf "${HOME}"/.config/nvim "${HOME}"/.nvim_bak || ! err "Backup failed interrupt" || exit
  info "deleting existing vim config file"
  rm -rf "${HOME}"/.config/nvim
fi

info "Copy Config file to ~/.vim ~/.vimrc"
cp -rf ${SCRIPTPATH}/../vim "${HOME}"/.vim   || ! err "Copy vim config folder failed" || exit

info "Changing relevant linking"
if [ -d "${HOME}/.config/" ]; then
  info "Existing ${HOME}/.config file"
else
  info "No ${HOME}/.config dir creating"
  ${COMMAND_PREFIX} mkdir "${HOME}"/.config/
fi

if [ -f "${HOME}/.config/nvim" ] || [ -d "${HOME}/.config/nvim" ]; then
  info "deleting existing nvim config file"
  rm -rf "${HOME}"/.config/nvim
fi

info "Creating link to nvim configfile"
ln -s "${HOME}"/.vim "${HOME}"/.config/nvim || ! err "Creating nvim link failed" || exit

info "===========> --------------- <============"
info "===========> One More things <============"
info "===========> --------------- <============"
info "We are good to go now, Happy Vimming"
info "If configure is not set up correctly, please check out if ${HOME}/.config/nvim and ${HOME}/.config/nvim/init.lua are generated properly"
