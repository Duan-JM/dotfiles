# AGENTS.md

This file provides guidance to AI coding agents when working with code in this repository.

## Project Overview

<PROJECT_NAME> is a <ONE_LINE_DESCRIPTION>. It provides:

- <KEY_CAPABILITY_1>
- <KEY_CAPABILITY_2>
- <KEY_CAPABILITY_3>
- <KEY_CAPABILITY_4>

## Commands

```bash
# Install dependencies
poetry install

# Run the application / CLI
poetry run <ENTRY_POINT> <SUBCOMMAND>

# Run all tests with coverage
poetry run pytest

# Run a single test file
poetry run pytest tests/<module>/test_<name>.py

# Run tests by marker
poetry run pytest -m unit
poetry run pytest -m "not integration"
poetry run pytest -m "not slow"

# Format code
poetry run black src/ tests/ --line-length 120

# Lint
poetry run ruff check src/ tests/

# Type-check
poetry run mypy src/<package_name>

# Build docs (if applicable)
make -C docs strict
```

## Architecture

### Source layout: `src/<package_name>/`

**Entry point**: `<entry_file>.py` — <Describe CLI / app entry, e.g. Click group, FastAPI factory, etc.>

**Main modules:**

1. **`<module_1>/`** — <Responsibility>
   - `<file>.py` — <Class/function and its role>
   - `<file>.py` — <...>

2. **`<module_2>/`** — <Responsibility>
   - `<file>.py` — <...>

3. **`<module_3>/`** — <Responsibility>
   - `<file>.py` — <...>

**Top-level modules:**

- `<utility>.py` — <Description, e.g. logging setup, shared helpers>

### Key patterns

- **Configuration**: All secrets and environment settings via `.env` file. Loaded with `python-dotenv`. Config object lists all expected env vars (e.g. `<ENV_VAR_1>`, `<ENV_VAR_2>`).
- **Data storage**: <Describe DBs / storage backends used, e.g. PostgreSQL via SQLAlchemy ORM, Redis, S3, etc.>
- **Service architecture**: <Describe layering, e.g. Routes → Services → Workers; or CLI → Handlers → Repositories.>
- **Background / async work**: <Describe task queue, scheduler, thread pool, etc. if applicable.>
- **Logging**: `structlog.get_logger()` throughout. Use named keyword arguments for structured context. Auto-switches between console (TTY) and JSON (container) rendering. Log level via `LOG_LEVEL` env var.
- **Error handling**: Custom exception hierarchy under `<module>/exceptions.py`. Wrap external calls with try-except and log with structured context.
- **No legacy code**: Deprecated or replaced code MUST be deleted, not left behind "for reference". When a module is superseded, remove the old files entirely and update all imports, tests, and documentation. Dead code increases maintenance burden and confuses contributors.

### Infrastructure

- **Docker Compose** (`docker-compose.yml`): <List app + dependent services>
- **Dockerfiles** in `dockerfiles/` directory
- **Scripts** (`scripts/`): <List notable migration / integration / dev scripts>

## Code Style

- **Formatter**: Black, 120 char line length
- **Linter**: Ruff (and Pylint)
- **Type-checker**: mypy
- Always use classes instead of standalone functions
- Google Python Style Guide for docstrings
- 4-space indentation, PEP 8 compliance
- Type hints required on all public functions/methods
- Descriptive names; comments for non-obvious logic only

## Testing

- Tests mirror source structure under `tests/`
- Shared fixtures in `tests/conftest.py` and `tests/fixtures/`
- Markers: `unit`, `integration`, `slow`
- Coverage gate: `--cov-fail-under=<N>` (aspirational target 80%)
- External APIs / network calls MUST be mocked
- `pythonpath` is set to `src` in pytest config — imports use `from <package_name>.xxx import ...`

## Dependencies

- **Poetry** for all dependency management — never use pip directly
- Python `>=3.10,<4`
- <Pin notable libraries with their constraints>
- <List other key dependencies with one-line purpose>

## Iteration Workflow (MANDATORY for AI agents)

Every code change — feature, fix, refactor, docs, even one-line typos —
must go through this loop. **Direct pushes to `main` are forbidden**,
no exceptions. The loop ensures CI is the single source of truth for
"is this change safe to merge".

### The 7-step loop

1. **Branch from latest `main`**

   ```bash
   git checkout main && git pull --ff-only origin main
   git checkout -b <type>/<slug>
   ```

   `<type>` ∈ {`feat`, `fix`, `docs`, `refactor`, `test`, `chore`} —
   matcheks Conventional Commits.
   `<slug>` is 2–5 word kebab-case (e.g. `fix/login-redirect-loop`,
   `feat/csv-export`).

2. **Implement and verify locally** before pushing:

   ```bash
   poetry run ruff check src/ tests/
   poetry run black --check src/ tests/
   poetry run mypy src/<package_name>
   poetry run pytest -m "not slow and not integration"
   make -C docs strict        # only if docs/ changed
   ```

3. **Commit** with Conventional Commits format. Every commit message
   must include the trailer:

   ```
   Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
   ```

4. **Push the branch and open a PR**:

   ```bash
   git push -u origin HEAD
   gh pr create --fill --base main
   ```

   The PR body must include a `## Verification` section listing
   exactly what was run locally (the commands from step 2 plus their
   outcomes).

5. **Watch CI and self-heal until green**:

   ```bash
   gh run watch --exit-status        # blocks until the run finishes
   # if it fails:
   gh run view <run-id> --log-failed # diagnose
   # push fix commits to the same branch, repeat
   ```

   **Hard limit: 3 fix attempts.** If CI is still red after the third
   push, stop. Summarize what was tried and surface the failure to the
   human — do NOT keep guessing. Suspected-flaky failures count toward
   this budget; if you believe a failure is flaky, say so explicitly
   in the PR and stop.

6. **After CI is green, audit documentation and update if needed.**
   Walk the doc surfaces below and decide for each whether the change
   requires an update. If it does, make the change and re-run steps
   2–5 for the doc commit (it must also pass CI before merging).

   Doc surfaces and when to update each:
   - `CHANGELOG.md` — **always update for any user-visible change**
     (new behaviour, perf, API addition, fix, security). Add an entry
     under `## [Unreleased]` using Keep a Changelog categories
     (Added / Changed / Deprecated / Removed / Fixed / Security).
   - `docs/guides/*.md` — update when behaviour, APIs, or architecture
     described in a guide changed (architecture, backtesting,
     data_contracts, factor_mining, quickstart, installation).
   - `docs/api/*.md` — Sphinx `automodule` regenerates from docstrings;
     no manual edit needed unless a public symbol was added / renamed /
     removed, in which case confirm the `automodule` directive covers it.
   - `docs/factors/` — when factor inventory or derivation changed.
   - `README.md` — when user-facing setup, features, commands, or
     architecture overview changed.
   - `AGENTS.md` — when architecture, module layout, key patterns,
     infrastructure, or this workflow itself changed.

   Rule of thumb: an internal refactor or perf change with unchanged
   public contract usually needs only a `CHANGELOG.md` entry;
   architectural shifts usually need `AGENTS.md` + `README.md` too.

   If any docs change, run `make -C docs strict` locally before pushing
   and confirm CI's docs job stays green on the new commit.

7. **Stop after the PR is green. Do NOT auto-merge.** Report the PR URL
   and the final green CI run ID. Merging is the human's call.

### Why no direct pushes to `main`

Changes that "look clean locally" can still fail on CI's cold
environment. The PR + CI loop catches those before they land on `main`,
and gives reviewers a single artifact (the PR diff) to inspect rather
than a moving `main`.
