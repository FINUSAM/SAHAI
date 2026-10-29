# 0005: Plan notifications ahead with the engine, using flutter_local_notifications

- **Status:** Accepted
- **Date:** 2026-10-30
- **Decided by:** FINUSAM, 2026-10-30
- **Related:** M3, M4; PRD 7; AT-050 to AT-058, AT-078, AT-079; [tech plan §7](../tech-plan/README.md#7-notifications-prd-7-m3-and-m4)

## Context

Notifications must fire when the app is closed, name the item or group several, stay silent for items still hidden under a set-aside ancestor (AT-054), respect Remind me and the global switch, survive a phone restart, and work without network access. Android often delays or stops background work, especially on some phone brands.

## Decision

- **Plan ahead.** A pure-Dart planner uses the engine to step through upcoming wake and show times. Assuming no further changes, it works out which items will newly appear on the Summary at each moment, and schedules one notification per moment.
- **Reschedule** everything after every action, on app start and resume, and after a time-zone change. The horizon is 60 days, capped at 100 notifications.
- **Recurring items** get show-day and due-day reminders at the reminder time. The due-day reminder ignores set-aside ancestors.
- **Inexact scheduling** by default. Exact scheduling only when "Exact reminders" is on and Android's alarm permission is granted.

| Package | Version | License | Publisher | Maintenance (checked 2026-10-30) |
|---|---|---|---|---|
| `flutter_local_notifications` | 22.3.3 | BSD-3 | dexterx.dev | Released 2026-10-25; 150/160 pub points |
| `timezone` | 0.11.2 | BSD-2 | labs.dart.dev | Released 2026-10-12; 160/160 |
| `flutter_timezone` | 5.1.1 | Apache-2.0 | wolverinebeach.net | Released 2026-10-03; 160/160 |

**Permissions this brings** (each needs approval when added): `POST_NOTIFICATIONS`, `RECEIVE_BOOT_COMPLETED`, optional `SCHEDULE_EXACT_ALARM`, and possibly `VIBRATE`.

## Alternatives considered

| Option | Pros | Cons | Why not chosen |
|---|---|---|---|
| A background job that checks at fire time (e.g. `workmanager`) | Always current | Android delays or kills it; extra package; more battery use | Unreliable timing |
| Native Kotlin `AlarmManager` code | Full control | Much more code to write and maintain | The plugin already handles boot restore and grouping |

## Consequences

- Correct as long as the app reschedules after every change, which the application layer does automatically.
- If the app isn't opened for over 60 days, later reminders aren't scheduled (risk R4 in the plan).
- Delivery with the app closed must be checked on real phones (marked **D** in the test matrix), ideally on at least two brands.
