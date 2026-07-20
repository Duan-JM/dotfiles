---
applyTo: "**"
---

# Copilot CLI Local Git Development Workflow

This file is the canonical workflow for Copilot CLI automation in repositories
that cannot use GitHub or another remote forge. It assumes a local Git
repository with `dev` as the integration branch and `main` as the release
branch. Read `AGENTS.md` for project engineering rules and `CONTRIBUTING.md` for
the contributor-facing branch, changelog, integration, and release policy.

No step in this workflow depends on `gh`, a remote named `origin`, hosted issue
tracking, pull requests, or hosted CI.

## Authorization and branch boundaries

An implementation request authorizes Copilot CLI to perform the complete
day-to-day local `dev` workflow:

- create or claim the required local task record;
- create or resume its linked task branch and dedicated worktree;
- synchronize the task branch with the latest local `dev` under the safe
  rebase gates below;
- validate the repository's `pre-commit` configuration, install its declared
  Git hook types, and run its configured local gates when present;
- commit without any `Co-authored-by` trailer; and
- create or update a local review snapshot whose base branch is `dev`.

This authorization never permits a direct update to `dev` or `main`. It also
does not permit integrating a task branch, creating a review snapshot targeting
`main`, closing a task, creating a tag, exporting or publishing an artifact, or
deleting a branch, worktree, task record, or review record. Each operation
requires an explicit user request in the current turn. Release and hotfix work
must also follow the main-branch rules below.

Do not contact a Git remote unless the user explicitly requests it and the
repository policy permits it.

## Project-specific requirements

Before review, commit, local review creation, integration, or release work, read
the repository's project instructions and contributor guide. Apply the
documentation audit, targeted checks, final verification, changelog policy,
release policy, integration strategy, `pre-commit` command and offline cache
policy, and domain-specific review gates defined there.

If the repository defines its own local task store or review format, use it
instead of the default `.git/local-workflow/` layout below.

Do not copy project commands, paths, tools, test selectors, documentation
inventory, release implementation, or domain rules into this file.

## Branch and verification boundaries

Day-to-day branches and local review snapshots target `dev`. A review snapshot
targeting `main` requires an explicit current-turn user request and must follow
the repository's release or hotfix policy.

There is no hosted CI gate. When the repository contains a `pre-commit`
configuration, `pre-commit` is the mandatory first-line local gate. The
repository's documented test, build, and final verification set remains the
integration gate; hooks do not replace it.

A local review snapshot records a base and head for inspection. It is not an
approval and does not update its target branch.

## Pre-commit policy

Apply this section when the repository contains `.pre-commit-config.yaml` or
`.pre-commit-config.yml`.

- Use the repository's documented wrapper when it has one, such as
  `uv run pre-commit` or a Make target. The examples below use the bare
  `pre-commit` command.
- Validate the configuration before installing or running hooks. Validate
  `.pre-commit-hooks.yaml` or `.pre-commit-hooks.yml` too when the repository
  publishes its own hooks.
- Install the Git hook types declared by the repository. Projects that rely on
  stages beyond `pre-commit` should declare them in
  `default_install_hook_types` so `pre-commit install --install-hooks` remains
  deterministic.
- The environment is offline. Hook repositories, language runtimes, and
  `additional_dependencies` must resolve from local paths, approved mirrors, or
  an already populated local cache. If hook environment installation attempts
  network access or cannot resolve offline, stop.
- Do not run `pre-commit autoupdate`; it contacts hook remotes. Do not run
  `pre-commit clean` or `pre-commit gc` automatically because the local cache
  may be the only available copy of a hook environment.
- Do not use `git commit --no-verify`, `git rebase --no-verify`, `SKIP`,
  `PRE_COMMIT_ALLOW_NO_CONFIG`, or another bypass unless the user explicitly
  requests it in the current turn and the repository policy permits it.
- Treat hook rewrites as implementation changes. Inspect them, keep only
  in-scope changes, rerun affected tests, and rerun the same hook command until
  it passes. If a hook changes unrelated files, stop rather than silently
  expanding the task.
