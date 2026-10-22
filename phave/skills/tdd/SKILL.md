---
name: tdd
description: Use when implementing a feature or fixing a bug test-first, or when the user asks for TDD or red-green-refactor. Write a failing test, confirm it fails for the right reason, make it pass with minimal code, then refactor.
---

# Test-driven development

## 0. Find the test setup

Before writing anything, learn how this project tests:

- Framework and runner: check `package.json` scripts, `pyproject.toml`, `Makefile`, `go.mod`, CI config.
- Where tests live and how they're named. Copy the pattern of the nearest existing test file.
- How to run a **single** test or file. You'll do this many times, so find the fast command.

## 1. Red: write a failing test

- One behavior per test. Name it after the behavior: `returns_empty_list_when_no_matches`, not `test_search_2`.
- For a bug fix, the test reproduces the bug exactly as reported.
- Run it. **It must fail, and for the expected reason:** an assertion failure, not an import error, typo, or missing fixture. If it fails for the wrong reason, fix the test before going on.
- If it passes right away, either the behavior already exists or the test is wrong. Stop and work out which.

## 2. Green: make it pass

- Write the least code that makes the test pass. Don't add behavior no test asks for.
- Run the single test, then the surrounding file or module to check nothing nearby broke.

## 3. Refactor

- With tests green, clean up: duplication, naming, extracting functions.
- Re-run tests after each refactor step. If they go red, undo that step rather than debugging forward.

## 4. Repeat

Pick the next behavior or edge case and go back to step 1. Typical order:

1. Happy path
2. Boundaries (empty, one, many, max)
3. Invalid input and error cases

## Finish

- Run the full test suite once at the end.
- Report which tests you added, and show the red → green evidence: the failing output, then the passing output.

## Rules

- Never weaken or delete an existing assertion to make a test pass without explicit approval.
- Mock only at system boundaries (network, clock, filesystem, randomness), not the code under test.
- Tests must be deterministic. No sleeps, no dependence on test order, no real network calls.
