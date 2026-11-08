# Sahai (GTD AI)

Sahai is an offline-first task manager for Android, built with Flutter. iOS will follow after v1.

Everything Sahai stores stays on your device. Version 1 has no internet access, no accounts, and no analytics or tracking.

## Status

**M4 Recurring items shipped as v0.4.0.** The app opens on the Summary: the next step of every project and stream, and nothing else. Tick a card to complete it (with 5 seconds to undo), tap it for its path and notes, or open it in the tree. The Explorer from M1 still holds the whole tree. Set anything aside until later, with a reminder when it comes back; the Set-Aside page lists what's away. Stream items can repeat, with due labels, Skip, Stop repeating and reminders on the show day and the due day. Groups and order arrive in M5, and Capture in M6.

| | |
|---|---|
| Platform | Android (iOS later) |
| Framework | Flutter |
| Application ID | `com.finusam.sahai` |
| Current milestone | M5 Groups and order (v0.5.0, in progress) |

## Roadmap

v1 is built in 8 milestones, each released as a tagged version:

| Milestone | Name | Tag |
|---|---|---|
| M1 | Foundations | v0.1.0 |
| M2 | Core loop | v0.2.0 |
| M3 | Set aside | v0.3.0 |
| M4 | Recurring items | v0.4.0 |
| M5 | Groups and order | v0.5.0 |
| M6 | Capture | v0.6.0 |
| M7 | Polish and safety | v0.7.0 |
| M8 | Release prep | v0.8.0 |
| | Public release | v1.0.0 |

## Documentation

| Document | Location |
|---|---|
| Product requirements (PRD) | [`docs/PRD.md`](docs/PRD.md) |
| Approved PRD changes (read with the PRD) | [`docs/PRD_Edits.md`](docs/PRD_Edits.md) |
| Acceptance tests | [`docs/tests/`](docs/tests/) |
| Technical plan | [`docs/tech-plan/`](docs/tech-plan/) |
| Design and wireframes | [`docs/design/`](docs/design/) |
| Decision records | [`docs/decisions/`](docs/decisions/) |
| Work plans and checklists | [`docs/plans/`](docs/plans/) |
| How to contribute | [`CONTRIBUTING.md`](CONTRIBUTING.md) |
| Rules for Claude Code sessions | [`CLAUDE.md`](CLAUDE.md) |
| Changes | [`CHANGELOG.md`](CHANGELOG.md) |

## Getting started

To get a development machine ready (details in the [technical plan](docs/tech-plan/README.md#2-toolchain)):

1. Install **Flutter 3.47.3** (stable channel), which includes Dart 3.13.3.
2. Install **Android Studio**. In its SDK Manager, add **Android SDK Platform 36** and the build tools.
3. Use **JDK 17 or newer**. Android Studio's bundled JDK works; point Flutter at it with `flutter config --jdk-dir <path>` if needed.
4. If Flutter can't find the Android SDK, run `flutter config --android-sdk <path>`.
5. Run `flutter doctor` and fix anything it reports for Android.
6. For testing on a phone: Android 8.0 or newer, with USB debugging on.

### Everyday commands

Run these from the repo root.

| Task | Command |
|---|---|
| Get packages | `flutter pub get` |
| Regenerate database code after changing `lib/data/tables.dart` or `database.dart` | `dart run build_runner build` |
| Format | `dart format lib test tool integration_test` |
| Analyze | `flutter analyze` |
| Run all tests | `flutter test` |
| Run the tests on a connected phone (read the warning below first) | `flutter test integration_test --no-uninstall` |
| Acceptance test coverage | `dart run tool/at_coverage.dart M2` |
| Engine benchmark on a 10,000-item tree | `dart run tool/benchmark.dart` |
| Run on a connected phone | `flutter run` |
| Release APK (debug-signed until M8) | `flutter build apk --release` |

**Warning about the phone tests:**

- Without `--no-uninstall`, the run uninstalls the app when it finishes, which deletes its data on the phone.
- The tests use throwaway databases, but the test build still replaces the installed app. Reinstall the release build afterwards with `adb install -r build\app\outputs\flutter-apk\app-release.apk`.
- Check this again in M8. Once the app has its own signing key, a test build won't install over the release build, and that could trigger an uninstall.

### Changing the database

1. Change the tables, then raise `schemaVersion` in `lib/data/database.dart`.
2. Run `dart run drift_dev make-migrations`. It exports the new schema to `drift_schemas/` and generates migration tests.
3. Write the migration step. It runs after `backupBeforeMigration` and must never drop data (PRD 13).

### Project layout

| Folder | Holds |
|---|---|
| `lib/engine/` | Pure Dart rules: node types, tree, current task and locks, the Summary visibility rules and the surfaced diff |
| `lib/data/` | drift tables, database, migrations |
| `lib/actions/` | The only code that writes: each action is one transaction plus its log event, and it recomputes the Summary and logs what surfaced in that same transaction |
| `lib/app/` | App widget, providers (database, clock, actions), routes and theme |
| `lib/features/` | Screens: the Summary, the Explorer, and placeholders for later tabs |
| `lib/shared/` | Clock and id helpers, and every piece of user-facing text (`strings.dart`) |
| `test/` | Unit and widget tests, named by acceptance test ID |
| `integration_test/` | Runs the widget tests on a phone |
| `tool/` | Test matrix generator and AT coverage report |
| `drift_schemas/` | Exported database schema for each version |

## License

Proprietary. Copyright (c) 2026 FINUSAM. All rights reserved. See [`LICENSE`](LICENSE).
