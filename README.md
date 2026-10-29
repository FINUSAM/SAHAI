# Sahai (GTD AI)

Sahai is an offline-first task manager for Android, built with Flutter. iOS will follow after v1.

Everything Sahai stores stays on your device. Version 1 has no internet access, no accounts, and no analytics or tracking.

## Status

**Pre-development.** This repository has its foundations set up (rules, docs structure and GitHub templates), but there is no app code yet.

| | |
|---|---|
| Platform | Android (iOS later) |
| Framework | Flutter |
| Application ID | `com.finusam.sahai` |
| Current milestone | M1 Foundations (not started) |

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

There's no Flutter project yet; it's created in M1. To get a development machine ready (details in the [technical plan](docs/tech-plan/README.md#2-toolchain)):

1. Install **Flutter 3.47.3** (stable channel), which includes Dart 3.13.3.
2. Install **Android Studio**. In its SDK Manager, add **Android SDK Platform 36** and the build tools.
3. Use **JDK 17 or newer**. Android Studio's bundled JDK works; point Flutter at it with `flutter config --jdk-dir <path>` if needed.
4. If Flutter can't find the Android SDK, run `flutter config --android-sdk <path>`.
5. Run `flutter doctor` and fix anything it reports for Android.
6. For testing on a phone: Android 8.0 or newer, with USB debugging on.

Build and test commands will be added here when the Flutter project is created in M1.

## License

Proprietary. Copyright (c) 2026 FINUSAM. All rights reserved. See [`LICENSE`](LICENSE).
