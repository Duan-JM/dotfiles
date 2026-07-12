#!/usr/bin/env python3

import json
import subprocess
import sys
from pathlib import Path


def main() -> int:
    lockfile = Path(sys.argv[1])
    plugin_root = Path(sys.argv[2])
    locked_plugins = json.loads(lockfile.read_text())
    failures = []

    for name, metadata in sorted(locked_plugins.items()):
        plugin_dir = plugin_root / name
        if not plugin_dir.is_dir():
            failures.append(f"{name}: missing")
            continue

        expected_commit = metadata["commit"]
        marker = plugin_dir / ".code-cli-commit"
        payload_files = [
            path
            for path in plugin_dir.rglob("*")
            if path.is_file() and path != marker
        ]
        if not payload_files:
            failures.append(f"{name}: empty payload")
            continue

        if marker.is_file():
            actual_commit = marker.read_text().strip()
        else:
            result = subprocess.run(
                ["git", "-C", plugin_dir, "rev-parse", "HEAD"],
                check=False,
                capture_output=True,
                text=True,
            )
            if result.returncode != 0:
                failures.append(f"{name}: missing commit marker")
                continue
            actual_commit = result.stdout.strip()

        if actual_commit != expected_commit:
            failures.append(
                f"{name}: expected {expected_commit}, found {actual_commit}"
            )

    if failures:
        print("Neovim plugin verification failed:", file=sys.stderr)
        for failure in failures:
            print(f"  - {failure}", file=sys.stderr)
        return 1

    print(f"Verified {len(locked_plugins)} Neovim plugins")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
