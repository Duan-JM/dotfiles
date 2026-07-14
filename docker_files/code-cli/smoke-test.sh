#!/usr/bin/env bash

set -euo pipefail

IMAGE="${1:-code-cli:latest}"
EXPECTED_VARIANT="${2:-core}"

case "${EXPECTED_VARIANT}" in
  core|python|rust|go|ops) ;;
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

    assert_ops_commands_absent() {
      for command in psql redis-cli kcat kaf pgcli iredis ncat socat mtr trip dig nslookup nmap jq yq xh; do
        ! command -v "${command}" >/dev/null
      done
    }

    case "${EXPECTED_VARIANT}" in
      core)
        for command in python3 rustc cargo go; do
          ! command -v "${command}" >/dev/null
        done
        assert_ops_commands_absent
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
        assert_ops_commands_absent
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
        assert_ops_commands_absent
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
        assert_ops_commands_absent
        ;;
      ops)
        for command in \
          psql redis-cli kcat kaf pgcli iredis ncat socat mtr trip dig \
          nslookup ip ss ping nmap jq yq ssh openssl xh; do
          command -v "${command}" >/dev/null
        done

        psql --version
        redis-cli --version
        kcat -V
        kaf --version
        pgcli --version
        iredis --version
        trip --version
        ncat --version
        mtr --version
        nmap --version
        jq --version
        yq --version
        ssh -V
        openssl version
        xh --version

        ! timeout 5 psql "postgresql://postgres@127.0.0.1:1/postgres?connect_timeout=1" \
          -c "select 1"
        ! timeout 5 redis-cli -u redis://127.0.0.1:1/0 PING
        ! timeout 5 iredis --url redis://127.0.0.1:1/0 PING
        ! timeout 5 kcat -b 127.0.0.1:1 -L -m 1

        listener_log="$(mktemp)"
        socat TCP-LISTEN:45678,bind=127.0.0.1,reuseaddr,fork \
          OPEN:"${listener_log}",creat,append &
        listener_pid=$!
        listener_ready=0
        for attempt in 1 2 3 4 5; do
          if ncat -z 127.0.0.1 45678; then
            listener_ready=1
            break
          fi
          sleep 0.1
        done
        test "${listener_ready}" = 1
        printf "ops-smoke\n" | ncat 127.0.0.1 45678
        kill "${listener_pid}"
        wait "${listener_pid}" || true
        grep -q "ops-smoke" "${listener_log}"
        rm -f "${listener_log}"

        dns_query="$(mktemp)"
        socat -u UDP4-RECVFROM:45679,bind=127.0.0.1,reuseaddr STDOUT >"${dns_query}" &
        dns_listener_pid=$!
        dns_query_sent=0
        for attempt in 1 2 3; do
          if ! dig @127.0.0.1 -p 45679 example.com +time=1 +tries=1 >/dev/null 2>&1 \
            && test -s "${dns_query}"; then
            dns_query_sent=1
            break
          fi
        done
        wait "${dns_listener_pid}"
        test "${dns_query_sent}" = 1
        rm -f "${dns_query}"

        nslookup -version
        mtr --report --report-cycles 1 127.0.0.1
        trip --mode silent --report-cycles 1 --protocol tcp \
          --target-port 45679 127.0.0.1

        for command in rustc cargo go; do
          ! command -v "${command}" >/dev/null
        done
        ;;
    esac
  '

docker image inspect "${IMAGE}" \
  --format 'image={{index .RepoTags 0}} content-size={{.Size}} bytes arch={{.Architecture}}'
docker image ls "${IMAGE}" --format 'local-size={{.Size}}'
