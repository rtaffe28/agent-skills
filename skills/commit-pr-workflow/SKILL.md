---
name: commit-pr-workflow
description: Use when creating a branch, writing a commit message, or opening a pull request. Covers branch naming, Conventional Commits format, pre-push checks, and the PR description template.
---

# Commit & PR workflow

## Branches

- Never commit directly to `main`. If you're on it, create a branch first.
- Name: `<type>/<short-kebab-summary>`, e.g. `feat/user-export`, `fix/null-session-crash`.
- Types: `feat`, `fix`, `refactor`, `test`, `docs`, `chore`, `perf`.

## Commits

Use [Conventional Commits](https://www.conventionalcommits.org):

```
<type>(<optional scope>): <imperative summary, ≤72 chars, no period>

<body: why the change was made, not what the diff shows. Wrap at 72.>
```

- One logical change per commit. If the summary needs "and", split it.
- Stage files explicitly (`git add <paths>`), not `git add -A`. Check `git status` first so you don't commit secrets, `.env` files, or build output.
- Use the imperative mood: "add", not "added" or "adds".
- Mark breaking changes with `!` after the type and a `BREAKING CHANGE:` footer.

## Before pushing

Run whatever the project defines, in this order, and stop on the first failure:

1. Formatter / linter (e.g. `npm run lint`, `ruff check`, `golangci-lint run`)
2. Type check, if the language has one
3. Tests for the touched area, then the full suite if it's fast

If a check fails, fix it in a new commit. Don't amend commits that are already pushed, and never `--no-verify` past a hook without asking.

## Pull requests

Open with `gh pr create`. The title follows the same format as the commit summary. Body:

```markdown
## What
<1–3 sentences on the change>

## Why
<the problem or ticket this addresses>

## How to test
<commands or steps a reviewer can run>

## Notes
<risks, follow-ups, screenshots; delete if empty>
```

- Keep PRs small enough to review in one sitting, roughly under 400 changed lines. Split larger work into stacked PRs.
- Link the issue (`Closes #123`) when there is one.
- Open as a draft (`--draft`) if CI hasn't passed yet or the work is incomplete.
