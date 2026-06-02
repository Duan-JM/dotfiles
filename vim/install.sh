#!/usr/bin/env bash
#
# Author: Duan-JM
# e-mail: vincent.duan95@gmail.com
#
# Install Neovim and its dependencies, then symlink this config into
# ~/.config/nvim so future updates to the dotfiles repo take effect
# automatically.
#
# Usage:
#   bash ./install.sh            # run with sudo for system packages on Linux
#   bash ./install.sh ""         # disable sudo prefix (e.g. running as root)

set -euo pipefail

COMMAND_PREFIX="${1-sudo}"

# Resolve the absolute path of this script (no readlink -f on macOS by default).
resolve_path() {
  python3 -c "import os,sys; print(os.path.realpath(sys.argv[1]))" "$1"
}
SCRIPT="$(resolve_path "$0")"
SCRIPTPATH="$(dirname "$SCRIPT")"

info() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [INFO]  $*"; }
err()  { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [ERROR] $*" >&2; }

# ---------------------------------------------------------------------------
# macOS
# ---------------------------------------------------------------------------
ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    info "Homebrew detected"
    return
  fi
  info "Installing Homebrew"
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

brew_install_if_missing() {
  local pkg="$1"
  if brew list --formula 2>/dev/null | grep -qx "$pkg"; then
    info "$pkg already installed"
  else
    info "Installing $pkg"
    brew install "$pkg" || err "Failed to install $pkg"
  fi
}

macos_install() {
  info "Detected macOS"
  ensure_brew

  # Core packages (treesitter / telescope / LSP tooling all want these).
  local pkgs=(neovim node git universal-ctags python3 ripgrep fd)
  for pkg in "${pkgs[@]}"; do
    brew_install_if_missing "$pkg"
  done

  info "Installing formatters"
  for fmt in prettier isort stylua black google-java-format; do
    brew_install_if_missing "$fmt" || true
  done
}

# ---------------------------------------------------------------------------
# Ubuntu / Debian
# ---------------------------------------------------------------------------
ubuntu_install() {
  info "Detected Linux"

  ${COMMAND_PREFIX} apt-get update -y

  local pkgs=(
    curl make git python3-pip ripgrep fd-find
    autoconf autogen pkg-config libjansson-dev
    software-properties-common
  )
  ${COMMAND_PREFIX} apt-get install -y "${pkgs[@]}"

  # Neovim from official PPA (stable).
  if ! command -v nvim >/dev/null 2>&1; then
    info "Adding neovim PPA and installing"
    ${COMMAND_PREFIX} apt-add-repository -y ppa:neovim-ppa/stable
    ${COMMAND_PREFIX} apt-get update -y
    ${COMMAND_PREFIX} apt-get install -y neovim
  else
    info "neovim detected ($(nvim --version | head -n1))"
  fi

  # Node.js 20.x.
  if ! command -v node >/dev/null 2>&1; then
    info "Installing Node.js 20.x"
    curl -fsSL https://deb.nodesource.com/setup_20.x | ${COMMAND_PREFIX} bash -
    ${COMMAND_PREFIX} apt-get install -y nodejs
  else
    info "node detected ($(node -v))"
  fi

  # universal-ctags from source (apt's ctags is the old exuberant-ctags).
  if ! command -v ctags >/dev/null 2>&1; then
    info "Building universal-ctags from source"
    local tmpdir
    tmpdir="$(mktemp -d)"
    git clone https://github.com/universal-ctags/ctags.git --depth=1 "$tmpdir"
    pushd "$tmpdir" >/dev/null
    ./autogen.sh
    ./configure
    make
    ${COMMAND_PREFIX} make install
    popd >/dev/null
    rm -rf "$tmpdir"
  fi
}

# ---------------------------------------------------------------------------
# Common
# ---------------------------------------------------------------------------
install_python_support() {
  info "Installing pynvim (python LSP/RPC support)"
  if python3 -m pip install --user --upgrade pynvim --break-system-packages 2>/dev/null; then
    return
  fi
  python3 -m pip install --user --upgrade pynvim
}

# Move an existing path to a timestamped backup so re-running the script
# never overwrites a previous backup.
backup_path() {
  local target="$1"
  if [[ -e "$target" || -L "$target" ]]; then
    local backup
    backup="${target}.bak.$(date +%Y%m%d%H%M%S)"
    info "Backing up $target -> $backup"
    mv "$target" "$backup"
  fi
}

deploy_config() {
  local nvim_cfg="${HOME}/.config/nvim"
  mkdir -p "${HOME}/.config"

  backup_path "${HOME}/.vim"
  backup_path "${HOME}/.vimrc"
  backup_path "$nvim_cfg"

  info "Symlinking $SCRIPTPATH -> $nvim_cfg"
  ln -sfn "$SCRIPTPATH" "$nvim_cfg"
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------
main() {
  info "===> Installing Neovim and prerequisites <==="
  case "$(uname)" in
    Darwin) macos_install ;;
    Linux)  ubuntu_install ;;
    *)      err "Unsupported OS: $(uname)"; exit 1 ;;
  esac

  install_python_support
  deploy_config

  info "===> All done. Launch nvim; lazy.nvim will sync plugins on first run. <==="
}

main "$@"
