---
name: pr-babysit
description: Use when asked to monitor, watch, or babysit a pull request, get a PR green, fix failing CI or checks, resolve merge conflicts with main, or address PR review comments. Watches the PR's checks, mergeability, and review threads; fixes failing phave-ng CI jobs, merges main to resolve conflicts, implements and replies to every review comment, pushes the fixes, and repeats until the PR is green, mergeable, and has no unaddressed feedback.
---

# Babysit a PR until it's green, mergeable, and every review comment is addressed

Invoking this skill authorizes **normal pushes to the PR's own branch** and **replying to and resolving review threads on it**. It does not authorize force-pushing, merging the PR, or touching someone else's PR. Ask for each of those.

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
3. **Unaddressed review comments:** address them (step 5). Do this even while checks are pending, so the fixes ride the next CI run.
4. **Pending checks:** wait (step 6).
5. **All green, mergeable, and no unaddressed feedback:** report (step 7).

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

Commit per `commit-pr-workflow` (e.g. `fix(ci): <what was wrong>`), then run `git push` (never `--force`). Go to step 6.

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

## 5. Address review comments

### Collect every piece of feedback

Inline threads, with whether they're resolved:

```sh
gh api graphql -F owner=phavesoftware -F repo=<repo> -F n=<n> -f query='
query($owner:String!,$repo:String!,$n:Int!){repository(owner:$owner,name:$repo){pullRequest(number:$n){
  reviewThreads(first:100){nodes{id isResolved isOutdated path line
    comments(first:50){nodes{databaseId author{login} body createdAt}}}}}}}'
```

Plus review summaries and general PR comments:

```sh
gh pr view <n> --json reviews,comments
```

Work on: every **unresolved** thread, every review with `CHANGES_REQUESTED` or a body containing requests, and every general comment that asks for something. Include bot reviewers (e.g. Claude review, CodeQL, docs audit); their findings count too. Skip threads where your reply is the last word and the reviewer hasn't responded since.

### Triage each comment

| Kind | Do |
|---|---|
| **Actionable change** (bug, naming, missing test, style, simplification) | Implement it |
| **Question** | Answer it in the thread, with `path:line` references. If the answer reveals a real problem, it's actionable. |
| **Suggestion you believe is wrong** | Don't change the code. Reply with the concrete reason (the constraint, the caller, the test that would break) and leave the thread open for the reviewer. |
| **Valid but out of scope** | Reply proposing a follow-up issue. Don't grow the PR. |
| **Needs the user** (changes a design decision or scope, two reviewers disagree, product behavior is unclear) | Ask the user before doing anything |

Read the code around each comment before deciding. A comment on an outdated line (`isOutdated`) may already be fixed; check the current code.

### Implement the fixes

- Group related comments into logical commits, e.g. `refactor: rename X per review`, `test: cover empty input per review`.
- Fix the general case the reviewer pointed at, not just the one line: if they flagged a pattern, grep for the other instances in the PR's diff.
- Follow `tdd` for anything behavioral: a missing test or a bug gets a failing test first.
- Run the local checks for what you touched (step 3's table), then `git push`.

### Reply on every thread

After the push, reply in each thread you handled, so the reviewer can see what happened without diffing:

```sh
gh api repos/phavesoftware/<repo>/pulls/<n>/comments/<databaseId>/replies -f body='Fixed in <sha>: <one line on what changed>'
```

For review summaries and general comments, use `gh pr comment <n> --body '...'`.

- **Fixed:** "Fixed in `<sha>`: ..." Then resolve the thread (`gh api graphql -f query='mutation{resolveReviewThread(input:{threadId:"<id>"}){thread{isResolved}}}'`).
- **Answered, pushed back, or deferred:** reply, but **leave it unresolved** so the reviewer decides.
- Keep replies short and factual. Don't thank, apologize, or restate the comment.

Once all requested changes are addressed, tell the user who requested changes. Ask before re-requesting their review (`gh pr edit <n> --add-reviewer <login>`).

## 6. Watch

After each push, wait for the new run instead of polling:

```sh
gh pr checks <n> --watch --fail-fast     # run in the background; you'll be notified when it exits
```

When it exits, go back to step 2. New review comments can arrive at any time, so re-check threads on every pass. For a long-running watch the user wants kept up over time (new reviews, pushes from teammates, main moving), suggest `/loop`.

### Stop and report, instead of looping, when:

- The same check has failed after **3** fix attempts.
- The failure is already broken on main, or is infra that a rerun didn't fix.
- A conflict needs a product or design decision (both sides changed the same behavior differently).
- A review comment needs the user's decision (see the triage table).
- A reviewer pushed back on your reply and the disagreement isn't resolved by the code.

## 7. Report

When everything is green and mergeable, or you've stopped:

- PR link and its final state: checks passing/failing, mergeable or not, review status.
- Each fix pushed: commit, which check it fixed, and the root cause in one line.
- Conflicts resolved: which files, and how each was decided.
- Review comments: each one marked fixed (with commit), answered, pushed back (with reason), deferred, or waiting on the user.
- Anything left for the user, and why you stopped.

Don't merge the PR. That's the user's call.
