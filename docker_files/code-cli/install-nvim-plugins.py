#!/usr/bin/env python3

import json
import shutil
import subprocess
import sys
from pathlib import Path


def install_plugin(name: str, repository: str, commit: str, root: Path) -> None:
    destination = root / name
    url = f"https://codeload.github.com/{repository}/tar.gz/{commit}"
    archive = Path("/tmp") / f"{name}.tar.gz"

    for attempt in range(1, 4):
        shutil.rmtree(destination, ignore_errors=True)
        destination.mkdir(parents=True)
        try:
            subprocess.run(
                [
                    "curl",
                    "--fail",
                    "--location",
                    "--retry",
                    "5",
                    "--retry-all-errors",
                    "--connect-timeout",
                    "15",
                    "--output",
                    archive,
                    url,
                ],
                check=True,
            )
            subprocess.run(
                [
                    "tar",
                    "-xzf",
                    archive,
                    "--strip-components=1",
                    "-C",
                    destination,
                ],
                check=True,
            )
            (destination / ".code-cli-commit").write_text(f"{commit}\n")
            print(f"Installed {name} at {commit}")
            return
        except subprocess.CalledProcessError:
            print(
                f"Plugin fetch attempt {attempt}/3 failed: {repository}@{commit}",
                file=sys.stderr,
            )
        finally:
            archive.unlink(missing_ok=True)

    raise RuntimeError(f"Could not install {repository}@{commit}")


def main() -> int:
    lockfile = Path(sys.argv[1])
    repositories_file = Path(sys.argv[2])
    plugin_root = Path(sys.argv[3])

    locked_plugins = json.loads(lockfile.read_text())
    repositories = json.loads(repositories_file.read_text())

    missing_repositories = sorted(set(locked_plugins) - set(repositories))
    extra_repositories = sorted(set(repositories) - set(locked_plugins))
    if missing_repositories or extra_repositories:
        print(
            "Plugin repository manifest does not match lazy-lock.json",
            file=sys.stderr,
        )
        if missing_repositories:
            print(f"Missing: {', '.join(missing_repositories)}", file=sys.stderr)
        if extra_repositories:
            print(f"Extra: {', '.join(extra_repositories)}", file=sys.stderr)
        return 1

    plugin_root.mkdir(parents=True, exist_ok=True)
    for name, metadata in sorted(locked_plugins.items()):
        install_plugin(name, repositories[name], metadata["commit"], plugin_root)

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
