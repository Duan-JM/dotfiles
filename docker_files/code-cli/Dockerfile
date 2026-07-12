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
      core|python|rust|go) ;; \
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
