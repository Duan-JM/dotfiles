#!/usr/bin/env bash
#
# Install Squirrel/Rime with rime-ice and this repo's local customizations.
#
# Usage:
#   bash ./install.sh
#   SKIP_RIME_ICE_DOWNLOAD=1 bash ./install.sh  # only copy local custom files

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
RIME_DIR="${RIME_DIR:-${HOME}/Library/Rime}"
SQUIRREL_APP="/Library/Input Methods/Squirrel.app"
SQUIRREL_BIN="${SQUIRREL_APP}/Contents/MacOS/Squirrel"
RIME_ICE_URL="${RIME_ICE_URL:-https://github.com/iDvel/rime-ice/releases/latest/download/full.zip}"
RIME_ICE_MIRROR_URL="${RIME_ICE_MIRROR_URL:-https://mirror.nju.edu.cn/github-release/iDvel/rime-ice/LatestRelease/full.zip}"
SKIP_RIME_ICE_DOWNLOAD="${SKIP_RIME_ICE_DOWNLOAD:-0}"
SQUIRREL_HANS_ID="im.rime.inputmethod.Squirrel.Hans"

info() { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [INFO]  $*"; }
err()  { echo "[$(date +'%Y-%m-%dT%H:%M:%S%z')] [ERROR] $*" >&2; }

ensure_macos() {
  if [[ "$(uname)" != "Darwin" ]]; then
    err "This Rime setup is for macOS Squirrel only."
    exit 1
  fi
}

ensure_brew() {
  if command -v brew >/dev/null 2>&1; then
    return
  fi
  info "Installing Homebrew"
  NONINTERACTIVE=1 /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
}

ensure_squirrel() {
  if [[ -x "$SQUIRREL_BIN" ]]; then
    info "Squirrel detected"
    return
  fi

  ensure_brew
  info "Installing Squirrel"
  HOMEBREW_NO_AUTO_UPDATE=1 HOMEBREW_NO_INSTALL_CLEANUP=1 brew install --cask squirrel-app
}

repair_squirrel_bundle_signature() {
  local shared_support="${SQUIRREL_APP}/Contents/SharedSupport"
  local generated=()

  [[ -e "${shared_support}/build" ]] && generated+=("${shared_support}/build")
  [[ -e "${shared_support}/installation.yaml" ]] && generated+=("${shared_support}/installation.yaml")
  [[ -e "${shared_support}/user.yaml" ]] && generated+=("${shared_support}/user.yaml")

  if [[ "${#generated[@]}" -eq 0 ]]; then
    return
  fi

  local backup="/Users/Shared/Squirrel.app-generated-backup.$(date +%Y%m%d-%H%M%S)"
  info "Moving generated files out of Squirrel.app to keep the app signature valid"
  sudo mkdir -p "$backup"
  for path in "${generated[@]}"; do
    sudo mv "$path" "$backup/"
  done
  info "Moved generated Squirrel.app files to $backup"
}

backup_rime_dir() {
  if [[ ! -e "$RIME_DIR" ]]; then
    return
  fi

  local backup="${RIME_DIR}.backup.$(date +%Y%m%d-%H%M%S)"
  info "Backing up $RIME_DIR -> $backup"
  ditto "$RIME_DIR" "$backup"
}

download_rime_ice() {
  local dest="$1"
  if curl -fL --connect-timeout 20 --max-time 300 -o "$dest" "$RIME_ICE_URL"; then
    return
  fi

  info "Primary download failed; trying mirror"
  curl -fL --connect-timeout 20 --max-time 300 -o "$dest" "$RIME_ICE_MIRROR_URL"
}

install_rime_ice() {
  if [[ "$SKIP_RIME_ICE_DOWNLOAD" == "1" ]]; then
    info "Skipping rime-ice download"
    return
  fi

  local tmpdir zipfile srcdir
  tmpdir="$(mktemp -d)"
  zipfile="${tmpdir}/rime-ice-full.zip"
  trap 'rm -rf "$tmpdir"' RETURN

  info "Downloading rime-ice"
  download_rime_ice "$zipfile"

  info "Extracting rime-ice"
  unzip -q "$zipfile" -d "$tmpdir"

  if [[ -f "${tmpdir}/rime_ice.schema.yaml" ]]; then
    srcdir="$tmpdir"
  else
    srcdir="$(find "$tmpdir" -mindepth 1 -maxdepth 1 -type d -exec test -f '{}/rime_ice.schema.yaml' ';' -print | head -n 1)"
  fi
  if [[ -z "$srcdir" ]]; then
    err "Could not find extracted rime-ice directory."
    exit 1
  fi

  mkdir -p "$RIME_DIR"
  info "Copying rime-ice files into $RIME_DIR"
  rsync -a \
    --exclude='.git' \
    --exclude='.github' \
    --exclude='build' \
    --exclude='others/asserts' \
    "$srcdir"/ "$RIME_DIR"/

  trap - RETURN
  rm -rf "$tmpdir"
}

install_custom_files() {
  mkdir -p "$RIME_DIR"
  info "Copying local Rime customizations"
  cp "$SCRIPT_DIR/default.custom.yaml" "$RIME_DIR/default.custom.yaml"
  cp "$SCRIPT_DIR/rime_ice.custom.yaml" "$RIME_DIR/rime_ice.custom.yaml"
  cp "$SCRIPT_DIR/squirrel.custom.yaml" "$RIME_DIR/squirrel.custom.yaml"
}

deploy_rime() {
  info "Deploying Rime"
  "$SQUIRREL_BIN" --reload
  "$SQUIRREL_BIN" --register-input-source || true
  "$SQUIRREL_BIN" --enable-input-source "$SQUIRREL_HANS_ID" || true
}

ensure_enabled_input_source() {
  info "Ensuring Squirrel Hans is in AppleEnabledInputSources"
  python3 - <<'PY'
import os
import plistlib
import shutil
import datetime

path = os.path.expanduser('~/Library/Preferences/com.apple.HIToolbox.plist')
entry = {
    'Bundle ID': 'im.rime.inputmethod.Squirrel',
    'Input Mode': 'im.rime.inputmethod.Squirrel.Hans',
    'InputSourceKind': 'Input Mode',
}

if not os.path.exists(path):
    raise SystemExit(0)

with open(path, 'rb') as f:
    data = plistlib.load(f)

sources = data.setdefault('AppleEnabledInputSources', [])
exists = any(
    isinstance(item, dict)
    and item.get('Bundle ID') == entry['Bundle ID']
    and item.get('Input Mode') == entry['Input Mode']
    for item in sources
)

if exists:
    raise SystemExit(0)

backup = f"{path}.backup.{datetime.datetime.now().strftime('%Y%m%d-%H%M%S')}"
shutil.copy2(path, backup)
sources.append(entry)

with open(path, 'wb') as f:
    plistlib.dump(data, f, fmt=plistlib.FMT_BINARY)

print(f"Backed up HIToolbox plist to {backup}")
PY
  killall cfprefsd 2>/dev/null || true
  killall SystemUIServer 2>/dev/null || true
}

main() {
  ensure_macos
  ensure_squirrel
  repair_squirrel_bundle_signature
  backup_rime_dir
  install_rime_ice
  install_custom_files
  deploy_rime
  ensure_enabled_input_source

  info "Done. Default schema: rime_ice (雾凇拼音，全拼). Use F4 to switch schemas/options."
}

main "$@"
