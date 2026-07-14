# code-cli image

`code-cli` is an Alpine Edge-based terminal environment with this repository's
zsh, tmux, and Neovim configuration. The default image stays minimal; language
toolchains are provided as separate variants.

## Variants

| Variant | Additional tools | Default tag |
| --- | --- | --- |
| `core` | None | `code-cli:latest` |
| `python` | Python, pip, pynvim | `code-cli:python` |
| `rust` | Rust and Cargo | `code-cli:rust` |
| `go` | Go | `code-cli:go` |
| `ops` | Database clients and network diagnostics | `code-cli:ops` |

Every variant includes zsh, tmux, Neovim, bash, git, curl, ripgrep, fd, fzf,
the configured shell/tmux plugins, Neovim plugins, and precompiled
Python/Go/Rust Treesitter parsers.

The variants are intentionally independent rather than cumulative. Use the
smallest image that matches the project being maintained.

## Build

```bash
# minimal default image: code-cli:latest
bash docker_files/code-cli/build.sh

# language-specific images
VARIANT=python bash docker_files/code-cli/build.sh
VARIANT=rust bash docker_files/code-cli/build.sh
VARIANT=go bash docker_files/code-cli/build.sh
VARIANT=ops bash docker_files/code-cli/build.sh

# custom tag and platform
PLATFORM=linux/amd64 VARIANT=rust IMAGE=my/code-cli:rust \
  bash docker_files/code-cli/build.sh

# pass extra flags through to docker build
bash docker_files/code-cli/build.sh --no-cache
```

The build uses multiple stages. Compilers and parser build dependencies stay
in the builder stage; runtime images receive only configuration, installed
plugins, compiled parsers, and the packages selected by the variant.

Alpine Edge is used because the pinned Neovim plugins require Neovim 0.12,
while current stable Alpine releases package Neovim 0.11. The build installs
plugins sequentially at the exact commits in `lazy-lock.json`, verifies every
snapshot, and compiles native plugin components before producing the runtime
image.

The Alpine Edge image index and all zsh/tmux plugin snapshots are pinned to
immutable digests or commit SHAs. APK package versions still follow the Edge
repository, so package-level rebuild reproducibility is limited by Alpine's
rolling repository.

## Target platform

```bash
PLATFORM=linux/amd64 bash docker_files/code-cli/build.sh
PLATFORM=linux/arm64 bash docker_files/code-cli/build.sh
```

Cross-platform builds require Docker Buildx/QEMU. Each single-platform build is
loaded into the local Docker image store with `--load`.

## Run

```bash
docker run --rm -it code-cli
docker run --rm -it code-cli:python
docker run --rm -it code-cli:rust
docker run --rm -it code-cli:go
docker run --rm -it code-cli:ops
```

Mount a working directory when needed:

```bash
docker run --rm -it -v "$PWD":/work -w /work code-cli:python
```

## Verify

Smoke tests run with networking disabled and compile a minimal program for the
selected language variant:

```bash
bash docker_files/code-cli/smoke-test.sh code-cli:latest core
bash docker_files/code-cli/smoke-test.sh code-cli:python python
bash docker_files/code-cli/smoke-test.sh code-cli:rust rust
bash docker_files/code-cli/smoke-test.sh code-cli:go go
bash docker_files/code-cli/smoke-test.sh code-cli:ops ops
```

The `ops` variant adds PostgreSQL, Redis, and Kafka clients plus common DNS,
TCP/UDP, routing, TLS, SSH, JSON, and YAML troubleshooting tools. `kaf` and
`trippy` are downloaded from pinned upstream releases with architecture-specific
SHA-256 checksums. IRedis and its Python dependencies are version- and
hash-pinned in the `ops` build step.

Packet capture and live bandwidth tools are not included in the first version
because they add substantial image size and generally require `NET_RAW` or
`NET_ADMIN` capabilities.

## Size and compatibility trade-offs

Measured locally on `linux/arm64` on 2026-07-14:

| Variant | `docker image ls` size | Docker content size |
| --- | ---: | ---: |
| `core` | ~165 MB | ~165 MB |
| `ops` | ~367 MB | ~367 MB |

The `ops` variant is about 202 MB larger than the current `core` image on
`linux/arm64`. The verified `linux/amd64` image is about 358 MB. The largest
direct tool payloads are `kaf` (~19 MB), `nmap` (~13 MB), `yq` (~13 MB), and
`trippy` (~8.6 MB); package dependency sharing means these direct installed
sizes are not individually additive.

Earlier local measurements for the language variants were ~321 MB for
`python`, ~735 MB for `go`, and ~1.02 GB for `rust`; Alpine Edge updates can
change those values between rebuilds.

Language variants are larger than `core` only by the packages required for
that language. Rust remains the largest because Alpine's Rust package pulls
compiler and LLVM runtime dependencies.

The image uses musl libc and `C.UTF-8`. Native binaries built for glibc may
need to be rebuilt inside the image or replaced with musl-compatible releases.
