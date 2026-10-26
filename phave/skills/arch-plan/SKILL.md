---
name: arch-plan
description: Use when asked to plan a feature or project before building it, design its architecture, or slice a large piece of work. Produces a local markdown plan centered on architecture diagrams and interface definitions, sliced for large work and kept to one page for small work, stress-tested by a critic/defender debate, and presented as an Artifact for review. Implement it afterwards with `implement-plan`.
---

# Architecture-first plan

The plan answers two questions above all: **what are the pieces and how do they connect** (diagrams), and **what are the exact contracts between them** (interfaces). Task lists are secondary; a competent implementer can derive them from good interfaces.

Plans are local and personal: `~/plans/<YYYY-MM-DD>-<slug>/`. The markdown file is the source of truth. The Artifact is a view of it.

## 1. Understand the request

- Restate the goal in one or two sentences, plus what's explicitly out of scope.
- If requirements are ambiguous, ask with AskUserQuestion. Batch the questions, and only ask what would change the design. Do another round if the answers open new forks.

## 2. Gather context

In phave-ng (the main checkout or the stack's worktree):

- Read `CLAUDE.md`, `AGENTS.md`, and `.claude/rules/*` first. They encode decisions you must not contradict.
- Find what exists: the types, services, routes, tables, jobs, and components the feature touches or could reuse. For a broad sweep, run parallel `Explore` agents, one per area, and keep only their conclusions.
- Note every existing interface you'll extend, with its `path:line`.

## 3. Size it

| | Small | Large |
|---|---|---|
| Signals | One area of the codebase, roughly one PR (under ~400 lines), no migration or a trivial one | Several areas, schema changes, new background jobs, more than one PR, or several people or sessions |
| Output | `plan.md` only | `plan.md` plus `slices/01-<name>.md`, `slices/02-<name>.md`, ... |

**Don't slice small work.** Ceremony on a one-PR change is waste.

For large work, cut **vertical slices**: each slice is mergeable on its own, leaves main working, and delivers something testable. A schema-only "slice" or a "frontend slice" isn't a slice. Order the slices by dependency and keep each roughly one PR.

## 4. Write the plan

`~/plans/<date>-<slug>/plan.md`:

```markdown
# <Title>

**Status:** Draft | Approved | In progress | Done
**Size:** Small | Large (N slices)
**Repo / base:** phave-ng @ <commit>

## Goal
<2–3 sentences> · **Out of scope:** <bullets>

## Architecture
### Components
<Mermaid flowchart: existing pieces in plain style, new pieces highlighted, changed pieces marked>
### Key flows
<Mermaid sequenceDiagram for each important flow, including the main error path>
### Data model
<Mermaid erDiagram if tables or columns change; stateDiagram if something has a lifecycle>

## Interfaces
<Every contract the feature adds or changes, as real code in the repo's language.
 Mark each one NEW or CHANGED, with its target file path.>
- Types / domain models
- Functions and services: full signatures, plus what they throw
- HTTP / server actions: method, path, request and response types, auth, error codes
- Database: tables, columns, indexes, RLS policy, migration name
- Jobs / events: name, payload type, idempotency, retries
- UI components: props, and which page renders them

## Key design decisions
| Decision | Options considered | Chosen | Why |

## Open questions
- [ ] <question> — who can answer it, and what changes depending on the answer

## Slices        (large only)
| # | Slice | Delivers | Depends on | Status |

## Plan (small only)
<Ordered steps; for each: the interfaces it implements, files, and how it's tested>

## Testing strategy
<What's unit-tested and what's tested against a stack (see `ai-test` / `manual-test`)>

## Risks
```

Each `slices/0N-<name>.md` has: goal, the interfaces from `plan.md` it implements (link to them, don't copy), files, ordered steps, acceptance criteria, tests, and **Implementation notes** (left empty, filled in by `implement-plan`).

Rules:

- **Diagrams are Mermaid**, with one idea per diagram. If one needs more than ~12 nodes, split it.
- **Interfaces are code**, not prose. Name real files. Reuse existing types where you can, and say so.
- Every decision that a reasonable engineer could make differently goes in the decisions table.
- Unknowns go in Open questions. Don't quietly guess.

## 5. Critic / defender debate

Launch two agents **in parallel** with the Agent tool. Give each one the plan path and the key repo files to read, not your conclusions:

- **Critic:** "Find what's wrong. Does the design meet the goal? Are interfaces missing, leaky, or inconsistent with the codebase's patterns? Are slices not truly vertical? Is there an over-engineered or under-specified part, a missed reuse, a failure mode, a migration risk, a permissions gap? Report each issue with a concrete fix."
- **Defender:** "Make the strongest case for the plan's choices, especially where the obvious alternative was rejected. Name what the critic is likely to attack and why the current design holds."

Then a **rebuttal round**: send each agent the other's output (SendMessage) and ask it to concede or hold each point, with reasons.

You are the judge. For each point of contention:

- Agreed change: apply it to `plan.md` / slice files.
- Unresolved, and it needs the user: move it to **Open questions**.
- Rejected: keep the decision, and record why in the decisions table.

Append a `## Debate summary` to `plan.md`: point → critic → defender → resolution.

## 6. Present as an Artifact

Load `artifact-design`, and `artifact-diagramming` for the diagrams. Publish one page for review, in this order:

1. Title, status, size, and a one-paragraph summary
2. **Key design decisions** (the table)
3. **Open questions**: what you need from the user, first-class and easy to find
4. **Architecture diagrams**, rendered, not raw Mermaid text
5. **Interfaces**, as highlighted code, grouped by layer, with NEW / CHANGED badges
6. Slices (large) or steps (small)
7. Debate highlights: only the points that changed the plan or are still open
8. The local path of `plan.md`

In chat, give the link plus the open questions.

## 7. Iterate until approved

The user's answers and comments go into `plan.md` first. Then republish the same Artifact (same file path, so the URL stays the same). When the user approves, set **Status: Approved** and point them to `implement-plan`.

Don't write product code in this skill.
