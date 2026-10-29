# 0002: drift on SQLite for storage and migrations

- **Status:** Proposed
- **Date:** 2026-10-30
- **Decided by:** FINUSAM (pending)
- **Related:** M1; PRD 3, 10, 13; [tech plan §5](../tech-plan/README.md#5-data)

## Context

PRD 3 requires one on-device SQLite database. PRD 13 requires database work off the UI thread, versioned migrations tested from every released version, and no destructive migrations. Every multi-step change must be atomic.

## Decision

Use **drift** (typed SQLite for Dart) with **drift_flutter** to open the database on a background isolate. Use **drift_dev** and **build_runner** for code generation, schema snapshots and generated migration tests. SQLite itself is bundled by `sqlite3` 3.x, which drift depends on.

| Package | Version | License | Publisher | Maintenance (checked 2026-10-30) |
|---|---|---|---|---|
| `drift` | 2.35.3 | MIT | simonbinder.eu | Released 2026-10-23; 160/160 pub points |
| `drift_flutter` | 0.3.1 | MIT | simonbinder.eu | Released 2026-07-11; 160/160 |
| `drift_dev` (dev) | 2.35.2 | MIT | simonbinder.eu | Released 2026-10-23 |
| `build_runner` (dev) | 2.17.1 | BSD-3 | tools.dart.dev | Released 2026-10-14; 160/160 |

Settings: WAL journal mode with a full checkpoint when the app goes to the background. Times are stored as UTC milliseconds and due dates as `YYYY-MM-DD` text. Every write that changes more than one row runs in a transaction.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| `sqflite` (2.4.5, BSD-2) | Very widely used, simple | Hand-written SQL strings; no generated migration tests; runs on the platform thread through a channel | Migration safety (AT-012) is a hard requirement |
| `sqlite3_flutter_libs` | Previously needed with drift | End-of-life since `sqlite3` 3.x bundles SQLite | Obsolete |
| Isar / ObjectBox / Hive | Fast object stores | Not SQLite, which PRD 3 requires | Out of scope |

## Consequences

- Code generation adds a build step (`dart run build_runner build`) and generated files to keep in sync.
- To verify in M1: that `sqlite3` 3.x builds cleanly on the development machine, and that it adds no Android permissions.
- The drift author maintains `drift`, `drift_flutter` and `sqlite3`, which concentrates risk in one maintainer. The packages are widely used and the data stays in standard SQLite, so a switch later would be possible.
