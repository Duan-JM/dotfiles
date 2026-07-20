---
applyTo: "**"
---

# Copilot CLI GitHub Development Workflow

This file is the canonical workflow for Copilot CLI automation in this
repository. Read `AGENTS.md` for project engineering rules and
`CONTRIBUTING.md` for the contributor-facing branch, pull request, changelog,
and release policy.

## Authorization and branch boundaries

An implementation request authorizes Copilot CLI to perform the complete
day-to-day `dev` workflow:

- create or claim the required issue;
- create or resume its linked issue branch and dedicated worktree;
- synchronize the issue branch with the latest `origin/dev` under the safe
  rebase gates below;
- commit without any `Co-authored-by` trailer;
- push the issue branch, including `--force-with-lease` after an authorized safe
  rebase; and
- create or update a pull request whose base branch is `dev`.

This authorization never permits a direct push to `dev` or `main`. It also does
not permit a branch or pull request targeting `main`, merging a pull request,
creating a tag or release, publishing an artifact, closing an issue, or deleting
a branch or worktree. Each of those operations requires an explicit user
request in the current turn. Release and hotfix work must also follow the
main-branch rules below.

## Project-specific requirements

Before review, commit, push, or pull request creation, read the repository's
project instructions and contributor guide. Apply the documentation audit,
targeted checks, final verification, changelog policy, release policy, and
domain-specific review gates defined there.

Do not copy project commands, paths, tools, test selectors, documentation
inventory, release implementation, or domain rules into this file.

## Branch and CI boundaries

Day-to-day branches and pull requests target `dev`. A pull request targeting
`main` requires an explicit current-turn user request and must follow the
repository's release or hotfix policy.

The CI workflow runs only for pull requests targeting `dev` or `main`. Branch
pushes do not run CI.

## Review orchestration

The issue-owning top-level agent is the only review coordinator. It may invoke
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

### 1. Create the issue structure

A small, independently reviewable change uses one issue. A large task uses one
epic with native GitHub sub-issues; implementation branches and pull requests
belong only to child issues.

Before creating child issues, define their dependency graph:

- Give every child an explicit `Depends on` entry. Use `None` when it is
  independent.
- Record which children can run in parallel and keep their files, behavior, and
  verification scopes independently reviewable.
- Prefer independent vertical slices that can be claimed and developed in
  parallel worktrees.
- Do not create artificial serial dependencies.
- A blocked child may exist for tracking, but implementation waits until every
  prerequisite pull request is merged into `dev`.
- Do not use stacked pull requests to bypass a dependency.

Create new children with `gh issue create --parent <epic>` or attach existing
issues with `gh issue edit <epic> --add-sub-issue <issue>`. The epic tracks
scope, dependencies, parallel batches, and progress. Do not create an
implementation branch or pull request for the epic itself.

### 2. Claim the issue

Use the authenticated GitHub account returned by `gh api user` as the ownership
identity. An issue may be claimed when it is open and assigned exclusively to
that account. Active implementation additionally requires exactly one linked
branch and one worktree. Zero linked branches is valid only during the initial
claim before the branch is created.

```bash
set -euo pipefail
issue=123
actor=$(gh api user --jq .login)
claimed_now=false

test "$(gh issue view "$issue" --json state --jq .state)" = "OPEN"

assignment=$(
  gh issue view "$issue" --json assignees \
    --jq ".assignees | if length == 0 then \"unassigned\"
      elif ([.[].login] == [\"$actor\"]) then \"self\"
      else \"other\" end"
)
case "$assignment" in
  unassigned)
    gh issue edit "$issue" --add-assignee "$actor"
    claimed_now=true
    ;;
  self) ;;
  other) exit 1 ;;
esac

if ! gh issue view "$issue" --json state,assignees \
  --jq ".state == \"OPEN\" and ([.assignees[].login] == [\"$actor\"])" |
  grep -qx true; then
  if [ "$claimed_now" = true ]; then
    gh issue edit "$issue" --remove-assignee "$actor"
  fi
  exit 1
fi

gh issue develop --list "$issue"
```

If the issue is closed or assigned to anyone else, stop. If the branch listing
shows multiple branches or an unexpected pull request, stop. Recheck exclusive
assignment plus the single branch/worktree condition before every commit, push,
and pull request creation. Other independent issues owned by the same account
do not conflict.

### 3. Create or resume the linked worktree

Keep the primary checkout as a clean coordination worktree. Develop in a
dedicated worktree under the repository root's ignored `.worktree/` directory.
Use this block only when creating a new linked branch:

```bash
test -z "$(git status --porcelain=v1)"
issue=123
branch_type=docs
branch_slug=short-kebab-slug
branch="$branch_type/$issue-$branch_slug"
repo_root=$(git rev-parse --show-toplevel)
worktree_root="$repo_root/.worktree"
worktree_path="$worktree_root/$issue-$branch_slug"

git fetch origin --prune
gh issue develop "$issue" \
  --name "$branch" \
  --base dev
gh issue develop --list "$issue"

mkdir -p "$worktree_root"
git fetch origin "$branch"
git worktree add --track -b "$branch" "$worktree_path" "origin/$branch"
cd "$worktree_path"
```

