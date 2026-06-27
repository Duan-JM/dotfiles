#!/bin/bash
set -euo pipefail

SUDO_PREFIX=${1:-}
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

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

if [ "$(uname)" == "Darwin" ]; then
  echo "Dectect MacOS"

  if command -v brew >/dev/null 2>&1; then
    echo 'brew detected, skip install brew'
  else
    echo 'no exists brew, installing'
    NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if command -v git >/dev/null 2>&1; then
    echo 'git detected, skip install git'
  else
    echo 'no exists git, installing'
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --quiet git
  fi

  if command -v tmux >/dev/null 2>&1; then
    echo 'tmux detected, skip install tmux'
  else
    echo 'no exist tmux, installing'
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --quiet tmux
  fi

elif [ "$(uname)" == "Linux" ]; then
  echo "Detect Linux"

  if command -v git >/dev/null 2>&1; then
    echo 'git detected, skip install git'
  else
    ${SUDO_PREFIX} apt install git --yes
  fi

  if command -v tmux >/dev/null 2>&1; then
    echo 'tmux detected, skip install tmux'
  else
    echo 'no exist tmux, installing'
    ${SUDO_PREFIX} apt install tmux --yes
  fi
fi

# simple script
if [ -d "${HOME}/.tmux/" ]; then
  info "backup existing tmux config file"
  cp -rf "${HOME}"/.tmux "${HOME}"/.tmux_bak || { err "Backup failed interrupt"; exit 1; }
  info "deleting existing tmux config file"
  rm -rf "${HOME}"/.tmux
fi

info "Creating the Tmux Configure Files"
cp -rf "${SCRIPTPATH}/tmux.conf" "${HOME}/.tmux.conf"
cp -rf "${SCRIPTPATH}/tmux" "${HOME}/.tmux"

info "Installing the Tmux plugins"
if [ -d "${HOME}/.tmux/plugins/tpm/" ]; then
  info "tpm founded, skipping"
else
  info "tpm not found, installing tpm."
  git clone https://github.com/tmux-plugins/tpm "${HOME}/.tmux/plugins/tpm"
fi

info "Installing plugins"
bash "${HOME}/.tmux/plugins/tpm/bin/install_plugins"
