# code-cli image

`code-cli` is an Alpine Edge-based, ready-to-run terminal development image. It
bundles this repository's zsh, tmux, and Neovim configuration and offers a
small core image plus a full language-toolchain image.

## Variants

| Variant | Included tools | Default tag |
| --- | --- | --- |
| `full` | zsh, tmux, Neovim, Python, Node.js, Rust, Cargo, and Go | `code-cli:latest` |
| `core` | zsh, tmux, Neovim, Python, and Node.js | `code-cli:core` |

Both variants include git, curl, ripgrep, fd, fzf, npm, the configured shell
and tmux plugins, Neovim plugins, and precompiled Python/Go/Rust Treesitter
parsers. The `core` variant leaves out the large Rust and Go toolchains when
only a portable shell/editor environment is needed.

## Build

```bash
# full image
bash docker_files/code-cli/build.sh

# smaller image without Rust and Go toolchains
VARIANT=core bash docker_files/code-cli/build.sh

# custom tag
IMAGE=my/code-cli:dev bash docker_files/code-cli/build.sh

# pass extra flags through to docker build
bash docker_files/code-cli/build.sh --no-cache
```

The build uses multiple stages. Compilers and parser build dependencies stay
in the builder stage; the runtime stage receives only the installed plugins,
compiled parsers, configuration, and requested CLI packages.

Alpine Edge is used because the pinned Neovim plugins require Neovim 0.12,
while the current stable Alpine releases still package Neovim 0.11. The build
installs plugins sequentially at the exact commits in `lazy-lock.json`, verifies
every extracted snapshot, and only then compiles native plugin components.
Commit tarballs avoid unreliable parallel Git transports and omit `.git`
metadata from the runtime image. Update plugins by rebuilding the image after
changing `lazy-lock.json`.

The Alpine Edge image index and all zsh/tmux plugin snapshots are pinned to
immutable digests or commit SHAs. APK package versions still follow the Edge
repository, so package-level rebuild reproducibility is limited by Alpine's
rolling repository.

## Target platform

The Dockerfile uses Alpine packages available for both supported platforms:

```bash
PLATFORM=linux/amd64 bash docker_files/code-cli/build.sh
PLATFORM=linux/arm64 bash docker_files/code-cli/build.sh
```

Cross-platform builds require Docker Buildx/QEMU. A single-platform build is
loaded into the local Docker image store with `--load`.

## Run

```bash
docker run --rm -it code-cli
docker run --rm -it -v "$PWD":/work -w /work code-cli
```

The default command is zsh. `tmux` and `nvim` are available on `PATH` with
their configuration and plugins pre-installed.

## Verify

```bash
bash docker_files/code-cli/smoke-test.sh code-cli:latest full
bash docker_files/code-cli/smoke-test.sh code-cli:core core
```

The smoke test checks the expected commands, configuration paths, Neovim
startup, locale, image variant, and image size.

## Size and compatibility trade-offs

Measured locally on `linux/arm64` (package versions and sizes will change over
time):

| Image | `docker image ls` size | Docker content size |
| --- | ---: | ---: |
| Previous Ubuntu image | ~1.31 GB | ~313 MB |
| Alpine `core` | ~422 MB | ~91 MB |
| Alpine `full` | ~1.45 GB | ~358 MB |

The core image is about 68% smaller than the previous local image. Alpine uses
musl libc and substantially smaller system packages, while the multi-stage
build removes parser compilers from the runtime image.

The full image cannot be as small as the core image because the packaged Rust
and Go SDKs are intentionally retained. On Alpine Edge, Rust pulls in GCC and
LLVM runtime components; Rust and Go together account for most of the full
image. Use `core` for temporary remote work and `full` when the language
toolchains must work without installing anything at container startup.

The image uses `C.UTF-8` rather than `en_US.UTF-8`, which is the portable UTF-8
locale provided by Alpine/musl.
