#!/usr/bin/env bash
#
# Build the Alpine-based code-cli image.
#
# Usage:
#   bash docker_files/code-cli/build.sh
#   VARIANT=python bash docker_files/code-cli/build.sh
#   PLATFORM=linux/amd64 VARIANT=rust bash docker_files/code-cli/build.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../.." && pwd -P)"

VARIANT="${VARIANT:-core}"
PLATFORM="${PLATFORM:-}"

case "${VARIANT}" in
  core|python|rust|go|ops) ;;
  *)
    echo "ERROR: unsupported VARIANT '${VARIANT}' (use core, python, rust, go, or ops)" >&2
    exit 1
    ;;
esac

if [[ -z "${IMAGE:-}" ]]; then
  if [[ "${VARIANT}" == "core" ]]; then
    IMAGE="code-cli:latest"
  else
    IMAGE="code-cli:${VARIANT}"
  fi
fi

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
echo "    variant:    ${VARIANT}"
echo "    context:    ${REPO_ROOT}"
echo "    dockerfile: ${SCRIPT_DIR}/Dockerfile"
echo "    platform:   ${PLATFORM:-<host>}"

docker build \
  ${PLATFORM_ARGS[@]+"${PLATFORM_ARGS[@]}"} \
  --load \
  -t "${IMAGE}" \
  -f "${SCRIPT_DIR}/Dockerfile" \
  "$@" \
  --build-arg "CODE_CLI_VARIANT=${VARIANT}" \
  "${REPO_ROOT}"

echo "==> Done. Run it with:"
echo "    docker run --rm -it ${IMAGE}"
