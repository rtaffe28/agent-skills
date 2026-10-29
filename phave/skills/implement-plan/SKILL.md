---
name: implement-plan
description: Use when asked to implement, build, or execute a plan made with `arch-plan` (a `~/plans/<date>-<slug>/plan.md`). Builds the entire plan on one stack, one branch, and one PR, fanning independent slices and tasks out to parallel subagents, implementing the planned interfaces first, test-first, and keeps the plan file updated with progress and any deviations.
---

# Implement an architecture plan

The whole plan ships as **one worktree, one branch, one PR**, however many slices it has. Big PRs are fine here: this overrides the "under ~400 lines / stacked PRs" guidance in `commit-pr-workflow`. Slices are still the unit of work, commits, and progress tracking, just not of branches or PRs.

## 1. Load the plan

- Find it: the path the user gave, otherwise the most recent `~/plans/*/plan.md` whose status is `Approved` or `In progress`. Confirm which one if there's more than one.
- Read all of `plan.md`, including every slice.
- **Status must be `Approved` or `In progress`.** If it's `Draft`, or open questions still affect any slice, stop and ask.
- Re-read phave-ng's `CLAUDE.md` and `.claude/rules/*`.
- Check drift: if `main` has moved since the plan's base commit, skim `git log <base>..origin/main` for changes to the files the plan touches. Flag conflicts before writing code.

## 2. Set up

- One stack and one branch for the entire plan (`stack-up`: `stack create <slug>`). Every slice is built in that stack's worktree. Don't create per-slice branches or stacks, and don't give subagents `isolation: "worktree"`.
- Set the plan's status to `In progress`.

## 3. Schedule for parallelism

Before writing code, turn the slices into **waves**:

1. From the slices table and each slice's interfaces, list the files every slice will create or change, and which slices depend on which.
2. **Wave 0 is the shared foundation**: every planned interface any slice needs (types, signatures, schema and migration, route contracts, component props). You build it yourself, sequentially, because everything else depends on it.
3. Group the remaining slices into waves: a slice goes in the earliest wave after all its dependencies. Slices in the same wave run in parallel only if their file sets are disjoint. If two overlap, move one to the next wave, or have one agent own the shared file.
4. Within a big slice, split it further into tasks on disjoint files (e.g. service + tests, route, UI component) when that buys real parallelism.

Write the wave schedule into `plan.md` under `## Execution`, then mark the slices in the current wave `🟡`.

## 4. Build

### Wave 0: interfaces (you)

Write the types, signatures, schema and migration, route contracts, and component props **exactly as planned**, for all slices. Stub bodies. Run the migration and typecheck. Commit it (`feat(<area>): add interfaces for <plan>`), so every agent starts from a green, committed base.

### Waves 1..N: behavior and wiring (parallel agents)

Launch one `general-purpose` agent per slice (or per task) in the wave, **all in a single message** so they run concurrently. Each brief contains:

- The stack's worktree path, and that it must stay inside its assigned files.
- The slice's goal, acceptance criteria, and its interface blocks from the plan, copied in.
- Its exact file list, and the files it must **not** touch (other agents' files in the same wave).
- To follow the `tdd` skill (red, green, refactor) for each behavior, then wire up its routes, pages, jobs, and navigation.
- To run only the targeted test files and typecheck for its own area, **not** commit, and not change planned interfaces; if one looks wrong, stop and report back instead.
- To report: files changed, tests added and their results, and any deviation or surprise.

While a wave runs, don't edit files it owns. When all its agents finish:

1. Review each agent's diff yourself. Fix or re-brief anything off-plan.
2. Run `pnpm typecheck` and the relevant `pnpm test:*` suites across the wave, and fix integration breaks.
3. Commit each slice separately (`git add` its files only), following `commit-pr-workflow`, so the history reads slice by slice.
4. Mark those slices `✅`, fill in their **Implementation notes**, then start the next wave.

Keep going wave after wave without stopping for review, unless a deviation needs a decision (section 5) or checks fail in a way you can't fix.

## 5. Deviations

The plan's interfaces are the contract. If one turns out to be wrong:

- **It changes a planned interface, a design decision, or scope:** stop and ask before doing it. Hold the agents in the next wave until it's resolved.
- **Anything smaller** (a private helper, file placement): just do it and note it.

Either way, update `plan.md` (the interface block or diagram) so it describes what was actually built, and log it in a `## Deviations` section: what changed, why, and the date.

## 6. Verify the whole plan

Once every wave is in, run phave-ng's full checks: `pnpm lint`, `pnpm typecheck`, and every `pnpm test:*` suite covering the touched areas. All of them must pass.

- Review the entire branch diff against `main` with the `review-checklist` skill. For a large diff, split the review across parallel agents by area and fix what they find.
- Check every slice's acceptance criteria one by one on the stack in the browser.
- For UI or anything that crosses layers, offer `ai-test` (an automated sweep with a report) or `manual-test` (a hands-on plan for the user).

## 7. Record, PR, and hand back

- Set the plan's status to `Done` and make sure every slice has its Implementation notes.
- Ask once, then push the branch and open **one** PR for the whole plan following `commit-pr-workflow`. The PR body lists each slice with what it delivered, links the plan, and calls out deviations.
- Report: what the plan delivered, the wave schedule as it actually ran, the checks run and their results, any deviations, and the PR link. Offer `pr-babysit` to get it green.
