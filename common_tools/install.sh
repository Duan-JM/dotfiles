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
    /usr/bin/ruby -e \
      "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
  fi

  # install fd
  if command -v fd > /dev/null 2>&1; then
    info 'fd existing, plz manually check its version'
  else
    info "installing fd"
    brew install fd
  fi
fi

if [ "$(uname)" == "Linux" ]; then
  info "Detect Linux"

  # install fd
  if command -v fd > /dev/null 2>&1; then
    info 'fd existing, plz manually check its version'
  else
    info "installing fd"
     ${SUDO_PREFIX} apt-get install fd
  fi
fi
