import 'package:flutter_test/flutter_test.dart';
import 'package:sahai/data/settings.dart';
import 'package:sahai/engine/settings.dart';
import 'package:sahai/engine/time.dart';

import '../helpers.dart';

/// Saving settings from the Settings screen (PRD 8.6, M7).
void main() {
  late TestApp app;

  setUp(() => app = TestApp());
  tearDown(() => app.close());

  Future<AppSettings> read() => readSettings(app.db);

  test('a new database reads as the PRD defaults', () async {
    final settings = await read();
    expect(settings.dayStartMinutes, 240);
    expect(settings.reminderMinutes, 540);
    expect(settings.defaultLeadDays, 3);
    expect(settings.presetTimes, const PresetTimes());
    expect(settings.onboardingDone, isFalse);
  });

  test('each setting saves on its own and leaves the others', () async {
    await saveSettings(app.db, nowMillis: 1, dayStartMinutes: 180);
    await saveSettings(app.db, nowMillis: 2, reminderMinutes: 8 * 60);
    await saveSettings(app.db, nowMillis: 3, defaultLeadDays: 5);
    final settings = await read();
    expect(settings.dayStartMinutes, 180);
    expect(settings.reminderMinutes, 8 * 60);
    expect(settings.defaultLeadDays, 5);
    expect(settings.notificationsEnabled, isTrue);
  });

  test('AT-109 a changed preset time is saved, and Reset puts back the PRD '
      'times', () async {
    final times = const PresetTimes().withTime(Preset.tonight, 21 * 60);
    await saveSettings(app.db, nowMillis: 1, presetTimes: times);
    expect((await read()).presetTimes.tonight, 21 * 60);

    await saveSettings(app.db, nowMillis: 2, presetTimes: const PresetTimes());
    final row = await app.db.select(app.db.settingsTable).getSingle();
    expect(row.presets, isNull);
    expect((await read()).presetTimes, const PresetTimes());
  });

  test('settings changes are not activity log events (PRD 9)', () async {
    final before = await app.db.select(app.db.events).get();
    await saveSettings(
      app.db,
      nowMillis: 1,
      dayStartMinutes: 0,
      presetTimes: const PresetTimes().withTime(Preset.nextWeek, 600),
      onboardingDone: true,
    );
    expect(await app.db.select(app.db.events).get(), before);
  });

  test('Day starts at accepts only whole hours from midnight to 6 AM', () {
    expect(
      () => saveSettings(app.db, nowMillis: 1, dayStartMinutes: 7 * 60),
      throwsArgumentError,
    );
    expect(
      () => saveSettings(app.db, nowMillis: 1, dayStartMinutes: 90),
      throwsArgumentError,
    );
    expect(
      () => saveSettings(app.db, nowMillis: 1, defaultLeadDays: -1),
      throwsArgumentError,
    );
  });

  test('a damaged presets value reads as the defaults', () async {
    await app.db.customStatement(
      "UPDATE settings SET presets = 'not json' WHERE id = 1",
    );
    expect((await read()).presetTimes, const PresetTimes());
  });
}
