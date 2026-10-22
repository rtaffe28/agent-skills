# agent-skills

Personal Claude Code skills. Each skill lives in `skills/<name>/SKILL.md`.

## Skills

| Skill | Use it for |
|---|---|
| [`commit-pr-workflow`](skills/commit-pr-workflow/SKILL.md) | Branching, commit messages, and opening PRs |
| [`review-checklist`](skills/review-checklist/SKILL.md) | Reviewing a diff or PR against a fixed checklist |
| [`tdd`](skills/tdd/SKILL.md) | Test-first changes: write a failing test, make it pass, refactor |

## Install

Symlink each skill into your user skills directory so edits here take effect immediately:

```sh
./install.sh
```

This links `skills/*` into `~/.claude/skills/`. Restart Claude Code (or start a new session) to pick up new skills.

## Adding a skill

1. Create `skills/<name>/SKILL.md` with `name` and `description` frontmatter.
2. Write the description as *when to use it*. Claude decides whether to load the skill from that line alone.
3. Run `./install.sh` again.
