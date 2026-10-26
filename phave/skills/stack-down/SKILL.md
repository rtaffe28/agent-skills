---
name: stack-down
description: Use when asked to tear down, destroy, clean up, remove, or stop a phave-ng stack, or when work in a stack is finished or merged. Decides between stopping and destroying, makes sure no work is lost before `stack destroy`, and confirms the stack is fully gone.
---

# Tear down a stack

The `stack` skill has the full command reference. This skill is the procedure.

## 1. Identify the stack

- Use the name the user gave. Otherwise, if cwd is inside a stack (an ancestor directory holds a `.stack-ng` marker), it's that directory's name.
- Run `stack list` to confirm it exists and see its state.
- "Clean up my stacks" with no name: show `stack list` and ask which ones. Never destroy stacks in bulk on your own.

## 2. Stop or destroy?

| User wants | Do |
|---|---|
| Free up memory/CPU, coming back later | `stack stop <name>`. Processes stop; worktree, branch, and database stay. |
| Work is merged, abandoned, or the PR review is done | Destroy (continue below) |
| Unclear | Ask. Stopping is always safe and can be undone; destroying can't. |

## 3. Check for unsaved work (destroy only)

Destroy deletes the worktree, the local branch, and the database. Check the worktree first:

```sh
git -C <stacks_dir>/<name>/phave-ng status --short
git -C <stacks_dir>/<name>/phave-ng log --oneline @{u}..HEAD   # unpushed commits
```

If `@{u}` errors, the branch has no upstream and was never pushed. Treat every commit on it as unpushed.

- **Uncommitted changes or unpushed commits:** show them and ask the user whether to commit and push, or throw them away. Don't decide for them.
- **Branch never pushed but has commits:** same as above.
- **Data in the stack's database the user may want** (a reproduced bug state, hand-built test data): mention that the database goes too.

## 4. Release shared resources

```sh
stack tunnel              # who holds the ngrok tunnel
```

If this stack holds it, run `stack tunnel <name> --stop` first.

## 5. Destroy

Run from **outside** the stack directory. The worktree is deleted, so a shell sitting inside it breaks.

```sh
cd ~
stack destroy <name> --yes
```

`--yes` only skips the interactive prompt, which would hang here. The checks above stand in for it.

- **Never pass `--force` without the user's explicit approval for this stack.** It deletes uncommitted and unpushed work.
- If destroy refuses, read why and report it. Don't work around it.

## 6. Verify

```sh
stack list                # the stack is gone
stack doctor              # no leftover drift
```

- Stale registry entry with nothing on disk: `stack destroy <name> --registry-only`.
- Anything else `doctor` reports: show it to the user before running `stack doctor --fix`.

## Rules

- Never stop or restart Postgres. Other stacks and the user's dev environment share it.
- Never drop `phave_stack_*` databases or delete stack directories by hand. Use the CLI so the registry stays consistent.
- Never touch the template (`stack template destroy`) as part of tearing down a stack.
