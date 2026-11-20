import 'package:drift/drift.dart';

import '../engine/node_type.dart';
import 'database.dart';
import 'settings.dart';

/// Whether the app should open on onboarding (PRD 8.1, M7 wireframe
/// choice): only on first run, when there are no areas yet and onboarding
/// was never finished or skipped. An install that already has data, such as
/// one updated from 0.6.0, goes straight to the Summary.
Future<bool> needsOnboarding(SahaiDatabase db) async {
  if ((await readSettings(db)).onboardingDone) return false;
  final domain =
      await (db.select(db.nodes)
            ..where(
              (n) =>
                  n.type.equals(NodeType.domain.dbName) &
                  n.isDeleted.equals(false),
            )
            ..limit(1))
          .getSingleOrNull();
  return domain == null;
}
