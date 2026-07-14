# syntax=docker/dockerfile:1

ARG ALPINE_IMAGE=alpine:edge@sha256:9a341ff2287c54b86425cbee0141114d811ae69d88a36019087be6d896cef241

FROM ${ALPINE_IMAGE} AS config-builder

ENV HOME=/root \
    XDG_CONFIG_HOME=/root/.config \
    CODE_CLI_BUILD=1 \
    CODE_CLI_IMAGE=1 \
    CODE_CLI_LAZY_CONCURRENCY=1

RUN apk_add_with_retry() { \
      for attempt in 1 2 3; do \
        if apk add --no-cache "$@"; then return 0; fi; \
        echo "apk add attempt ${attempt}/3 failed" >&2; \
      done; \
      return 1; \
    }; \
    apk_add_with_retry \
      build-base \
      ca-certificates \
      curl \
      git \
      neovim \
      nodejs \
      python3 \
      py3-pynvim \
      tree-sitter-cli

COPY vim/lazy-lock.json /opt/dotfiles/vim/lazy-lock.json
COPY docker_files/code-cli/install-nvim-plugins.py /usr/local/bin/install-nvim-plugins
COPY docker_files/code-cli/nvim-plugin-repositories.json /opt/code-cli/nvim-plugin-repositories.json
COPY docker_files/code-cli/verify-nvim-plugins.py /usr/local/bin/verify-nvim-plugins
COPY docker_files/code-cli/runtime-snapshot-lock.json /opt/code-cli/runtime-snapshot-lock.json
COPY docker_files/code-cli/runtime-snapshot-repositories.json /opt/code-cli/runtime-snapshot-repositories.json

RUN git config --global http.version HTTP/1.1 \
    && mkdir -p /root/.local/share/nvim/lazy \
    && python3 /usr/local/bin/install-nvim-plugins \
         /opt/dotfiles/vim/lazy-lock.json \
         /opt/code-cli/nvim-plugin-repositories.json \
         /root/.local/share/nvim/lazy \
    && python3 /usr/local/bin/verify-nvim-plugins \
         /opt/dotfiles/vim/lazy-lock.json /root/.local/share/nvim/lazy \
    && make -C /root/.local/share/nvim/lazy/telescope-fzf-native.nvim

COPY vim /opt/dotfiles/vim

RUN for lang in python go rust; do \
      mkdir -p /root/.config; \
      ln -sfn /opt/dotfiles/vim /root/.config/nvim; \
      parser_ready=0; \
      for attempt in 1 2 3; do \
        nvim --headless \
          "+lua require('nvim-treesitter').install({'${lang}'}):wait(300000)" \
          +qa || true; \
        if find /root/.local/share/nvim -type f -name "${lang}.so" | grep -q .; then \
          parser_ready=1; \
          break; \
        fi; \
        echo "Treesitter ${lang} attempt ${attempt}/3 failed" >&2; \
      done; \
      test "${parser_ready}" = 1; \
    done

RUN python3 /usr/local/bin/install-nvim-plugins \
      /opt/code-cli/runtime-snapshot-lock.json \
      /opt/code-cli/runtime-snapshot-repositories.json \
      /opt/code-cli/runtime-snapshots \
    && python3 /usr/local/bin/verify-nvim-plugins \
      /opt/code-cli/runtime-snapshot-lock.json \
      /opt/code-cli/runtime-snapshots \
    && mkdir -p /root/.oh-my-zsh/custom/plugins /root/.tmux/plugins \
    && cp -a /opt/code-cli/runtime-snapshots/ohmyzsh/. /root/.oh-my-zsh/ \
    && rm -rf /opt/code-cli/runtime-snapshots/ohmyzsh \
    && for plugin in zsh-syntax-highlighting zsh-autosuggestions; do \
         mv "/opt/code-cli/runtime-snapshots/${plugin}" \
           "/root/.oh-my-zsh/custom/plugins/${plugin}"; \
       done \
    && for plugin in tpm tmux-prefix-highlight tmux-cpu tmux-resurrect; do \
         mv "/opt/code-cli/runtime-snapshots/${plugin}" \
           "/root/.tmux/plugins/${plugin}"; \
       done \
    && rmdir /opt/code-cli/runtime-snapshots

