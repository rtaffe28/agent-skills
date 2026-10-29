---
name: pr-babysit
description: Use when asked to monitor, watch, or babysit a pull request, get a PR green, fix failing CI or checks, or resolve merge conflicts with main. Watches the PR's checks and mergeability, diagnoses and fixes failing phave-ng CI jobs, merges main to resolve conflicts, pushes the fixes, and repeats until the PR is green and mergeable.
---

# Babysit a PR until it's green and mergeable

Invoking this skill authorizes **normal pushes to the PR's own branch**. It does not authorize force-pushing, merging the PR, or touching someone else's PR. Ask for each of those.

## 1. Find the PR and a place to work

```sh
gh pr view <number|url|branch> --json number,url,headRefName,baseRefName,author,isDraft,mergeable,mergeStateStatus,reviewDecision
```

- No argument: use the PR for the current branch (`gh pr view`).
- The author isn't the user: confirm before pushing anything to it.
- Work in a checkout of the head branch: its stack worktree if it has one (`stack list`), otherwise a stack made with `stack-up` (`--branch <headRefName>`). Make sure it's clean and up to date: `git status`, `git pull --ff-only`.

## 2. Check state

```sh
gh pr checks <n>                       # each check and its state
gh pr view <n> --json mergeable,mergeStateStatus
```

Handle things in this order:

1. **`mergeable: CONFLICTING`** (`mergeStateStatus: DIRTY`): resolve conflicts first (step 4). CI results on a conflicting PR are stale anyway.
2. **Failing checks:** fix them (step 3).
3. **Pending checks:** wait (step 5).
4. **All green and mergeable:** report (step 6).

## 3. Fix failing CI

### Diagnose

```sh
gh pr checks <n> --json name,state,link,workflow
gh run view <run-id> --log-failed     # run id is in the check's link
```

Read the actual error, not just the job name. Then classify it:

| Kind | Signs | Do |
|---|---|---|
| **Caused by the PR** | Error points at code or tests the PR touches | Fix it (below) |
| **Flaky / infra** | Network or registry errors, runner lost, timeout with no code signal, passes on retry | `gh run rerun <run-id> --failed` **once**. If it fails again, treat it as real. |
| **Already broken on main** | Same job fails on main's latest run: `gh run list --branch main --workflow CI -L 3` | Don't fix it in this PR. Report it. |

### Reproduce and fix

Run the failing job's command locally in the worktree, fix the root cause, and re-run until it passes. phave-ng's `CI` workflow:

| Job | Local command |
|---|---|
| `typecheck` | `pnpm typecheck` (a ratchet against `.tsc-error-baseline`) |
| `lint` | `pnpm lint`, `./scripts/census-ratchet.sh`, `pnpm vitest run --project=unit tests/unit/db/migration-files-frozen.test.ts`, `pnpm flags:overdue` |
| `unit` | `pnpm build:card-runtime && pnpm exec vitest run --project=unit`, `pnpm test:packages:changed:unit` |
| `unit-db` | `pnpm exec vitest run --project=unit-db`, `pnpm test:db:changed` (needs the stack's DB: `eval "$(stack env)"`) |
| `api` / `dom` | `pnpm exec vitest run --project=api` / `--project=dom` |
| `build` | `pnpm build` |
| `tracking-script-dist` | `pnpm build:tracking-script`, then commit the regenerated `packages/tracking-script/dist` |
| `page-origin-build` | `pnpm build:page-origin` |
| `migration-ordering` | `node scripts/ci/migration-ordering.mjs --before-baseline` |

If the job list in `.github/workflows/ci.yml` has changed, trust the workflow file over this table. Run a single failing test file rather than the whole project while iterating.

**Never make CI green by cheating:**

- Don't skip, `.only`, delete, or loosen a failing test or assertion.
- Don't raise a ratchet baseline (`.tsc-error-baseline`, the census) to absorb new errors. Fix the errors instead.
- Don't edit a migration that's already on main (`migration-files-frozen`). Add a new migration instead.
- Don't add `@ts-ignore` / `eslint-disable` to silence a real problem.

If the only fix is one of those, stop and ask.

### Commit and push

Commit per `commit-pr-workflow` (e.g. `fix(ci): <what was wrong>`), then run `git push` (never `--force`). Go to step 5.

## 4. Resolve conflicts with main

Default to **merging** main into the branch. It doesn't rewrite history or need a force-push, and reviewers' comments stay attached:

```sh
git fetch origin
git merge origin/<baseRefName>
git diff --name-only --diff-filter=U      # conflicted files
```

Only rebase if the user asks for it. That requires `git push --force-with-lease`, so confirm first.

### Resolve each file by intent, not by side

For each conflict, find out what each side was trying to do before editing:

```sh
git log --oneline origin/<base> -5 -- <file>     # what main changed and why
git diff origin/<base>...HEAD -- <file>          # what the PR changed
```

Keep both intents. Never resolve a whole file with `--ours` or `--theirs` unless one side's change is truly obsolete, and say so in the report if you did.

### Special files

| File | Resolve by |
|---|---|
| `pnpm-lock.yaml` | `git checkout --theirs pnpm-lock.yaml` (main's), then `pnpm install` to re-add the PR's dependencies. If CI's `--frozen-lockfile` still fails on Linux, run `pnpm lockfile:linux`. |
| New migrations on both sides (`packages/db/migrations/{master,tenant,queue}/`) | Keep main's files untouched. Rename the **PR's** migration so it sorts after main's latest, then run the `migration-ordering` check. |
| Generated output (`packages/tracking-script/dist`, files from `pnpm generate:*`) | Take either side, then re-run the generator. Never hand-merge generated files. |
| `.tsc-error-baseline` | Take main's version, then run `pnpm typecheck` and follow what the ratchet says. |

### Verify, commit, and push

Run `pnpm typecheck`, `pnpm lint`, and the test projects that cover the conflicted files. If any conflict touched behavior, restart the stack (`stack restart`) and check the affected page.

```sh
git add <files>
git commit --no-edit          # keeps the merge commit message
git push
```

## 5. Watch

After each push, wait for the new run instead of polling:

```sh
gh pr checks <n> --watch --fail-fast     # run in the background; you'll be notified when it exits
```

When it exits, go back to step 2. For a long-running watch the user wants kept up over time (new pushes from teammates, main moving), suggest `/loop`.

### Stop and report, instead of looping, when:

- The same check has failed after **3** fix attempts.
- The failure is already broken on main, or is infra that a rerun didn't fix.
- A conflict needs a product or design decision (both sides changed the same behavior differently).
- A reviewer requested changes (`reviewDecision: CHANGES_REQUESTED`). Summarize their comments; don't address them unless asked.

## 6. Report

When everything is green and mergeable, or you've stopped:

- PR link and its final state: checks passing/failing, mergeable or not, review status.
- Each fix pushed: commit, which check it fixed, and the root cause in one line.
- Conflicts resolved: which files, and how each was decided.
- Anything left for the user, and why you stopped.

Don't merge the PR. That's the user's call.
