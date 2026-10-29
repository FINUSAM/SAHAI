# 0003: Riverpod for state, go_router for navigation

- **Status:** Proposed
- **Date:** 2026-10-30
- **Decided by:** FINUSAM (pending)
- **Related:** M1; PRD 7, 8; [tech plan §6](../tech-plan/README.md#6-state-and-navigation)

## Context

Screens need the database, the clock, the engine's output and the actions, and tests must replace each of these with fakes. Notifications and "Open in tree" need deep links to a specific item.

## Decision

- **State:** `flutter_riverpod` 3.4.3 (MIT, dash-overflow.net, released 2026-09-03). Providers supply the clock, database, snapshot, Summary and actions, and tests override them.
- **Navigation:** `go_router` 18.1.2 (BSD-3, published by flutter.dev, released 2026-10-29), with routes such as `/summary?focus=<id>` and `/explorer?node=<id>`.

Plain Riverpod is used, without its code generator, to keep the build simple. drift already uses code generation.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| `flutter_bloc` 9.1.1 (MIT) | Very popular, explicit events | More boilerplate per screen; dependency injection is separate | Heavier for a small team |
| Provider / setState only | No extra packages | Hard to fake dependencies in tests; grows messy | Tests matter more |
| Flutter's built-in Navigator only | No package | Deep links and URL-style routes need hand-written code | go_router is the Flutter team's own package |

## Consequences

- One pattern for wiring and for test fakes across the whole app.
- Riverpod 3 has a learning curve. Conventions will be written in the M1 plan.
