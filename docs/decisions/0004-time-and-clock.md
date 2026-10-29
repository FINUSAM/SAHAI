# 0004: Injected clock, UTC storage and one logical-day function

- **Status:** Proposed
- **Date:** 2026-10-30
- **Decided by:** FINUSAM (pending)
- **Related:** M1–M4, M7; PRD 3, 7, 13; [tech plan §4.3](../tech-plan/README.md#43-time)

## Context

Presets, the "Day starts at" hour, due labels, recurring show dates and set-aside wake times all depend on the current time. Acceptance tests use specific dates (November 2026) and time-zone changes (India to Dubai). CLAUDE.md requires every time-dependent piece of code to be testable with a fake clock.

## Decision

- All code gets the time from an injected clock: `clock` 1.1.3 (Apache-2.0, published by tools.dart.dev, the Dart team). Tests use a fixed or advancing fake clock. A CI check fails if `DateTime.now()` appears outside the clock file.
- Moments (`snooze_until`, timestamps, events) are stored in **UTC milliseconds** and shown in local time.
- Due dates are **local calendar dates** (`YYYY-MM-DD`), read in the phone's current time zone.
- One function, `logicalDate(instant, dayStartHour)`, decides which day a moment belongs to. Presets, due labels and show dates all use it.
- Recurring show times are computed when needed, not stored, so they follow time-zone changes.
- Time-zone-aware scheduling uses `timezone` 0.11.2 (BSD-2, labs.dart.dev) and `flutter_timezone` 5.1.1 (Apache-2.0); both are added in M3.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| Our own `Clock` interface | No package | Reinvents a small, stable Dart-team package | `clock` also works with `withClock` in tests |
| Store local times | Simple display | Breaks on time-zone and daylight-saving changes (AT-118) | PRD 3 requires UTC |
| Store show dates as `snooze_until` | One field to check | Goes wrong after a time-zone change (AT-081) | Computing on demand is correct and cheap |

## Consequences

- Every time rule is a pure function with table-driven tests.
- A set-aside time is an absolute moment (same instant after travel), while a due date is a calendar date (the "5th" wherever you are). These are deliberately different, as the PRD and AT-081/AT-118 require.