- Do not use `pre-commit install --overwrite`. If `core.hooksPath` or custom
  hooks require special integration, follow the repository's documented setup
  instead of replacing them.

## Review orchestration

The task-owning top-level agent is the only review coordinator. It may invoke
the `check` skill once after implementation, the documentation audit, and
targeted tests are complete.

- The coordinator performs the base review. Do not launch a generic
  `code-review` agent for the same role.
- Review agents are leaf workers. A `code-review`, `security-review`,
  `rubber-duck`, architecture, database, or causality reviewer must not invoke
  `check`, load another review skill, launch tasks or subagents, or run the full
  repository verification set.
- Deduplicate reviewers by review target and role.
- Quick reviews use only the coordinator's base review.
- Standard reviews use the base review plus at most two non-overlapping
  specialists.
- Deep reviews use the base review plus at most four non-overlapping
  specialists. Security and architecture are the default specialist ceiling;
  add database or causality only when the diff directly touches those risks.
- Rubber-duck is reserved for unresolved design uncertainty or repeated failed
  approaches and replaces the coordinator's adversarial pass.
- After fixes, rerun only reviewers that reported confirmed findings. Allow one
  targeted re-review round with at most two reviewers.
- Do not launch "final-final", "clean gate", or "no-findings gate" reviewers.
- The coordinator validates findings, applies fixes, and runs final repository
  verification once against the finished diff.
- If a leaf reviewer attempts to invoke `check` or another reviewer, stop that
  task and report an orchestration violation.

## Iteration workflow

### 1. Create the local task structure

A small, independently reviewable change uses one task. A large task uses one
epic with child task records; implementation branches and review snapshots
belong only to child tasks.

The default task store lives under the shared Git common directory so every
linked worktree sees the same records:

```bash
set -euo pipefail
task=123-short-kebab-slug
case "$task" in
  ''|*[!a-z0-9-]*|-*|*-) exit 1 ;;
esac

git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
workflow_root="$git_common_dir/local-workflow"
tasks_root="$workflow_root/tasks"
task_dir="$tasks_root/$task"

mkdir -p "$tasks_root"
mkdir "$task_dir"
printf '%s\n' "task" >"$task_dir/kind"
printf '%s\n' "open" >"$task_dir/state"
printf '%s\n' "<short task title>" >"$task_dir/title"
printf '%s\n' "None" >"$task_dir/depends-on"
```

Use `kind=epic` for an epic. A child task records its epic ID in `parent`.
`depends-on` contains one task ID per line, or exactly `None`. An epic may also
use `plan.md` to record scope, dependency batches, and progress. Do not create
an implementation branch or review snapshot for the epic itself.

Before creating child tasks, define their dependency graph:

- Give every child an explicit `depends-on` entry.
- Record which children can run in parallel and keep their files, behavior, and
  verification scopes independently reviewable.
- Prefer independent vertical slices that can be claimed and developed in
  parallel worktrees.
- Do not create artificial serial dependencies.
- A blocked child may exist for tracking, but implementation waits until every
  prerequisite task has been integrated into `dev`.
- Do not use stacked branches or stacked review snapshots to bypass a
  dependency.

Task IDs are repository-unique. If `mkdir "$task_dir"` reports that the record
already exists, inspect and reuse the existing task or choose a different ID.
Do not overwrite an existing record.

### 2. Claim the task

Use `GIT_LOCAL_OWNER` when the environment provides an explicit automation
identity. Otherwise use the repository's configured Git email. A task may be
claimed when it is open and its claim is absent or belongs to that identity.
Active implementation additionally requires exactly one linked branch and one
worktree. Zero linked branches is valid only during the initial claim before
the branch is created.

