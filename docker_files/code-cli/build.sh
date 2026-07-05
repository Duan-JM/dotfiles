#!/usr/bin/env bash
#
# Build the minimal "code-cli" dev image that bundles this repo's
# tmux / vim / zsh configuration.
#
# Usage:
#   bash docker_files/code-cli/build.sh              # build image "code-cli:latest"
#   IMAGE=my/code-cli:dev bash docker_files/code-cli/build.sh
#   bash docker_files/code-cli/build.sh --no-cache   # extra args go to docker build
#
# Config (environment variables):
#   IMAGE     target image tag                 (default: code-cli:latest)
#   PLATFORM  target platform for the image    (default: host platform)
#               - linux/amd64  -> x86_64 (typical Linux servers)
#               - linux/arm64  -> arm64  (Apple Silicon / macOS)
#
#   # build an x86_64 image (e.g. to ship to a Linux server):
#   PLATFORM=linux/amd64 bash docker_files/code-cli/build.sh
#   # build an arm64 image (e.g. to run natively on Apple Silicon macOS):
#   PLATFORM=linux/arm64 bash docker_files/code-cli/build.sh
#
# After building, jump into a throwaway container:
#   docker run --rm -it code-cli

set -euo pipefail

# Resolve the repo root regardless of where the script is invoked from; the
# build context must be the repo root so the install scripts can see tmux/,
# zsh/ and vim/.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

IMAGE="${IMAGE:-code-cli:latest}"
PLATFORM="${PLATFORM:-}"

# Only pass --platform when explicitly requested; otherwise docker builds for
# the host platform. Cross-platform builds rely on buildx/qemu emulation.
PLATFORM_ARGS=()
if [[ -n "${PLATFORM}" ]]; then
  case "${PLATFORM}" in
    linux/amd64|linux/arm64) ;;
    *)
      echo "ERROR: unsupported PLATFORM '${PLATFORM}' (use linux/amd64 or linux/arm64)" >&2
      exit 1
      ;;
  esac
  PLATFORM_ARGS=(--platform "${PLATFORM}")
fi

echo "==> Building ${IMAGE}"
echo "    context:    ${REPO_ROOT}"
echo "    dockerfile: ${SCRIPT_DIR}/Dockerfile"
echo "    platform:   ${PLATFORM:-<host>}"

docker build \
  ${PLATFORM_ARGS[@]+"${PLATFORM_ARGS[@]}"} \
  -t "${IMAGE}" \
  -f "${SCRIPT_DIR}/Dockerfile" \
  "$@" \
  "${REPO_ROOT}"

echo "==> Done. Run it with:"
echo "    docker run --rm -it ${IMAGE}"
