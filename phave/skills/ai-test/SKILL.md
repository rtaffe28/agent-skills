---
name: ai-test
description: Use when asked to test a phave-ng feature or branch end to end, QA it, or "actually test" what a change added. Writes throwaway Playwright scripts that drive every page and feature the change touched on a running stack, screenshots each step, and finishes with an Artifact report of what was tested and the results.
---

# AI testing with throwaway Playwright scripts

The goal is real coverage of what the change added, with visual evidence. The scripts are temporary and never committed. The deliverable is the report.

## Who the tester is

The user is **Ryan, `ryan@phave.com`** (password `master` locally). Build everything around that login:

- Sign in as `ryan@phave.com` in every seed or probe script (`signInAsAcme(page, { email: "ryan@phave.com" })`), never `nick@phave.com` or the e2e operator. Whatever the seed creates is then authored by Ryan, and his test sends and notifications reach him.
- Ryan owns two local subscriptions, **Acme Holdings** (`acme`, the demo data) and **test**. Sign-in may land on either. Seed into the subscription Ryan's browser is on (`select t.slug from session s join tenant t on t.id = s.active_tenant_id where s.user_id = (select id from "user" where email = 'ryan@phave.com') order by s.last_seen_at desc limit 1`), Acme Holdings unless that says otherwise. After signing in, switch the script's session to it (`POST /api/session/tenant` with `{ tenantId }`) and check the switch took before writing anything.
- The plan's Setup names the login as `ryan@phave.com` and the subscription by name. Other logins (a viewer for permission checks, and so on) appear only in the steps that need them.

## 1. Work out what the change added

From the stack's worktree (`<stacks_dir>/<name>/phave-ng`):

```sh
git fetch origin
git log --oneline origin/main..HEAD
git diff --stat origin/main...HEAD
```

Also read the PR description (`gh pr view`) and the linked ticket if there is one.

Turn the diff into a **test inventory** before writing any code:

- **Pages:** every changed or new `app/**/page.tsx`, mapped to its URL. Pages that render a changed component count too; grep for the component's imports.
- **Features:** every user-visible behavior: forms, buttons, dialogs, tables, filters, empty states, validation, permissions, emails sent, background jobs.
- **Edge cases:** empty data, long text, invalid input, unauthorized user, and the error path of each action.
- **Regression neighbors:** existing flows next to the change that could break.

Every inventory item has to end up as a test or as an explicit "not tested, because ..." in the report.

## 2. Get a stack ready

- No stack for this branch yet: use the `stack-up` skill (`stack create <name> --branch <branch>`).
- For a sweep of more than a handful of pages, serve the production bundle, because the dev server balloons in memory: `stack restart <name> --prod`.
- Seed the e2e principal: `stack seed <name> --e2e`.
- Seed the data each test needs (see the `manual-test` skill, step 3). Prefer doing it inside the spec through the UI or API so the test is self-contained.

## 3. Write the throwaway specs

Put them in the worktree so they can use the repo's helpers, and keep git from seeing them:

```sh
cd <stacks_dir>/<name>/phave-ng
mkdir -p e2e/_ai-test
echo "e2e/_ai-test/" >> "$(git rev-parse --git-common-dir)/info/exclude"
```

Screenshots go **outside** the repo, into a run directory in the scratchpad: `<scratchpad>/ai-test/<stack>-<timestamp>/shots/`.

Skeleton:

```ts
import { test, expect } from "../helpers/fixtures";
import { signInAsAcme } from "../helpers/sign-in";

const SHOTS = process.env.AI_TEST_SHOTS!;
let n = 0;
const shot = (page, slug: string) =>
  page.screenshot({ path: `${SHOTS}/${String(++n).padStart(2, "0")}-${slug}.png`, fullPage: true });

test.describe("<feature>", () => {
  test.beforeEach(async ({ page }) => {
    const errors: string[] = [];
    page.on("console", (m) => m.type() === "error" && errors.push(m.text()));
    page.on("pageerror", (e) => errors.push(e.message));
    await signInAsAcme(page);
  });

  test("<behavior in plain words>", async ({ page }) => {
    await test.step("open the page", async () => {
      await page.goto("/...");
      await shot(page, "page-loaded");
    });
    await test.step("do the thing", async () => {
      // act, then assert on the real outcome, not just that the page rendered
      await shot(page, "after-action");
    });
  });
});
```

- One spec file per inventory area. Name each test after the behavior it proves.
- Screenshot every meaningful state: initial load, after each action, success, error, and empty state.
- Assert on outcomes: the record saved, the row appeared, the toast text, the URL changed, the email landed (`e2e/helpers/mailpit.ts`).
- Fail the test on console errors and uncaught page errors.
- Check the existing `e2e/helpers/` (sign-in, tenant-sql, mailpit, fixtures) before writing your own helper.

## 4. Run

```sh
eval "$(stack env <name>)"     # sets E2E_BASE_URL so Playwright targets the stack
export AI_TEST_SHOTS=<run dir>/shots
mkdir -p "$AI_TEST_SHOTS"
pnpm exec playwright test e2e/_ai-test --list      # confirm your tests are picked up
pnpm exec playwright test e2e/_ai-test --reporter=list,json > <run dir>/results.json
```

If `--list` finds nothing, a `projects` `testMatch` is filtering the files. Pass the default project with `--project`.

## 5. Triage

For each failure, decide whether it's a **test bug** (bad selector, timing, wrong assumption) or a **product bug**:

- Test bug: fix the spec and re-run. Don't report it as a finding.
- Product bug: keep the failing test, keep its screenshot, and write down the reproduction steps. Don't fix product code unless the user asked you to.

Then **look at the screenshots yourself** with the Read tool. Passing assertions can still hide broken layouts, overlapping elements, unstyled pages, or wrong copy. Record anything visual as a finding.

## 6. Report as an Artifact

Load the `artifact-design` skill first, then publish one HTML page. Pass screenshots as `files` instead of inlining them. Contents:

1. **Summary:** branch, commit, stack URL, date, passed / failed / not-tested counts, and a one-line verdict.
2. **Findings:** product bugs and visual problems, most severe first. Each one has a screenshot, reproduction steps, and expected vs actual.
3. **Coverage:** the inventory from step 1 as a table: item → test(s) → result, including the "not tested, because ..." rows.
4. **Walkthrough:** each test in order, with its steps, its screenshots, and its result.

Give the user the link plus a two-line summary in chat.

## 7. Clean up

```sh
rm -rf e2e/_ai-test
stack restart <name>           # back to dev mode, if you switched to --prod
```

Leave the screenshots in the scratchpad. Offer to turn tests worth keeping into real specs under `e2e/`, as a separate, deliberate change.