```bash
set -euo pipefail
task=123-short-kebab-slug
git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
task_dir="$git_common_dir/local-workflow/tasks/$task"
actor=${GIT_LOCAL_OWNER:-$(git config --get user.email)}
claimed_now=false

test -n "$actor"
test -f "$task_dir/state"
test "$(cat "$task_dir/state")" = "open"

if mkdir "$task_dir/claim" 2>/dev/null; then
  printf '%s\n' "$actor" >"$task_dir/claim/owner"
  claimed_now=true
elif test -f "$task_dir/claim/owner" &&
  test "$(cat "$task_dir/claim/owner")" = "$actor"; then
  :
else
  exit 1
fi

if ! test "$(cat "$task_dir/state")" = "open" ||
  ! test "$(cat "$task_dir/claim/owner")" = "$actor"; then
  if [ "$claimed_now" = true ]; then
    rm -f "$task_dir/claim/owner"
    rmdir "$task_dir/claim"
  fi
  exit 1
fi

git worktree list --porcelain
```

If the task is closed or claimed by another identity, stop. If the task record
or `git worktree list --porcelain` shows multiple branches, multiple worktrees,
or a branch or worktree linked to another task, stop. Recheck the exclusive
claim plus the single branch/worktree condition before every commit and local
review update. Other independent tasks owned by the same identity do not
conflict.

### 3. Create or resume the linked worktree

Keep the primary checkout as a clean coordination worktree. Develop in a
dedicated worktree under the repository root's locally ignored `.worktree/`
directory. Use this block only when creating a new linked branch:

```bash
set -euo pipefail
test -z "$(git status --porcelain=v1)"

task=123-short-kebab-slug
branch_type=docs
branch="$branch_type/$task"
git check-ref-format --branch "$branch" >/dev/null

repo_root=$(git rev-parse --show-toplevel)
git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
task_dir="$git_common_dir/local-workflow/tasks/$task"
worktree_root="$repo_root/.worktree"
worktree_path="$worktree_root/$task"
exclude_file="$git_common_dir/info/exclude"

test "$(cat "$task_dir/state")" = "open"
test ! -e "$task_dir/branch"
test ! -e "$task_dir/worktree"
git show-ref --verify --quiet refs/heads/dev

grep -qxF '/.worktree/' "$exclude_file" ||
  printf '%s\n' '/.worktree/' >>"$exclude_file"
mkdir -p "$worktree_root"
git worktree add -b "$branch" "$worktree_path" dev

printf '%s\n' "$branch" >"$task_dir/branch"
printf '%s\n' "$worktree_path" >"$task_dir/worktree"
cd "$worktree_path"
```

Before creating a worktree, inspect
`git status --short --branch -uall` in the primary checkout. Stop if tracked or
untracked changes exist; never stash, clean, reset, move, or overwrite them.

For resumed work, read `branch` and `worktree` from the task record and inspect
`git worktree list --porcelain`. If the linked branch already has that
worktree, reuse it. If the branch exists but its recorded worktree is no longer
registered, add it without recreating or resetting the branch:

```bash
branch=$(cat "$task_dir/branch")
worktree_path=$(cat "$task_dir/worktree")

if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add "$worktree_path" "$branch"
else
  exit 1
fi
```

If the branch is missing, the recorded path belongs to another worktree, or
multiple task records claim the same branch or path, stop. Never use
`git worktree add --force`.

After entering a new worktree, run the repository's documented bootstrap
command before any dependency, build, or verification command. If no bootstrap
command is documented, stop instead of inventing one.

Then initialize the configured `pre-commit` environment. This deliberately
installs hook environments early so an unavailable offline dependency blocks
the task before implementation begins:

```bash
pre_commit_config=
if test -f .pre-commit-config.yaml; then
  pre_commit_config=.pre-commit-config.yaml
elif test -f .pre-commit-config.yml; then
  pre_commit_config=.pre-commit-config.yml
fi

if test -n "$pre_commit_config"; then
  command -v pre-commit >/dev/null
  pre-commit validate-config "$pre_commit_config"

  if test -f .pre-commit-hooks.yaml; then
    pre-commit validate-manifest .pre-commit-hooks.yaml
  elif test -f .pre-commit-hooks.yml; then
    pre-commit validate-manifest .pre-commit-hooks.yml
  fi

  hooks_path=$(git config --get core.hooksPath || true)
  test -z "$hooks_path"
  pre-commit install --config "$pre_commit_config" --install-hooks
fi
```

