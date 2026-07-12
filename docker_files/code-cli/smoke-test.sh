#!/usr/bin/env bash

set -euo pipefail

IMAGE="${1:-code-cli:latest}"
EXPECTED_VARIANT="${2:-core}"

case "${EXPECTED_VARIANT}" in
  core|python|rust|go) ;;
  *)
    echo "ERROR: unsupported expected variant '${EXPECTED_VARIANT}'" >&2
    exit 1
    ;;
esac

docker run --rm -t --network none \
  -e "EXPECTED_VARIANT=${EXPECTED_VARIANT}" \
  "${IMAGE}" \
  /bin/sh -euc '
    test "$(cat /etc/code-cli-variant)" = "${EXPECTED_VARIANT}"
    test -r /root/.zshrc
    test -r /root/.tmux.conf
    test -r /root/.config/nvim/init.lua
    test -d /root/.oh-my-zsh
    for plugin in tpm tmux-prefix-highlight tmux-cpu tmux-resurrect; do
      test -d "/root/.tmux/plugins/${plugin}"
    done

    for command in zsh tmux nvim git rg fd fzf; do
      command -v "${command}" >/dev/null
    done
    for command in node npm; do
      ! command -v "${command}" >/dev/null
    done

    nvim_output="$(nvim --headless \
      "+lua assert(vim.fn.stdpath(\"config\") == \"/root/.config/nvim\"); assert(require(\"lazy.core.config\").plugins[\"nvim-treesitter\"]); require(\"lazy\").load({ plugins = { \"telescope.nvim\" } }); local telescope = require(\"telescope\"); telescope.load_extension(\"fzf\"); assert(telescope.extensions.fzf)" \
      +qa 2>&1)"
    printf "%s\n" "${nvim_output}"
    ! printf "%s\n" "${nvim_output}" | grep -Eq "(^|[[:space:]])E[0-9]{3,4}:"
    expected_plugins="$(grep -c "\"commit\":" /root/.config/nvim/lazy-lock.json)"
    installed_plugins="$(find /root/.local/share/nvim/lazy \
      -mindepth 2 -maxdepth 2 -name .code-cli-commit | wc -l | tr -d " ")"
    test "${installed_plugins}" = "${expected_plugins}"
    zsh -lic "test \"\${LC_ALL}\" = C.UTF-8"

    case "${EXPECTED_VARIANT}" in
      core)
        for command in python3 rustc cargo go; do
          ! command -v "${command}" >/dev/null
        done
        ;;
      python)
        command -v python3 >/dev/null
        command -v pip3 >/dev/null
        workdir="$(mktemp -d)"
        printf "value: int = 1\\n" > "${workdir}/smoke.py"
        python3 -m py_compile "${workdir}/smoke.py"
        rm -rf "${workdir}"
        for command in rustc cargo go; do
          ! command -v "${command}" >/dev/null
        done
        ;;
      rust)
        command -v rustc >/dev/null
        command -v cargo >/dev/null
        workdir="$(mktemp -d)"
        printf "fn main() {}\\n" > "${workdir}/main.rs"
        rustc "${workdir}/main.rs" -o "${workdir}/rust-smoke"
        "${workdir}/rust-smoke"
        rm -rf "${workdir}"
        for command in python3 go; do
          ! command -v "${command}" >/dev/null
        done
        ;;
      go)
        command -v go >/dev/null
        workdir="$(mktemp -d)"
        printf "package main\\nfunc main() {}\\n" > "${workdir}/main.go"
        go build -o "${workdir}/go-smoke" "${workdir}/main.go"
        "${workdir}/go-smoke"
        rm -rf "${workdir}"
        for command in python3 rustc cargo; do
          ! command -v "${command}" >/dev/null
        done
        ;;
    esac
  '

docker image inspect "${IMAGE}" \
  --format 'image={{index .RepoTags 0}} content-size={{.Size}} bytes arch={{.Architecture}}'
docker image ls "${IMAGE}" --format 'local-size={{.Size}}'
