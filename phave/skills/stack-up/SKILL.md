---
name: stack-up
description: Use when asked to bring up, spin up, or create a phave-ng stack, or to get an isolated environment for a feature, bug, or PR review. Runs the `stack` CLI (stack-ng) end to end with preflight checks, picks the right create flags, and verifies the stack is healthy before handing it over.
---

# Bring up a stack

A stack is an isolated phave-ng environment: git worktree, its own database on the shared local Postgres, and web, worker, and Mailpit processes on a slot port. The `stack` skill has the full command reference. This skill is the procedure.

## 1. Preflight

Run these and stop at the first problem:

```sh
stack config              # dev_name must be set; note source_dir and stacks_dir
pg_isready -h localhost -p 5432
stack list                # what's running, which slots are taken
stack template status     # how far behind main the template is
```

- `dev_name` not set: ask the user to run `! stack setup`. It's interactive, so don't run it yourself.
- Postgres down: tell the user. Don't start or restart it yourself, because it also serves their own dev environment.
- All 10 slots used: list the stacks and ask which one to tear down (see `stack-down`).
- Template missing: `stack template build`. Template behind main: `stack template refresh`. Both take a while. Run them in the background and wait.

## 2. Pick a name

- Lowercase letters, digits, and hyphens only. It becomes the hostname.
- Short and tied to the work: `invite-flow`, `fix-null-session`, `pr-142`.
- Must not collide with an existing name in `stack list`.
- If the user didn't give a name, propose one and use it. Don't stop to ask.

## 3. Pick flags

| Situation | Command |
|---|---|
| New work, new branch off main | `stack create <name>` (branch becomes `<dev_name>/<name>`) |
| Continue an existing branch / review a teammate's PR | `stack create <name> --branch <branch>` (works for origin-only branches) |
| Branch off something other than main | `stack create <name> --base <ref>` |
| E2E run, or anything sensitive to data shape | add `--no-template` |
| Reproduce a subscription with no AI configured | add `--no-ai-keys` |
| Need buying groups / committees populated | add `--seat-committees` (about 3 more minutes) |

For a PR, get the branch with `gh pr view <n> --json headRefName -q .headRefName`.

If the flags aren't obvious, run with `--dry-run` first and show the plan.

## 4. Create

```sh
stack create <name> [flags]
```

This fetches origin, creates the worktree and database, writes `.env.local`, starts all tiers, health-checks, and runs tenant migrations. It takes minutes, so run it in the background. If it's interrupted or fails partway, re-run the **same command**; it resumes.

## 5. Verify

```sh
stack status <name>
```

All tiers must be up. If not:

```sh
stack logs <name> -t web -n 100
stack logs <name> -t worker -n 100
stack doctor              # report drift; only add --fix after reading the report
```

Fix the cause and re-run `stack create <name>` or `stack restart <name>`. Don't hand over a stack that isn't healthy.

## 6. Hand over

Report:

- URL: `http://<name>.localhost:<port>` (from `stack status`)
- Login: `nick@phave.com` / `master`
- Worktree: `<stacks_dir>/<name>/phave-ng`. Do all code changes for this work there, not in the main phave-ng checkout.
- Branch name
- Mailpit UI URL, if the work involves email

## Rules

- Never hand-edit `.env.local`. It's regenerated on every `stack start`.
- Never touch slot 0 (`:3000`). That's the user's own dev server.