If the repository documents a shared `PRE_COMMIT_HOME`, export it before these
commands so every worktree reuses the same offline cache. Do not invent or
relocate the cache when the project already defines one.

### 4. Implement and audit documentation

Run all edits, targeted tests, commits, rebases, and local review operations
from the task worktree. Implement only the claimed task and run the
project-specific targeted checks declared by the repository.

When `pre-commit` is configured, run it against every changed or untracked
in-scope file after each logical edit batch and before review:

```bash
if test -f .pre-commit-config.yaml; then
  pre_commit_config=.pre-commit-config.yaml
elif test -f .pre-commit-config.yml; then
  pre_commit_config=.pre-commit-config.yml
else
  exit 1
fi

changed_files=()
while IFS= read -r -d '' file; do
  changed_files+=("$file")
done < <(
  git diff --name-only --diff-filter=ACMR -z dev
  git ls-files --others --exclude-standard -z
)

if [ "${#changed_files[@]}" -gt 0 ]; then
  pre-commit run --config "$pre_commit_config" \
    --show-diff-on-failure \
    --files "${changed_files[@]}"
fi
```

Do not stage files only to make hooks see them. The explicit file list covers
committed branch changes, staged and unstaged changes, and untracked files.

Apply the documentation audit before review. If it changes documentation,
complete those edits and rerun the changed-file hooks before review.

### 5. Review

After implementation, targeted tests, and the documentation audit are complete,
run review according to the orchestration rules above. Validate every finding
against the current diff, apply confirmed fixes, and rerun only affected
targeted tests.

### 6. Run final repository verification

When `pre-commit` is configured, validate it again and run its complete default
stage across the repository:

```bash
if test -f .pre-commit-config.yaml; then
  pre_commit_config=.pre-commit-config.yaml
elif test -f .pre-commit-config.yml; then
  pre_commit_config=.pre-commit-config.yml
else
  exit 1
fi

pre-commit validate-config "$pre_commit_config"
pre-commit run --config "$pre_commit_config" \
  --show-diff-on-failure \
  --all-files
```

Run any repository-designated `manual` hooks at this point too. Do not run
arbitrary manual hooks whose purpose is not part of the documented verification
gate.

After all hooks pass without modifying files, run the complete verification set
declared by the repository once against the final reviewed diff. Do not
duplicate those commands here. If a hook or later edit changes the diff, rerun
affected targeted checks, the full `pre-commit` gate, and the repository's final
verification set. The commit step below runs the `pre-push` stage after the
final commits exist.

### 7. Commit

Use Conventional Commits and commit normally so installed `pre-commit`,
`prepare-commit-msg`, `commit-msg`, and post-commit stages run when configured.
Do not add a `Co-authored-by` trailer for Copilot or another AI tool.

If a commit hook fails or rewrites files, inspect the result, rerun affected
checks, and commit again only after the hook passes. Never bypass the hook.

Because this workflow has no push operation, emulate the configured `pre-push`
stage after the final commit. Supplying local base, head, branch, and repository
metadata preserves the stage's normal ref context without contacting a remote:

```bash
if test -f .pre-commit-config.yaml; then
  pre_commit_config=.pre-commit-config.yaml
elif test -f .pre-commit-config.yml; then
  pre_commit_config=.pre-commit-config.yml
else
  exit 1
fi

branch=$(git branch --show-current)
git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
pre-commit run --config "$pre_commit_config" \
  --show-diff-on-failure \
  --hook-stage pre-push \
  --from-ref dev \
  --to-ref HEAD \
  --local-branch "refs/heads/$branch" \
  --remote-branch refs/heads/dev \
  --remote-name local \
  --remote-url "$git_common_dir"
```

If the emulated `pre-push` stage fails or rewrites files, inspect the result,
rerun the earlier gates, commit the correction normally, and rerun this stage
against the new head.

