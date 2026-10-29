# agent-skills

Personal Claude Code skills, grouped by project or context. Each skill lives in `<group>/skills/<name>/SKILL.md`.

| Group | What it holds |
|---|---|
| `phave/` | Workflow and process skills for work at Phave |

## Phave skills

| Skill | Use it for |
|---|---|
| [`commit-pr-workflow`](phave/skills/commit-pr-workflow/SKILL.md) | Branching, commit messages, and opening PRs |
| [`review-checklist`](phave/skills/review-checklist/SKILL.md) | Reviewing a diff or PR against a fixed checklist |
| [`tdd`](phave/skills/tdd/SKILL.md) | Test-first changes: write a failing test, make it pass, refactor |
| [`stack-up`](phave/skills/stack-up/SKILL.md) | Bringing up a phave-ng stack with the `stack` CLI (stack-ng) |
| [`stack-down`](phave/skills/stack-down/SKILL.md) | Stopping or destroying a stack without losing work |
| [`ai-test`](phave/skills/ai-test/SKILL.md) | Claude tests a feature with throwaway Playwright scripts and screenshots, and reports as an Artifact |
| [`manual-test`](phave/skills/manual-test/SKILL.md) | Claude seeds the data and writes a step-by-step plan for you to test by hand |
| [`arch-plan`](phave/skills/arch-plan/SKILL.md) | Architecture-first plan (diagrams + interfaces), sliced if large, critic/defender debate, Artifact for review |
| [`implement-plan`](phave/skills/implement-plan/SKILL.md) | Builds an `arch-plan` plan slice by slice: interfaces first, then test-first behavior |
| [`pr-babysit`](phave/skills/pr-babysit/SKILL.md) | Watches a PR, fixes failing CI, resolves conflicts with main, until green and mergeable |

## Install

Symlink each skill into your user skills directory so edits here take effect immediately:

```sh
./install.sh          # every group
./install.sh phave    # just one group
```

This links `<group>/skills/*` into `~/.claude/skills/`. Skill names share one namespace there, so keep names unique across groups. Restart Claude Code (or start a new session) to pick up new skills.

## Adding a skill

1. Create `<group>/skills/<name>/SKILL.md` (make a new top-level group folder for a new project) with `name` and `description` frontmatter.
2. Write the description as *when to use it*. Claude decides whether to load the skill from that line alone.
3. Run `./install.sh` again.
