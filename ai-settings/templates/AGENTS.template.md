# AGENTS.md

This file is the working guide for AI coding agents in this repository. Keep it
short and operational: durable architecture, feature guides, and API reference
belong in the project documentation. This file should point to those sources
and retain only the rules agents need before editing code.

Replace every `<PLACEHOLDER>` and remove sections that do not apply.

## Project Overview

<PROJECT_NAME> is <ONE_LINE_DESCRIPTION>.

It provides:

- <KEY_CAPABILITY_1>
- <KEY_CAPABILITY_2>
- <KEY_CAPABILITY_3>
- <KEY_CAPABILITY_4>

## Product Boundaries

<Describe the product's primary user and the workflow that new features should
support. Keep this section focused on durable product decisions, not current
roadmap items.>

Primary workflow:

```text
<INPUT> -> <DECISION_OR_TRANSFORMATION> -> <OUTPUT> -> <REVIEW>
```

New user-facing work should answer at least one of these questions:

- <PRIMARY_USER_QUESTION_1>
- <PRIMARY_USER_QUESTION_2>
- <PRIMARY_USER_QUESTION_3>

Non-goals:

- <NON_GOAL_1>
- <NON_GOAL_2>
- <NON_GOAL_3>

If a proposal falls outside these boundaries, keep it in internal tooling,
research support, or documentation unless the maintainer explicitly approves
the product-scope change.

## Architecture and Documentation Map

<DOCS_SYSTEM> documentation is the canonical home for architecture and feature
reference. Do not duplicate long explanations in this file.

| Topic | Canonical source |
| --- | --- |
| System architecture and data flow | `<ARCHITECTURE_DOC>` |
| Setup and local development | `<SETUP_DOC>` |
| Data contracts and persistence | `<DATA_DOC>` |
| Public API or CLI behavior | `<API_DOC>` |
| Feature workflows | `<FEATURE_GUIDE_DIR>` |
| Contribution and release process | `<CONTRIBUTING_DOC>` |

Agent-facing architecture reminders:

- Source code lives under `<SOURCE_ROOT>`.
- `<MODULE_1>` owns <RESPONSIBILITY_1>.
- `<MODULE_2>` owns <RESPONSIBILITY_2>.
- `<MODULE_3>` owns <RESPONSIBILITY_3>.
- <Describe the allowed dependency direction between layers or modules.>
- <State where business logic belongs and which surfaces should remain thin.>
- Import internal components from their responsibility-specific module. Keep
  package-root exports limited to intentionally stable public contracts.

## Documentation Audit Gate

Every change that touches code, architecture, setup, commands, public behavior,
or contributor workflow must audit related documentation before the final
response or PR. This applies to documentation-only changes too.

Review these surfaces and update the ones affected:

- `<CHANGELOG_SOURCE>`: add an entry or fragment for user-visible changes.
- `README.md`: update for user-facing setup, features, commands, architecture,
  or project positioning.
- `<CONTRIBUTING_DOC>`: update for branch flow, verification, commit and PR
  rules, changelog policy, or coding conventions.
- `AGENTS.md`: update for agent rules, architecture pointers, module layout,
  product boundaries, or workflow changes.
- `<DOCS_INDEX>`: update when top-level navigation or the project summary
  changes.
- `<FEATURE_GUIDE_DIR>`: update guides that describe changed behavior, APIs,
  architecture, installation, or workflows.
- `<API_DOC_DIR>`: confirm coverage when public symbols are added, renamed, or
  removed.

After documentation changes, run `<DOCS_CHECK_COMMAND>`.

## Core Engineering Rules

- Preserve <PROJECT_CRITICAL_INVARIANT_1>.
- Keep behavior consistent across <RELATED_EXECUTION_PATHS> by sharing domain
  primitives instead of copying scenario-specific logic.
- Use `<PRIMARY_PERSISTENCE_LAYER>` as the source of truth for
  <PERSISTED_DATA>.
- Use `<MIGRATION_TOOL>` for schema changes. Do not mutate production schemas
  through ad hoc startup logic.
