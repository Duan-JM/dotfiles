#!/bin/bash
set -euo pipefail

###############
#  CONFIGURE  #
###############

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOT_FILE="$(cd "${SCRIPT_DIR}/.." && pwd)"

trim_secret_value() {
  local value="$1"

  value="${value%%#*}"
  value="${value%%//*}"
  value="${value%,}"
  value="${value%;}"
  value="${value#"${value%%[![:space:]]*}"}"
  value="${value%"${value##*[![:space:]]}"}"

  if [[ "$value" == \"*\" && "$value" == *\" ]]; then
    value="${value#\"}"
    value="${value%\"}"
  elif [[ "$value" == \'*\' && "$value" == *\' ]]; then
    value="${value#\'}"
    value="${value%\'}"
  fi

  printf '%s' "$value"
}

is_placeholder_secret_value() {
  local value value_lower
  value="$(trim_secret_value "$1")"
  value_lower="$(printf '%s' "$value" | tr '[:upper:]' '[:lower:]')"

  case "$value_lower" in
    ""|none|null|nil|false|changeme|change_me|placeholder|example|dummy|test|xxx|xxxx|xxxxx|your_*)
      return 0
      ;;
    '$'*|'${'*)
      return 0
      ;;
  esac

  return 1
}

scan_file_for_secrets() {
  local file="$1"
  local display_path="${file/#$HOME/\$HOME}"

  case "$file" in
    */.env|*/.env.*|*/.netrc|*/.npmrc|*/.pypirc|*/id_rsa|*/id_dsa|*/id_ecdsa|*/id_ed25519|*.pem|*.p12|*.pfx|*.key)
      echo "warning: secret-like file path found: $display_path" >&2
      return 1
      ;;
  esac

  if ! LC_ALL=C grep -Iq . "$file"; then
    return 0
  fi

  local line_number=0
  local line secret_value
  shopt -s nocasematch
  while IFS= read -r line || [[ -n "$line" ]]; do
    line_number=$((line_number + 1))

    if [[ "$line" =~ -----BEGIN[[:space:]][A-Z0-9[:space:]]*PRIVATE[[:space:]]KEY----- ]]; then
      echo "warning: private key block found: $display_path:$line_number" >&2
      return 1
    fi

    if [[ "$line" =~ ^[[:space:]]*(#|//) ]]; then
      continue
    fi

    if [[ "$line" =~ (API[_-]?KEY|TOKEN|SECRET|PASSWORD|PASSWD|PRIVATE[_-]?KEY|ACCESS[_-]?KEY|CLIENT[_-]?SECRET|AUTH[_-]?TOKEN|CREDENTIAL)[A-Za-z0-9_-]*[[:space:]]*[:=][[:space:]]*(.+)$ ]]; then
      secret_value="${BASH_REMATCH[2]}"
      if ! is_placeholder_secret_value "$secret_value"; then
        echo "warning: secret-like assignment found: $display_path:$line_number" >&2
        return 1
      fi
    fi
  done < "$file"
}

scan_path_for_secrets() {
  local source_path="$1"
  local failed=0
  local file

  if [[ -f "$source_path" ]]; then
    scan_file_for_secrets "$source_path"
    return
  fi

  while IFS= read -r -d '' file; do
    if ! scan_file_for_secrets "$file"; then
      failed=1
    fi
  done < <(find "$source_path" -type f ! -path '*/.git/*' -print0)

  if [[ "$failed" -ne 0 ]]; then
    echo "warning: potential secrets were found under ${source_path/#$HOME/\$HOME}" >&2
    return 1
  fi
}

confirm_secret_risk() {
  local source_path="$1"
  local answer

  if scan_path_for_secrets "$source_path"; then
    return 0
  fi

  if ! read -r -p "Potential secrets were found. Continue backing up ${source_path/#$HOME/\$HOME}? [y/N] " answer; then
    echo "error: backup aborted because potential secrets were found and no confirmation was provided" >&2
    return 1
  fi

  case "$answer" in
    [yY]|[yY][eE][sS])
      echo "warning: continuing backup with potential secrets: ${source_path/#$HOME/\$HOME}" >&2
      return 0
      ;;
    *)
      echo "error: backup aborted by user" >&2
      return 1
      ;;
  esac
}

backup_file() {
  local source_file="$1"
  local target_file="$2"

  if [[ ! -f "$source_file" ]]; then
    echo "warning: skip missing file: $source_file" >&2
    return
  fi

  confirm_secret_risk "$source_file"

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

  confirm_secret_risk "$source_dir"

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
