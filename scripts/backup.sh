#!/bin/bash
set -euo pipefail

###############
#  CONFIGURE  #
###############

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_FILE="$(cd "${SCRIPT_DIR}/.." && pwd)"

backup_file() {
  local source_file="$1"
  local target_file="$2"

  if [[ ! -f "$source_file" ]]; then
    echo "warning: skip missing file: $source_file" >&2
    return
  fi

  mkdir -p "$(dirname "$target_file")"
  cp -f "$source_file" "$target_file"
}

backup_dir() {
  local source_dir="$1"
  local target_dir="$2"

  if [[ ! -d "$source_dir" ]]; then
    echo "warning: skip missing directory: $source_dir" >&2
    return
  fi

  if [[ -d "$target_dir" ]]; then
    local source_real target_real
    source_real="$(cd "$source_dir" && pwd -P)"
    target_real="$(cd "$target_dir" && pwd -P)"
    if [[ "$source_real" == "$target_real" ]]; then
      echo "info: skip unchanged directory: $source_dir -> $target_dir"
      return
    fi
  fi

  mkdir -p "$(dirname "$target_dir")"
  rm -rf -- "$target_dir"
  cp -R "$source_dir" "$target_dir"
}


##############################
#  BACKUP NEOVIM CONFIGURE  #
##############################
# back up to dotfiles
backup_dir "$HOME/.config/nvim" "$DOT_FILE/vim"


###########################
#  BACKUP TMUX CONFIGURE  #
###########################
backup_file "$HOME/.tmux.conf" "$DOT_FILE/tmux/tmux.conf"
backup_dir "$HOME/.tmux" "$DOT_FILE/tmux/tmux"


##############
#  BACK ZSH  #
##############
# back up zsh to dotfiles
# plugin should install with command below
# git clone https://github.com/zsh-users/zsh-syntax-highlighting ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
backup_file "$HOME/.zshrc" "$DOT_FILE/zsh/zshrc"
backup_dir "$HOME/.zsh-config" "$DOT_FILE/zsh/.zsh-config"


#####################
#  Pylint & flake8  #
#####################
# cp ~/.pylintrc $DOT_FILE/rc-files/pylintrc


#########
# Kitty #
#########
backup_file "$HOME/.config/kitty/kitty.conf" "$DOT_FILE/kitty/kitty.conf"