### 8. Synchronize with local `dev`

Copilot CLI may safely rebase the task branch onto the latest local `dev`
without another confirmation. Direct updates to `dev` or `main` remain
forbidden.

```bash
branch=$(git branch --show-current)
git merge-base --is-ancestor dev HEAD
```

If `dev` is not an ancestor of `HEAD`, rebase automatically only when:

- the task worktree is clean;
- the task remains open and exclusively claimed by the current identity;
- the current branch and worktree exactly match the task record;
- any existing `refs/local-review/dev/<task>` ref matches its recorded head and
  is an ancestor of the current branch, so no submitted commit is lost; and
- no `reviewed-head` record shows that human review covers commits the rebase
  would rewrite.

Record the old head and merge base:

```bash
old_head=$(git rev-parse HEAD)
old_base=$(git merge-base HEAD dev)
git rebase dev
```

If Git reports a conflict, immediately run `git rebase --abort` and stop. Do not
resolve the conflict or merge `dev` automatically.

After a successful rebase, inspect:

```bash
git range-diff "$old_base..$old_head" "dev..HEAD"
```

Rerun affected targeted checks, the changed-file hooks, the complete
`pre-commit` gate, and final verification. If a local review snapshot already
exists, update it to the new head and reset its decision to `pending`. Never
silently carry an approval or reviewed head across rewritten commits.

### 9. Create the local `dev` review snapshot

Copilot CLI may create or update a local review snapshot whose base is `dev`
without another confirmation. Use the repository's local review template when
one exists. Otherwise prepare `body.md` with the task ID, summary, verification
results, documentation impact, and known risks.

The review head is stored as `refs/local-review/dev/<task>`. Supporting metadata
lives under `.git/local-workflow/reviews/dev/<task>/`.

```bash
set -euo pipefail
task=123-short-kebab-slug
git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
workflow_root="$git_common_dir/local-workflow"
task_dir="$workflow_root/tasks/$task"
review_dir="$workflow_root/reviews/dev/$task"
review_ref="refs/local-review/dev/$task"
branch=$(cat "$task_dir/branch")

test "$(git branch --show-current)" = "$branch"
test -z "$(git status --porcelain=v1)"
git merge-base --is-ancestor dev HEAD

base=$(git rev-parse dev)
head=$(git rev-parse HEAD)
previous_head=
if test -f "$review_dir/head"; then
  previous_head=$(cat "$review_dir/head")
fi

mkdir -p "$review_dir"
printf '%s\n' "$base" >"$review_dir/base"
printf '%s\n' "$head" >"$review_dir/head"
printf '%s\n' "$branch" >"$review_dir/branch"
if [ "$previous_head" != "$head" ] || ! test -f "$review_dir/state"; then
  printf '%s\n' "pending" >"$review_dir/state"
  rm -f "$review_dir/reviewed-head"
fi

pre_commit_config=
if test -f .pre-commit-config.yaml; then
  pre_commit_config=.pre-commit-config.yaml
elif test -f .pre-commit-config.yml; then
  pre_commit_config=.pre-commit-config.yml
fi

if test -n "$pre_commit_config"; then
  printf '%s\n' "configured" >"$review_dir/pre-commit-state"
  printf '%s\n' "$head" >"$review_dir/pre-commit-head"
  printf '%s\n' "$(pre-commit --version)" \
    >"$review_dir/pre-commit-version"
  printf '%s\n' "$pre_commit_config" >"$review_dir/pre-commit-config"
  git hash-object "$pre_commit_config" \
    >"$review_dir/pre-commit-config-hash"
else
  printf '%s\n' "not-configured" >"$review_dir/pre-commit-state"
  rm -f "$review_dir/pre-commit-head" \
    "$review_dir/pre-commit-version" \
    "$review_dir/pre-commit-config" \
    "$review_dir/pre-commit-config-hash"
fi

git update-ref "$review_ref" "$head"

git show-ref --verify "$review_ref"
git log --oneline "dev..$review_ref"
git diff --stat "dev...$review_ref"
```