Before creating a worktree, inspect
`git status --short --branch -uall` in the primary checkout. Stop if tracked or
untracked changes exist; never stash, clean, reset, move, or overwrite them.

For resumed work, inspect `gh issue develop --list <issue>` and
`git worktree list --porcelain`. If the linked branch already has one worktree,
reuse it. If the branch exists but has no worktree, add one without recreating
or resetting the branch:

```bash
if git show-ref --verify --quiet "refs/heads/$branch"; then
  git worktree add "$worktree_path" "$branch"
else
  git fetch origin "$branch"
  git worktree add --track -b "$branch" "$worktree_path" "origin/$branch"
fi
```

If multiple linked branches, worktrees, or an unexpected pull request exist,
stop. Never use `git worktree add --force`.

After entering a new worktree, run the repository's documented bootstrap
command before any dependency, build, or verification command. If no bootstrap
command is documented, stop instead of inventing one.

### 4. Implement and audit documentation

Run all edits, targeted tests, commits, pushes, and pull request operations from
the issue worktree. Implement only the claimed issue and run the project-specific
targeted checks declared by the repository.

Apply the documentation audit before review. If it changes documentation,
complete those edits before review.

### 5. Review

After implementation, targeted tests, and the documentation audit are complete,
run review according to the orchestration rules above. Validate every finding
against the current diff, apply confirmed fixes, and rerun only affected
targeted tests.

### 6. Run final repository verification

Run the complete verification set declared by the repository once against the
final reviewed diff. Do not duplicate those commands here. If a later edit
changes the diff, rerun affected targeted checks and the repository's final
verification set.

### 7. Commit

Use Conventional Commits. Do not add a `Co-authored-by` trailer for Copilot or
another AI tool.

### 8. Synchronize with `dev` and push the issue branch

Copilot CLI may fetch `origin/dev`, safely rebase the issue branch, and push the
issue branch without another confirmation. Direct pushes to `dev` or `main`
remain forbidden.

```bash
branch=$(git branch --show-current)
git fetch origin dev "$branch"
git merge-base --is-ancestor origin/dev HEAD &&
  git push -u origin HEAD
```

If `origin/dev` is not an ancestor of `HEAD`, rebase automatically only when:

- the issue worktree is clean;
- the issue remains exclusively assigned to the authenticated account and has
  exactly one linked branch and worktree;
- `origin/$branch` is an ancestor of `HEAD`, so no unexpected remote commit
  would be overwritten; and
- no submitted human review covers commits the rebase would rewrite.

Record the old head and merge base:

```bash
old_head=$(git rev-parse HEAD)
old_base=$(git merge-base HEAD origin/dev)
git rebase origin/dev
```

If Git reports a conflict, immediately run `git rebase --abort` and stop. Do not
resolve the conflict or merge `origin/dev` automatically.

After a successful rebase, inspect:

```bash
git range-diff "$old_base..$old_head" "origin/dev..HEAD"
```

Rerun affected targeted checks and final verification. Use a normal push when
it is fast-forward. If the safe rebase rewrote published commits, use only
`git push --force-with-lease -u origin HEAD`; never use `--force`.

### 9. Create the `dev` pull request

Copilot CLI may create or update a pull request whose base is `dev` without
another confirmation. Use `.github/PULL_REQUEST_TEMPLATE.md` and a prepared
body.

```bash
gh pr create \
  --base dev \
  --title "<conventional-commit-style title>" \
  --body-file "<prepared-pr-body>"
gh pr view --json baseRefName,headRefName,body,url
```

Use `Refs #<issue>` for a `dev` pull request. Keep the issue open until the pull
request is merged, then leave issue closure to the user. A child pull request
must never close its epic.

CI starts only after a pull request targets `dev` or `main`. Day-to-day work
stops after local verification and creation of the `dev` pull request.

### 10. Stop without merging or cleaning up

Do not auto-merge. Do not close the issue or remove its worktree or branch.
Cleanup requires a separate explicit user request and is allowed only after the
pull request is merged, the issue is closed, the worktree is clean, and the
branch is contained in `origin/dev`. Never force-remove a worktree or
force-delete its branch.

## Main release and hotfix workflow

Do not create or update a pull request targeting `main`, push a release or
hotfix branch, merge, tag, release, or publish without an explicit current-turn
user request.

When explicitly authorized, a release promotion:

1. opens a release pull request from `dev` to `main`;
2. follows the repository's documented changelog and release preparation;
3. runs the repository's release verification set and waits for pull request
   CI;
4. remains unmerged for human review; and
5. performs no tag, release, or publish action beyond the explicit user request.

An explicitly authorized urgent hotfix starts from `main`, targets `main`, and
follows the repository's documented backport policy.
