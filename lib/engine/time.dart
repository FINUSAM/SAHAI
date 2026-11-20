// The logical day and set-aside presets (PRD 7, tech plan 4.3).
//
// Wall-clock rules such as "8 PM" or "Monday" belong to the phone's local
// time zone, so each function converts its instant with toLocal() and
// returns local DateTimes. Callers store them as UTC instants.

/// "Day starts at" when the user hasn't changed it: 4:00 AM (PRD 7).
const defaultDayStartMinutes = 4 * 60;

/// The calendar date [instant] belongs to, as local midnight. Before the
/// day-start time it still counts as the previous day, so 1:30 AM on
/// Wednesday is Tuesday night (AT-043).
DateTime logicalDate(
  DateTime instant, {
  int dayStartMinutes = defaultDayStartMinutes,
}) {
  final local = instant.toLocal();
  final minutes = local.hour * 60 + local.minute;
  final daysBack = minutes < dayStartMinutes ? 1 : 0;
  // DateTime normalises day 0 to the last day of the previous month.
  return DateTime(local.year, local.month, local.day - daysBack);
}

/// The next moment the logical day changes after [instant], when due labels
/// move on (AT-063).
DateTime nextDayStart(
  DateTime instant, {
  int dayStartMinutes = defaultDayStartMinutes,
}) {
  final day = logicalDate(instant, dayStartMinutes: dayStartMinutes);
  return DateTime(day.year, day.month, day.day + 1, 0, dayStartMinutes);
}

/// The four default set-aside presets (PRD 7). [logName] is what the
/// `set_aside` event stores (AT-059); a custom time stores [customLogName].
enum Preset {
  tonight('tonight'),
  tomorrowMorning('tomorrow_morning'),
  threeDaysLater('three_days_later'),
  nextWeek('next_week');

  const Preset(this.logName);

  final String logName;

  static const customLogName = 'custom';
}

/// A preset and the moment it wakes at.
class PresetTime {
  const PresetTime(this.preset, this.wakeAt);

  final Preset preset;

  /// Local time.
  final DateTime wakeAt;

  @override
  bool operator ==(Object other) =>
      other is PresetTime && other.preset == preset && other.wakeAt == wakeAt;

  @override
  int get hashCode => Object.hash(preset, wakeAt);

  @override
  String toString() => 'PresetTime(${preset.name}, $wakeAt)';
}

/// The time of day each preset wakes at, in minutes after midnight. Only
/// the times can be changed in Settings; the names and days stay fixed (M7
/// wireframe choice). The defaults are the PRD's.
class PresetTimes {
  const PresetTimes({
    this.tonight = defaultTonightMinutes,
    this.tomorrowMorning = defaultMorningMinutes,
    this.threeDaysLater = defaultMorningMinutes,
    this.nextWeek = defaultMorningMinutes,
  });

  static const defaultTonightMinutes = 20 * 60;
  static const defaultMorningMinutes = 8 * 60;

  final int tonight;
  final int tomorrowMorning;
  final int threeDaysLater;
  final int nextWeek;

  int of(Preset preset) => switch (preset) {
    Preset.tonight => tonight,
    Preset.tomorrowMorning => tomorrowMorning,
    Preset.threeDaysLater => threeDaysLater,
    Preset.nextWeek => nextWeek,
  };

  PresetTimes withTime(Preset preset, int minutes) => PresetTimes(
    tonight: preset == Preset.tonight ? minutes : tonight,
    tomorrowMorning: preset == Preset.tomorrowMorning
        ? minutes
        : tomorrowMorning,
    threeDaysLater: preset == Preset.threeDaysLater ? minutes : threeDaysLater,
    nextWeek: preset == Preset.nextWeek ? minutes : nextWeek,
  );

  bool get isDefault => this == const PresetTimes();

  /// Stored in the `settings.presets` column, keyed by the preset's log
  /// name so the stored form doesn't depend on Dart names.
  Map<String, int> toJson() => {
    for (final preset in Preset.values) preset.logName: of(preset),
  };

  /// Reads what [toJson] wrote. Anything missing or not a valid time of day
  /// falls back to the default, so a damaged value can never stop Set aside
  /// from working.
  factory PresetTimes.fromJson(Object? json) {
    var times = const PresetTimes();
    if (json is! Map) return times;
    for (final preset in Preset.values) {
      final value = json[preset.logName];
      if (value is int && value >= 0 && value < 24 * 60) {
        times = times.withTime(preset, value);
      }
    }
    return times;
  }

  @override
  bool operator ==(Object other) =>
      other is PresetTimes &&
      other.tonight == tonight &&
      other.tomorrowMorning == tomorrowMorning &&
      other.threeDaysLater == threeDaysLater &&
      other.nextWeek == nextWeek;

  @override
  int get hashCode =>
      Object.hash(tonight, tomorrowMorning, threeDaysLater, nextWeek);
}

/// The presets offered at [now], in menu order. Tonight is 8 PM, Tomorrow
/// morning the next logical day at 8 AM, 3 days later the logical day plus
/// three at 8 AM, and Next week the following Monday at 8 AM (AT-042), or
/// the times chosen in Settings (AT-109). Presets that are no longer in the
/// future are left out (AT-044).
List<PresetTime> presetsAt(
  DateTime now, {
  int dayStartMinutes = defaultDayStartMinutes,
  PresetTimes times = const PresetTimes(),
}) {
  final day = logicalDate(now, dayStartMinutes: dayStartMinutes);
  // Built from calendar fields rather than by adding Durations, so a
  // daylight-saving change in between still lands on the chosen time.
  DateTime at(int days, Preset preset) =>
      DateTime(day.year, day.month, day.day + days, 0, times.of(preset));

  // Tonight set earlier than the day start, such as 12:30 AM, is still
  // tonight: after midnight, on the next calendar date.
  final tonight = times.tonight < dayStartMinutes
      ? at(1, Preset.tonight)
      : at(0, Preset.tonight);
  final daysToMonday = DateTime.daysPerWeek - day.weekday + DateTime.monday;
  return [
    for (final p in [
      PresetTime(Preset.tonight, tonight),
      PresetTime(Preset.tomorrowMorning, at(1, Preset.tomorrowMorning)),
      PresetTime(Preset.threeDaysLater, at(3, Preset.threeDaysLater)),
      PresetTime(Preset.nextWeek, at(daysToMonday, Preset.nextWeek)),
    ])
      if (p.wakeAt.isAfter(now)) p,
  ];
}

/// Whether [wakeAt] can be chosen as a set-aside time at [now]: only times
/// still in the future (AT-045).
bool isValidWakeTime(DateTime wakeAt, DateTime now) => wakeAt.isAfter(now);