Do not create or update the review snapshot unless the configured `pre-commit`
gate passed against the recorded head. The recorded version, configuration
path, and configuration hash make that result auditable during local
integration.

Do not overwrite `body.md` or human review notes when only the head changes.
Keep the task open until its reviewed head is integrated into `dev`, then leave
task closure to the user. A child review must never close its epic.

There is no hosted CI after this point. Day-to-day work stops after local
verification and creation or update of the `dev` review snapshot.

### 10. Stop without integrating or cleaning up

Do not auto-integrate the review head into `dev`. Do not close the task or
remove its review ref, review record, worktree, or branch. Cleanup requires a
separate explicit user request and is allowed only after the reviewed head is
integrated into `dev`, the task is closed, the worktree is clean, and the
branch is contained in `dev`. Never force-remove a worktree or force-delete its
branch.

## Local integration, main release, and hotfix workflow

Do not update `dev` or `main`, integrate a review head, close a task, delete a
review ref, create a tag, export a release, or publish an artifact without an
explicit current-turn user request.

When explicitly authorized to integrate a reviewed task into `dev`:

1. confirm the task is still exclusively claimed and its worktree is clean;
2. confirm the review ref, recorded review head, and task branch head are
   identical;
3. confirm the recorded review base is the current `dev`; if `dev` advanced,
   synchronize the task branch, rerun affected verification, and update the
   review snapshot before integration;
4. confirm the review's `pre-commit` evidence matches its head and current
   configuration;
5. from the task worktree, emulate the configured `pre-push` stage against
   `dev...HEAD` again and run the `pre-merge-commit` stage when the repository
   declares it, because a fast-forward integration may not invoke that Git
   hook;
6. run any repository-defined integration gate from a clean primary checkout;
7. use the repository's documented integration strategy, or
   `git merge --ff-only refs/local-review/dev/<task>` when no strategy is
   documented; and
8. record the integrated head in the task record without closing the task or
   cleaning up unless those actions were also explicitly requested.

An authorized fast-forward integration from a clean primary checkout may use:

```bash
set -euo pipefail
task=123-short-kebab-slug
git_common_dir=$(git rev-parse --path-format=absolute --git-common-dir)
workflow_root="$git_common_dir/local-workflow"
task_dir="$workflow_root/tasks/$task"
review_dir="$workflow_root/reviews/dev/$task"
review_ref="refs/local-review/dev/$task"
branch=$(cat "$task_dir/branch")

test "$(git branch --show-current)" = "dev"
test -z "$(git status --porcelain=v1)"
test "$(git rev-parse "$review_ref")" = "$(cat "$review_dir/head")"
test "$(git rev-parse "$branch")" = "$(cat "$review_dir/head")"
test "$(git rev-parse dev)" = "$(cat "$review_dir/base")"
if test "$(cat "$review_dir/pre-commit-state")" = "configured"; then
  test "$(cat "$review_dir/pre-commit-head")" = \
    "$(cat "$review_dir/head")"
  test "$(pre-commit --version)" = \
    "$(cat "$review_dir/pre-commit-version")"
  pre_commit_config=$(cat "$review_dir/pre-commit-config")
  test "$(git show "$review_ref:$pre_commit_config" |
    git hash-object --stdin)" = \
    "$(cat "$review_dir/pre-commit-config-hash")"
fi

git merge --ff-only "$review_ref"
printf '%s\n' "$(git rev-parse dev)" >"$task_dir/integrated-head"
```

When explicitly authorized, a release promotion:

1. creates or updates a local review snapshot from `dev` to `main`;
2. follows the repository's documented changelog and release preparation;
3. runs the complete configured `pre-commit` gate and the repository's release
   verification set locally;
4. leaves `main` unchanged for human review; and
5. performs no integration, tag, export, or publish action beyond the explicit
   user request.

An explicitly authorized urgent hotfix starts from `main`, creates a local
review snapshot targeting `main`, and follows the repository's documented
backport policy.
