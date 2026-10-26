---
name: manual-test
description: Use when the user wants to test a phave-ng feature themselves, or asks for a manual test plan, QA script, or walkthrough. Seeds every piece of data the feature needs on a stack, verifies the seed, then gives the user a step-by-step test plan to walk through by hand.
---

# Manual test plan with seeded data

You prepare everything and the user does the testing. Your job is to make sure that when they open step 1, all the data and state they need already exists, and every step tells them exactly where to go and what they should see.

## 1. Work out what the change added

Same as `ai-test` step 1: read `git log` / `git diff origin/main...HEAD` in the stack's worktree and the PR description, then list every user-visible page, behavior, edge case, and regression neighbor.

From that list, write **scenarios**: things a person would actually do, like "an admin creates X, a member sees it, and an outsider can't". Each scenario names who does it and what it starts from.

## 2. Get a stack ready

Use `stack-up` if the branch doesn't have a healthy stack yet. Stay in **dev mode** (the default). Manual testing doesn't need `--prod`.

## 3. Seed everything the scenarios need

For each scenario, list its preconditions: tenant, users and their roles, records (accounts, contacts, campaigns, and so on) in the right states, feature flags, integration connections, emails waiting in Mailpit. Then create them, preferring options in this order:

1. **Existing seeds:** `stack seed <name>` (with `--bulk`, `--seat-committees`, or `--e2e` as needed), or the repo's `pnpm seed:*` scripts after `eval "$(stack env <name>)"`.
2. **The app's own API or UI, driven by a throwaway script:** a Playwright or tsx script in `e2e/_ai-test/` (excluded from git as in `ai-test` step 3) that signs in and creates the data the way a user would.
3. **Direct SQL via `stack psql`:** only when there's no other way. Set tenant context first (`select set_config('app.tenant_id', ...)` plus `search_path`). See the `stack` skill's RLS warning.

Rules for seeded data:

- Prefix names so it's obvious what's seeded: `QA - Acme renewal`, `qa-member@...`.
- Make scripts idempotent so a re-run doesn't duplicate data.
- Seed the edge cases too: an empty list, a very long name, a record in each status the feature handles.
- Users for permission scenarios need known passwords. Write them down for the plan.

**Verify the seed:** load each scenario's starting URL (curl or a quick Playwright check) and confirm the data appears. Fix the seed now, rather than letting the user find a missing record at step 4.

## 4. Write the plan

Publish it as an Artifact (load `artifact-design` first). The user walks through it, so make it a checklist they can tick off: one checkbox per step and a notes field per scenario. Store that state in `localStorage` only, since it's per viewer.

Structure:

1. **Setup:** stack URL, Mailpit URL, every login (email / password / role), and a table of the seeded data with names and where to find it.
2. **Scenarios**, happy path first, then edge cases, permissions, and regression checks. Each step has:
   - **As:** which user
   - **Go to:** an exact, clickable URL
   - **Do:** one action
   - **Expect:** what should happen, concretely ("the row shows status *Active* and a green badge"), not "it works"
3. **Things to eyeball:** responsive or mobile widths, dark mode, loading and empty states, copy.
4. **Reset:** how to restore the seed if they want to run a scenario again (the re-run command).
5. **Reporting back:** ask them to note the step number and what they saw for anything that fails.

Keep each step to one action. If a step needs a paragraph of explanation, split it.

## 5. Hand over

Give the link, the stack URL, and the main login in chat. Don't run the scenarios yourself. When the user reports failures, investigate them on the same stack.

Leave throwaway seed scripts in `e2e/_ai-test/` until testing is done, then delete them.
