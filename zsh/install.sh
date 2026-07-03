#!/bin/bash
SUDO_PREFIX=${1:-sudo}
SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"

install_fzf() {
  if command -v fzf >/dev/null 2>&1; then
    echo 'fzf detected, skip install fzf'
  else
    echo 'no exist fzf, installing'
    if [ "$(uname)" == "Darwin" ]; then
      HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --quiet fzf
    elif [ "$(uname)" == "Linux" ]; then
      ${SUDO_PREFIX} apt install --yes fzf
    fi
  fi

  if [ ! -d "${HOME}/.fzf" ]; then
    echo 'no exist fzf shell integration, installing'
    git clone --depth 1 https://github.com/junegunn/fzf.git "${HOME}/.fzf"
  else
    echo 'fzf shell integration detected, skip clone'
  fi

  if [ -x "${HOME}/.fzf/install" ]; then
    "${HOME}/.fzf/install" --all --no-bash --no-fish --no-update-rc
  else
    echo "fzf installer not found at ${HOME}/.fzf/install"
    return 1
  fi
}

# os check
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

  if command -v zsh >/dev/null 2>&1; then
    echo 'zsh detected, skip install zsh'
  else
    echo 'no exist zsh, installing'
    HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --quiet zsh
    ${SUDO_PREFIX} chsh -s /bin/zsh "$USER"
  fi

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo 'no exist oh my zsh, installing'
    git clone https://github.com/robbyrussell/oh-my-zsh.git "${HOME}/.oh-my-zsh"
  else
    echo 'oh my zsh detected, skip installing'
  fi

elif [ "$(uname)" == "Linux" ]; then
  echo "Detect Linux"

  if command -v git >/dev/null 2>&1; then
    echo 'git detected, skip install git'
  else
    echo 'no exists git, installing'
    ${SUDO_PREFIX} apt install --yes git make
  fi

  if command -v zsh >/dev/null 2>&1; then
    echo 'zsh detected, skip install zsh'
  else
    echo 'no exist zsh, installing'
    ${SUDO_PREFIX} apt install --yes zsh
    ${SUDO_PREFIX} chsh -s /bin/zsh "$USER"
  fi

  if [ ! -d "${HOME}/.oh-my-zsh" ]; then
    echo 'no exist oh my zsh, installing'
    git clone https://github.com/robbyrussell/oh-my-zsh.git "${HOME}/.oh-my-zsh"
  else
    echo 'oh my zsh detected, skip installing'
  fi

else
  echo "Scripts do not support $(uname)"
fi

install_fzf

echo "Copy the Configure Files"

cp "${SCRIPTPATH}/zshrc" "${HOME}/.zshrc"
cp -rf "${SCRIPTPATH}/.zsh-config" "${HOME}/.zsh-config"

echo "Installing Plugins"
git clone https://github.com/zsh-users/zsh-syntax-highlighting "${HOME}/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting"
git clone https://github.com/zsh-users/zsh-autosuggestions "${HOME}/.oh-my-zsh/custom/plugins/zsh-autosuggestions"

echo "Installing Themes"
git clone https://github.com/iplaces/astro-zsh-theme.git /tmp/astro-zsh-theme
cp /tmp/astro-zsh-theme/astro.zsh-theme "${HOME}/.oh-my-zsh/themes/"

echo "Install Finished, Please manually change default bash to zsh"
