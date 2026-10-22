---
name: review-checklist
description: Use when reviewing a diff, branch, or pull request (your own before pushing, or someone else's). Walks a fixed checklist covering correctness, tests, security, and maintainability, and reports findings ranked by severity.
---

# Review checklist

## Get the diff

- Local changes: `git diff main...HEAD` (plus `git diff` for unstaged work)
- A PR: `gh pr diff <number>` and `gh pr view <number>` for the description

Read the PR description or commit messages first, so you're reviewing against the stated intent.

## Checklist

Go through every section. Only report items that are real problems in *this* diff.

### 1. Correctness
- Does the change do what the description says?
- Edge cases: empty/null input, zero, negative, very large input, unicode, concurrency.
- Error paths: are errors handled, propagated, or silently swallowed?
- Off-by-one errors, inverted conditions, wrong comparison operators.
- Callers: did a signature or behavior change break any call site? Grep for usages.

### 2. Tests
- Is new behavior covered? Is the bug being fixed covered by a regression test?
- Would the tests fail if the change were reverted?
- No tests that only assert on mocks.

### 3. Security
- User input reaching SQL, shell, file paths, HTML, or `eval`: is it parameterized or escaped?
- Secrets, tokens, or PII in code, logs, or error messages.
- Authorization checks on new endpoints or data access.

### 4. Maintainability
- Names say what things are. No misleading names left over from a refactor.
- Duplicated logic that already exists elsewhere in the codebase.
- Dead code, debug prints, commented-out blocks, stray TODOs without an owner.
- Matches the surrounding code's style and patterns.

### 5. Operational
- Migrations: reversible? Safe on a large table?
- New config or env vars documented, with defaults.
- Performance: N+1 queries, unbounded loops or collections, work on a hot path.

## Report

List findings most severe first. For each:

- **Severity**: `blocker` (wrong or unsafe), `should-fix`, or `nit`
- **Location**: `path/to/file.ext:line`
- **Problem**: one sentence
- **Scenario**: the concrete input or state that triggers it
- **Fix**: a suggestion, if it's obvious

If nothing survives the checklist, say so plainly. Don't pad the review with nits.
