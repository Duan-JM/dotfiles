# syntax=docker/dockerfile:1
#
# Minimal, ready-to-run dev image bundling this repo's tmux / vim (neovim) / zsh
# configuration. Intended for hopping onto remote machines to do temporary work:
#
#   docker run --rm -it code-cli
#
# The image reuses the repository's own per-tool install.sh scripts so it stays
# in sync with the dotfiles instead of duplicating package lists.

FROM ubuntu:24.04

# Run everything as root during build; the install scripts take an empty sudo
# prefix so they call apt / chsh directly.
ENV DEBIAN_FRONTEND=noninteractive \
    USER=root \
    HOME=/root \
    LANG=en_US.UTF-8 \
    LC_ALL=en_US.UTF-8 \
    TERM=xterm-256color

# Base packages the install scripts assume are already present (git/curl) plus
# locale support so zsh's LC_ALL=en_US.UTF-8 does not emit warnings.
RUN apt-get update -y \
    && apt-get install -y --no-install-recommends \
        ca-certificates curl git locales sudo python3 \
    && sed -i 's/^# *\(en_US.UTF-8 UTF-8\)/\1/' /etc/locale.gen \
    && locale-gen \
    && rm -rf /var/lib/apt/lists/*

# Bring the whole dotfiles repo in so the install scripts can find their
# sibling config files (tmux/, zsh/, vim/).
COPY . /opt/dotfiles
WORKDIR /opt/dotfiles

# Install the official neovim *stable* release. The distro / neovim PPA package
# on Ubuntu 24.04 is stuck at 0.9.5, but this config needs >= 0.10 (it uses
# vim.uv). Installing it here means vim/install.sh detects nvim and skips its
# own outdated apt install.
RUN set -eux; \
    arch="$(dpkg --print-architecture)"; \
    case "$arch" in \
        amd64) nvim_arch="x86_64" ;; \
        arm64) nvim_arch="arm64" ;; \
        *) echo "unsupported arch: $arch" >&2; exit 1 ;; \
    esac; \
    curl -fsSL -o /tmp/nvim.tar.gz \
        "https://github.com/neovim/neovim/releases/download/stable/nvim-linux-${nvim_arch}.tar.gz"; \
    tar -xzf /tmp/nvim.tar.gz -C /opt; \
    ln -sf "/opt/nvim-linux-${nvim_arch}/bin/nvim" /usr/local/bin/nvim; \
    rm -f /tmp/nvim.tar.gz; \
    nvim --version | head -1

# Run all three install scripts in a single layer. The tmux/zsh scripts assume
# an existing apt index (they do not run `apt-get update` themselves), so we
# refresh it up front and only prune the lists once at the very end.
#   - zsh:  installs zsh + oh-my-zsh + plugins, deploys ~/.zshrc
#   - tmux: installs tmux + tpm, deploys ~/.tmux.conf, pre-fetches plugins
#   - vim:  installs neovim + tooling, symlinks ~/.config/nvim
# Finally, install neovim plugins fully so the image is usable OFFLINE with no
# first-launch work: `Lazy! restore` installs every plugin pinned to the commit
# in the committed lazy-lock.json (deterministic, matches the repo), and the
# treesitter parsers for the primary languages are precompiled. Plugin .git
# dirs are intentionally kept so Lazy sees them as fully installed and never
# tries to re-clone/repair on startup.
RUN apt-get update -y \
    && ( cd zsh  && bash install.sh "" ) \
    && ( cd tmux && bash install.sh "" ) \
    && ( cd vim  && bash install.sh "" ) \
    && npm install -g tree-sitter-cli \
    && nvim --headless "+Lazy! restore" +qa \
    && nvim --headless \
        "+lua require('nvim-treesitter').install({'python','java','rust'}):wait(300000)" \
        +qa \
    && for lang in python java rust; do \
         find /root/.local/share/nvim -type f -name "${lang}.so" | grep -q . \
           || { echo "ERROR: treesitter parser for ${lang} was not built" >&2; exit 1; }; \
       done \
    && apt-get purge -y --auto-remove \
        autoconf autogen pkg-config libjansson-dev software-properties-common \
    && rm -rf /root/.oh-my-zsh/.git \
    && rm -rf /tmp/* /var/tmp/* \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /root
CMD ["/usr/bin/zsh"]
