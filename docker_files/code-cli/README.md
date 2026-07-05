# code-cli image

A minimal, ready-to-run container image that bundles this repo's **tmux**,
**vim (neovim)** and **zsh** configuration. Handy when you SSH into a remote
box for temporary work and want your usual editor/multiplexer/shell without
polluting the host.

The image reuses the repository's own per-tool `install.sh` scripts, so it
stays in sync with the dotfiles instead of duplicating package lists.

## Build

```bash
# from anywhere in the repo
bash docker_files/code-cli/build.sh

# custom tag
IMAGE=my/code-cli:dev bash docker_files/code-cli/build.sh

# pass extra flags through to `docker build`
bash docker_files/code-cli/build.sh --no-cache
```

### Target platform

By default the image is built for the host platform. Use `PLATFORM` to pick a
specific architecture (requires docker buildx / qemu for cross builds):

```bash
# x86_64 image (typical Linux servers)
PLATFORM=linux/amd64 bash docker_files/code-cli/build.sh

# arm64 image (Apple Silicon / macOS)
PLATFORM=linux/arm64 bash docker_files/code-cli/build.sh
```

The Dockerfile auto-selects the matching neovim release binary for the target
architecture.

The build context is the repo root (the script handles this), so the
Dockerfile can reach `tmux/`, `zsh/` and `vim/`.

## Run

```bash
# throwaway shell
docker run --rm -it code-cli

# mount your current project into the container
docker run --rm -it -v "$PWD":/work -w /work code-cli
```

The default command is `zsh`. `tmux` and `nvim` are on `PATH` with configs and
plugins pre-installed.

### Offline / out-of-the-box

The image is built to be usable **without network access** on first launch:

- All neovim plugins are installed at build time via `Lazy! restore`, pinned to
  the commits in the committed `vim/lazy-lock.json`. Opening `nvim` offline shows
  nothing pending in `:Lazy` — no install/update/clone happens on startup.
- treesitter parsers for **python / java / rust** are precompiled into the image,
  so syntax highlighting for those languages works offline immediately.

Note: opening a file whose treesitter parser was not precompiled (e.g. yaml,
json) simply falls back to basic syntax highlighting offline; run
`:TSInstall <lang>` once you have network to add it. Language servers (pyright,
jdtls, rust-analyzer, …) are **not** bundled — install them when needed.

## Notes

- Based on `ubuntu:24.04`, runs as `root` with `HOME=/root`.
- Neovim is installed from the official **stable** release (the Ubuntu/PPA
  package is too old for this config, which requires `vim.uv` / neovim >= 0.10).
- Includes the neovim toolchain the config expects (Node.js, Python, ripgrep,
  fd, pynvim) plus a C/C++ compiler so treesitter can build additional parsers
  on demand, so the image is a full dev environment rather than a bare shell.
  This is why the image is ~1.3 GB; the shell/tmux/nvim core is only ~300 MB,
  the rest is the neovim IDE stack (Node.js ~190 MB, compiler toolchain, plugins
  and precompiled parsers).
