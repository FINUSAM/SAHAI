# Decision records

A decision record captures a significant technical decision: what was decided, why, and what else was considered. It's useful later, when someone asks "why did we do it this way?"

## When to write one

- Choosing a framework, package, database or architecture pattern
- Adding a dependency or Android permission (after the owner approves it)
- Any choice that's hard to reverse, or that future work will depend on

## How

1. Copy [`0000-template.md`](0000-template.md) to `NNNN-short-title.md`, using the next free number (e.g. `0001-state-management.md`).
2. Fill it in and add it in the same PR as the change it describes.
3. Don't rewrite accepted records. If a decision changes, write a new record and mark the old one **Superseded by NNNN**.

## Index

| # | Title | Status |
|---|---|---|
| [0001](0001-architecture-and-engine.md) | Layered architecture with a pure Dart visibility engine | Accepted |
| [0002](0002-database-drift-sqlite.md) | drift on SQLite for storage and migrations | Accepted |
| [0003](0003-state-management-and-navigation.md) | Riverpod for state, go_router for navigation | Accepted |
| [0004](0004-time-and-clock.md) | Injected clock, UTC storage and one logical-day function | Accepted |
| [0005](0005-notifications.md) | Plan notifications ahead with the engine, using flutter_local_notifications | Accepted |
