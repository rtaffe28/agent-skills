---
name: implement-plan
description: Use when asked to implement, build, or execute a plan made with `arch-plan` (a `~/plans/<date>-<slug>/plan.md`), or to implement the next slice of one. Builds slice by slice on a stack, implementing the planned interfaces first, test-first, and keeps the plan file updated with progress and any deviations.
---

# Implement an architecture plan

## 1. Load the plan

- Find it: the path the user gave, otherwise the most recent `~/plans/*/plan.md` whose status is `Approved` or `In progress`. Confirm which one if there's more than one.
- Read all of `plan.md` and, for large plans, the slice you're about to build.
- **Status must be `Approved` or `In progress`.** If it's `Draft`, or open questions still affect this slice, stop and ask.
- Re-read phave-ng's `CLAUDE.md` and `.claude/rules/*`.
- Check drift: if `main` has moved since the plan's base commit, skim `git log <base>..origin/main` for changes to the files the plan touches. Flag conflicts before writing code.

## 2. Set up

- **Small plan:** one stack and one branch (`stack-up`: `stack create <slug>`).
- **Large plan:** one slice at a time, one branch per slice. If a slice depends on an unmerged earlier slice, branch from that slice's branch (`stack create <slug>-s0N --base <prev-branch>`) and note in the PR that it's stacked.
- Set the plan's status to `In progress`, and the slice's row to `🟡`.

## 3. Build: interfaces, then behavior, then wiring

1. **Interfaces first.** Write the types, signatures, schema and migration, route contracts, and component props **exactly as planned**. Stub bodies. Typecheck.
2. **Behavior, test-first.** For each behavior in the slice, follow the `tdd` skill: red, green, refactor.
3. **Wire it up:** routes, pages, jobs, navigation. Check it on the stack in the browser.

Use parallel subagents only for tasks that touch disjoint files. Give each one the relevant interface block from the plan, and review its diff yourself.

## 4. Deviations

The plan's interfaces are the contract. If one turns out to be wrong:

- **It changes a planned interface, a design decision, or scope:** stop and ask before doing it.
- **Anything smaller** (a private helper, file placement): just do it and note it.

Either way, update `plan.md` (the interface block or diagram) so it describes what was actually built, and log it in a `## Deviations` section: what changed, why, and the date.

## 5. Verify the slice

Run phave-ng's checks: `pnpm lint`, `pnpm typecheck`, and the relevant `pnpm test:*` suites (whichever ones cover the touched areas). All of them must pass.

- Review your own diff with the `review-checklist` skill and fix what it finds.
- Check the slice's acceptance criteria one by one.
- For UI or anything that crosses layers, offer `ai-test` (an automated sweep with a report) or `manual-test` (a hands-on plan for the user).

## 6. Record and commit

- Fill in the slice's **Implementation notes**: what was built, where, any surprises, and anything the next slice needs to know.
- Mark the slice `✅` in the slices table.
- Commit following `commit-pr-workflow`. **Don't push or open a PR without asking.**

## 7. Hand back

Report: what the slice delivered, the checks run and their results, any deviations, and what's next. For large plans, **stop after each slice** for the user's review before starting the next one, unless they've said to keep going.

When the last slice is done, set the plan's status to `Done`.