- Handle missing, invalid, and partial data explicitly. Do not replace missing
  values with convenient defaults unless the default has a documented domain
  meaning.
- Keep business logic out of transport, UI, and persistence adapters.
- Delete superseded code and update imports, tests, and docs. Do not retain
  deprecated compatibility shims "for reference" unless a documented support
  window requires them.
- Surface errors through the project's established exception and logging
  patterns. Do not add broad catches, silent early returns, or success-shaped
  fallbacks.
- Secrets and environment-specific settings belong in environment variables or
  the approved secret store. Never commit credentials.

## Commands

Use the project's existing package manager and task runner. Do not install
parallel tooling for a task the repository already supports.

```bash
# Install dependencies
<INSTALL_COMMAND>

# Run the application or CLI
<RUN_COMMAND>

# Run a targeted test
<TARGETED_TEST_COMMAND>

# Run the main test suite
<TEST_COMMAND>

# Format
<FORMAT_COMMAND>

# Lint
<LINT_COMMAND>

# Type-check
<TYPECHECK_COMMAND>

# Build or validate docs
<DOCS_CHECK_COMMAND>
```

## Code Style

- Formatter: `<FORMATTER>` with <FORMATTER_POLICY>.
- Linter: `<LINTER>` with <LINTER_POLICY>.
- Type checker: `<TYPE_CHECKER>`.
- Follow <LANGUAGE_STYLE_GUIDE> and the repository's existing conventions.
- Add types to public interfaces and boundaries.
- Keep modules and classes single-purpose; prefer small composable units over
  inheritance-heavy designs.
- Use `<LOGGING_LIBRARY>` with structured context.
- Comment only non-obvious behavior, constraints, and tradeoffs.
- Reuse existing helpers and patterns before introducing new abstractions.

## Testing

- Tests mirror source structure under `<TEST_ROOT>`.
- Shared fixtures live in `<FIXTURE_LOCATIONS>`.
- Test markers or groups: `<TEST_GROUPS>`.
- Mock external network and provider calls using the project test pattern.
- Add regression coverage for every bug fix.
- Test public behavior and domain invariants, not implementation details.
- For time-dependent or stateful behavior, verify boundary conditions and
  guard against future-data leakage, ordering mistakes, and stale state where
  applicable.
- Run the smallest targeted test first, then the repository verification set
  required for the changed surface.

## Dependencies

- Use `<PACKAGE_MANAGER>` for dependency management. Do not edit generated lock
  files manually or use a second package manager.
- Runtime version: `<RUNTIME_VERSION>`.
- Core stack: <CORE_LIBRARIES_AND_PURPOSES>.
- Keep optional or heavyweight providers lazily loaded when possible, with a
  clear error and installation path when unavailable.
- Before adding a dependency, search for an existing project utility or
  standard-library solution.

## Versioning and Releases

<Describe the release model, stable branch, integration branch, and automation.
Remove this section if the repository has no release process.>

- Day-to-day branches target `<INTEGRATION_BRANCH>`.
- Release and hotfix branches target `<STABLE_BRANCH>`.
- `<CHANGELOG_FILE>` is generated or release-managed through
  `<CHANGELOG_TOOL>`. Do not edit generated release material during ordinary
  feature work.
- User-visible feature, fix, deprecation, removal, and security changes require
  <CHANGELOG_ENTRY_POLICY>.
- Internal-only refactors, tests, and docs may skip a changelog entry when the
  PR explains why.
- Do not bump versions unless the user explicitly requests a release or version
  change.

## Iteration Workflow for AI Agents

Every code or documentation change starts from a GitHub issue. Direct pushes to
protected branches are forbidden. Do not auto-merge.

1. Create or identify the issue before implementation.

   - Use one issue for a small, independently reviewable change.
   - Split large work into an epic with independently implementable,
     testable, and reviewable child issues.
   - Implement one claimed issue at a time. Do not create an implementation
     branch or PR for an epic that only tracks child work.