FROM ${ALPINE_IMAGE}

ARG CODE_CLI_VARIANT=core
ARG TARGETARCH
ARG KAF_VERSION=0.2.14
ARG KAF_SHA256_AMD64=c2cc6e412d31f979242e3c7ca38f8474402c3722ef0ced22f842fe2a74818889
ARG KAF_SHA256_ARM64=8bcb6738652088f1b3d59ff4d244f5e5ce5ae0ae29c6e7caa6b255abd828d97d
ARG TRIPPY_VERSION=0.13.0
ARG TRIPPY_SHA256_AMD64=aa2b7b2a0773f3cc04da691100419049950b690fe3736d25e24ac955b63d6056
ARG TRIPPY_SHA256_ARM64=73af939aa94e9e0f07cac2b3c8177e02a6b1c3be88299d85988e02be81ae7004

ENV HOME=/root \
    LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    TERM=xterm-256color \
    CODE_CLI_IMAGE=1 \
    CODE_CLI_VARIANT=${CODE_CLI_VARIANT}

RUN set -eux; \
    apk_add_with_retry() { \
      for attempt in 1 2 3; do \
        if apk add --no-cache "$@"; then return 0; fi; \
        echo "apk add attempt ${attempt}/3 failed" >&2; \
      done; \
      return 1; \
    }; \
    case "${CODE_CLI_VARIANT}" in \
      core|python|rust|go|ops) ;; \
      *) echo "unsupported CODE_CLI_VARIANT: ${CODE_CLI_VARIANT}" >&2; exit 1 ;; \
    esac; \
    apk_add_with_retry \
      bash \
      ca-certificates \
      curl \
      fd \
      fzf \
      git \
      neovim \
      ripgrep \
      tmux \
      zsh; \
    case "${CODE_CLI_VARIANT}" in \
      python) apk_add_with_retry python3 py3-pip py3-pynvim ;; \
      rust) apk_add_with_retry cargo rust ;; \
      go) apk_add_with_retry go ;; \
      ops) \
        apk_add_with_retry \
          bind-tools \
          iproute2 \
          iputils \
          jq \
          kcat \
          mtr \
          nmap \
          nmap-ncat \
          openssh-client \
          openssl \
          pgcli \
          postgresql-client \
          py3-pip \
          redis \
          socat \
          xh \
          yq; \
        case "${TARGETARCH}" in \
          amd64) \
            kaf_arch=x86_64; \
            kaf_sha256="${KAF_SHA256_AMD64}"; \
            trippy_arch=x86_64; \
            trippy_sha256="${TRIPPY_SHA256_AMD64}" ;; \
          arm64) \
            kaf_arch=arm64; \
            kaf_sha256="${KAF_SHA256_ARM64}"; \
            trippy_arch=aarch64; \
            trippy_sha256="${TRIPPY_SHA256_ARM64}" ;; \
          *) echo "unsupported ops TARGETARCH: ${TARGETARCH}" >&2; exit 1 ;; \
        esac; \
        workdir="$(mktemp -d)"; \
        curl -fsSL --retry 3 --retry-all-errors \
          "https://github.com/birdayz/kaf/releases/download/v${KAF_VERSION}/kaf_${KAF_VERSION}_Linux_${kaf_arch}.tar.gz" \
          -o "${workdir}/kaf.tar.gz"; \
        echo "${kaf_sha256}  ${workdir}/kaf.tar.gz" | sha256sum -c -; \
        tar -xzf "${workdir}/kaf.tar.gz" -C "${workdir}" kaf; \
        install -m 0755 "${workdir}/kaf" /usr/local/bin/kaf; \
        curl -fsSL --retry 3 --retry-all-errors \
          "https://github.com/fujiapple852/trippy/releases/download/${TRIPPY_VERSION}/trippy-${TRIPPY_VERSION}-${trippy_arch}-unknown-linux-musl.tar.gz" \
          -o "${workdir}/trippy.tar.gz"; \
        echo "${trippy_sha256}  ${workdir}/trippy.tar.gz" | sha256sum -c -; \
        tar -xzf "${workdir}/trippy.tar.gz" -C "${workdir}"; \
        install -m 0755 \
          "${workdir}/trippy-${TRIPPY_VERSION}-${trippy_arch}-unknown-linux-musl/trip" \
          /usr/local/bin/trip; \
        printf '%s\n' \
          'iredis==1.16.0 --hash=sha256:8b51086e5cae9e3d136a74cd9b35c5b75491dcb333d2dae476078094df4cc5d2' \
          'click==8.4.2 --hash=sha256:e6f9f66136c816745b9d65817da91d61d957fb16e02e4dcd0552553c5a197b76' \
          'configobj==5.0.9 --hash=sha256:1ba10c5b6ee16229c79a05047aeda2b55eb4e80d7c7d8ecf17ec1ca600c79882' \
          'mistune==3.3.3 --hash=sha256:99de1585e42dcbd826faa9e11a202727a5e202e4e4722a4c69ac1ff615793dd7' \
          'packaging==24.2 --hash=sha256:09abb1bccd265c01f4a3aa3f7a7db064b36514d2cba19a2f694fe6150451a759' \
          'prompt_toolkit==3.0.52 --hash=sha256:9aac639a3bbd33284347de5ad8d68ecc044b91a762dc39b7c21095fcd6a19955' \
          'Pygments==2.20.0 --hash=sha256:81a9e26dd42fd28a23a2d169d86d7ac03b46e2f8b59ed4698fb4785f946d0176' \
          'python-dateutil==2.9.0.post0 --hash=sha256:a8b2bc7bffae282281c8140a97d3aa9c14da0b136dfe83f850eea9a5f7470427' \
          'redis==7.4.1 --hash=sha256:1fa4647af1c5e93a2c685aa248ee44cce092691146d41390518dabe9a99839b0' \
          'six==1.17.0 --hash=sha256:4721f391ed90541fddacab5acf947aa0d3dc7d27b2e1e8eda2be8970586c3274' \
          'wcwidth==0.8.2 --hash=sha256:d63947694a0539a1d51e01eda7caf800c291020e6cdd7e28ad7b14dd33ad4f85' \
          > "${workdir}/iredis-requirements.txt"; \
        pip3 install \
          --break-system-packages \
          --disable-pip-version-check \
          --no-cache-dir \
          --require-hashes \
          -r "${workdir}/iredis-requirements.txt"; \
        rm -rf "${workdir}" ;; \
    esac; \
    printf '%s\n' "${CODE_CLI_VARIANT}" > /etc/code-cli-variant; \
    printf '%s\n' "${TARGETARCH:-unknown}" > /etc/code-cli-arch

COPY vim /opt/dotfiles/vim
COPY zsh/zshrc /root/.zshrc
COPY zsh/.zsh-config /root/.zsh-config
COPY tmux/tmux.conf /root/.tmux.conf
COPY tmux/tmux /root/.tmux

COPY --from=config-builder /root/.local/share/nvim /root/.local/share/nvim
COPY --from=config-builder /root/.oh-my-zsh /root/.oh-my-zsh
COPY --from=config-builder /root/.tmux/plugins /root/.tmux/plugins

RUN mkdir -p /root/.config \
    && ln -s /opt/dotfiles/vim /root/.config/nvim \
    && sed -i 's/export LC_ALL=en_US.UTF-8/export LC_ALL=C.UTF-8/' /root/.zshrc \
    && nvim_output="$(nvim --headless \
         "+lua assert(require('lazy.core.config').plugins['nvim-treesitter'])" \
         +qa 2>&1)" \
    && printf '%s\n' "${nvim_output}" \
    && ! printf '%s\n' "${nvim_output}" | grep -Eq '(^|[[:space:]])E[0-9]{3,4}:'

WORKDIR /root
CMD ["/bin/zsh"]
