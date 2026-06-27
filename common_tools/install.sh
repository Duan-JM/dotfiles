#!/bin/bash
#
# Author: Duan-JM
# e-mail: vincent.duan95@gmail.com
# Install neovim & its relevant dependencies

SUDO_PREFIX=${1:-sudo}

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


info "===========> ------------------------------ <============"
info "===========> Start Installing Common Tools  <============"
info "===========> ------------------------------ <============"

info "===========> ------Common-Tools-Lists------ <============"
info "===========> 1. fd: replace find"

if [[ $(uname) == "Darwin" ]]; then
  info "Dectect MacOS"
  if command -v brew >/dev/null 2>&1; then
    info 'brew detected, skip install brew'
  else
    info 'no exists brew, installing'
    NONINTERACTIVE=1 /bin/bash -c \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  # install fd
  if command -v fd > /dev/null 2>&1; then
    info 'fd existing, plz manually check its version'
  else
    info "installing fd"
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --quiet fd
  fi
fi

if [ "$(uname)" == "Linux" ]; then
  info "Detect Linux"

  # install fd
  if command -v fd > /dev/null 2>&1; then
    info 'fd existing, plz manually check its version'
  else
    info "installing fd"
     ${SUDO_PREFIX} apt-get install -y fd
  fi
fi
