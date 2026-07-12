#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

IMAGE="${1:-code-cli:latest}"
EXPECTED_VARIANT="${2:-full}"

case "${EXPECTED_VARIANT}" in
  core|full) ;;
  *)
    echo "ERROR: unsupported expected variant '${EXPECTED_VARIANT}'" >&2
    exit 1
    ;;
esac

docker run --rm -t --network none \
  -e "EXPECTED_VARIANT=${EXPECTED_VARIANT}" \
  -v "${SCRIPT_DIR}/verify-nvim-plugins.py:/tmp/verify-nvim-plugins.py:ro" \
  -v "${REPO_ROOT}/vim/lazy-lock.json:/tmp/lazy-lock.json:ro" \
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

    for command in zsh tmux nvim python3 node npm git rg fd fzf; do
      command -v "${command}" >/dev/null
    done

    nvim_output="$(nvim --headless \
      "+lua assert(vim.fn.stdpath(\"config\") == \"/root/.config/nvim\"); assert(require(\"lazy.core.config\").plugins[\"nvim-treesitter\"])" \
      +qa 2>&1)"
    printf "%s\n" "${nvim_output}"
    ! printf "%s\n" "${nvim_output}" | grep -Eq "(^|[[:space:]])E[0-9]{3,4}:"
    python3 /tmp/verify-nvim-plugins.py \
      /tmp/lazy-lock.json /root/.local/share/nvim/lazy
    python3 -c "print(\"python-ok\")"
    zsh -lic "test \"\${LC_ALL}\" = C.UTF-8"

    if [ "${EXPECTED_VARIANT}" = full ]; then
      for command in rustc cargo go; do
        command -v "${command}" >/dev/null
      done
      workdir="$(mktemp -d)"
      printf "fn main() {}\\n" > "${workdir}/main.rs"
      rustc "${workdir}/main.rs" -o "${workdir}/rust-smoke"
      "${workdir}/rust-smoke"
      printf "package main\\nfunc main() {}\\n" > "${workdir}/main.go"
      go build -o "${workdir}/go-smoke" "${workdir}/main.go"
      "${workdir}/go-smoke"
      rm -rf "${workdir}"
    else
      for command in rustc cargo go; do
        ! command -v "${command}" >/dev/null
      done
    fi
  '

docker image inspect "${IMAGE}" \
  --format 'image={{index .RepoTags 0}} content-size={{.Size}} bytes arch={{.Architecture}}'
docker image ls "${IMAGE}" --format 'local-size={{.Size}}'