2. Confirm that the issue is open and available, then claim it using the
   authenticated GitHub account.

   ```bash
   set -euo pipefail
   issue=<ISSUE_NUMBER>
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
   ```

   Stop if the issue is assigned to another contributor. Recheck ownership
   before each commit, push, and PR creation when the repository requires
   exclusive issue ownership.

3. Keep the primary checkout clean. Create the issue branch from the latest
   remote integration branch in a dedicated worktree.

   ```bash
   git status --short --branch -uall
   git fetch origin --prune

   branch=<TYPE>/<ISSUE_NUMBER>-<SHORT_SLUG>
   repo_root=$(git rev-parse --show-toplevel)
   worktree_path="$repo_root/.worktree/<ISSUE_NUMBER>-<SHORT_SLUG>"
   mkdir -p "$repo_root/.worktree"
   git worktree add -b "$branch" "$worktree_path" \
     "origin/<INTEGRATION_BRANCH>"
   cd "$worktree_path"
   ```

   Inspect the primary checkout before creating the worktree. If tracked or
   untracked changes are present, do not stash, clean, reset, move, or overwrite
   them. Stop and ask the maintainer how to proceed. Reuse an existing worktree
   when resuming the same issue. Do not use `git worktree add --force`.

4. Implement only the claimed issue and verify locally.

   ```bash
   <LINT_COMMAND>
   <FORMAT_CHECK_COMMAND>
   <TYPECHECK_COMMAND>
   <TEST_COMMAND>
   <DOCS_CHECK_COMMAND>  # if docs changed
   ```

   Run targeted checks first. Escalate to broader verification only as required
   by repository policy or the changed behavior.

5. Apply the documentation audit gate before committing. If documentation
   changes, rerun the affected checks.

6. Commit using Conventional Commits:

   ```text
   <type>(<optional-scope>): <concise description>

   Co-authored-by: Copilot <223556219+Copilot@users.noreply.github.com>
   ```

7. Recheck issue ownership and base freshness, then push.

   ```bash
   git fetch origin <INTEGRATION_BRANCH>
   git merge-base --is-ancestor origin/<INTEGRATION_BRANCH> HEAD
   git push -u origin HEAD
   ```

   If the integration branch is not an ancestor of `HEAD`, stop and report the
   stale base. Do not automatically rebase or merge without maintainer
   approval.

8. Open a PR using the repository template.

   ```bash
   gh pr create \
     --base <INTEGRATION_BRANCH> \
     --title "<conventional-commit-style title>" \
     --body-file <PREPARED_PR_BODY>
   gh pr view --json baseRefName,headRefName,body,url
   ```

   The PR body must describe scope, issue linkage, documentation impact, and
   exact verification commands. Use the repository's required issue-closing
   syntax; do not close an epic from a child-issue PR.

9. Follow the repository CI policy.

   ```bash
   gh pr checks --watch --fail-fast
   ```

   Self-heal failures only within the configured attempt budget
   (`<MAX_CI_FIX_ATTEMPTS>`). Recheck issue ownership before each fix. If the
   budget is exhausted, stop and report the remaining failure instead of
   guessing.

10. Stop after verification and PR creation. Do not merge. Remove a worktree
    only after the PR is merged, the issue is closed, the worktree is clean,
    and the branch is contained in the integration branch. Never force-remove
    a worktree or force-delete its branch.

## Release Promotion Loop

<Remove this section if releases do not use integration-to-stable promotion.>

1. Open a release PR from `<INTEGRATION_BRANCH>` to `<STABLE_BRANCH>`.
2. Generate and edit release notes using `<CHANGELOG_TOOL>`.
3. Run the full local verification set and wait for release PR CI.
4. Merge only at a coherent release boundary.
5. Let the stable-branch automation create the version, tag, and release.

Urgent production fixes branch from `<STABLE_BRANCH>`, target the same branch,
and are then merged or cherry-picked back to `<INTEGRATION_BRANCH>` so the
branches do not drift.
