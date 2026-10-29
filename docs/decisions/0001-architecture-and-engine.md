# 0001: Layered architecture with a pure Dart visibility engine

- **Status:** Accepted
- **Date:** 2026-10-30
- **Decided by:** FINUSAM, 2026-10-30
- **Related:** M1, M2; PRD 6, 7, 13; [tech plan §3–4](../tech-plan/README.md#3-architecture)

## Context

The Summary rules (PRD 6) are the heart of the app and the riskiest logic (PRD 16). Over 100 acceptance tests depend on them, often with specific dates and times. They must recompute in under 50 ms with 10,000 items (PRD 13), and must never be stored (PRD 10).

## Decision

Split the app into an **engine** (pure Dart: no Flutter, no database, no system clock), a **data** layer (SQLite), an **application** layer (actions, each one transaction plus a log event plus an undo token) and a **UI** layer.

The Summary is computed **in memory in Dart** from a cached snapshot of the tree, using one depth-first walk. The engine also reports the next moment the Summary will change.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Compute the Summary with recursive SQL queries | Less data in memory | Rules spread across SQL; hard to test with fake times; hard to read | Testability and clarity matter most here |
| Put rules in widgets / state classes | Fast to start | Rules tied to Flutter; slow tests; duplicated logic | Doesn't scale to 124 acceptance tests |

## Consequences

- Most acceptance tests become fast unit tests with a fake clock.
- The in-memory snapshot must be kept in step with the database after every write. The application layer is the only writer, which makes that manageable.
- Memory use grows with the tree; it's a few MB at 10,000 items, which is acceptable.
- The engine is reusable for iOS (Phase 2) and for the AI planner's "what would show" checks.
