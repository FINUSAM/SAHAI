import 'package:drift/drift.dart';

// Schema v1 (PRD 10, PRD_Edits E-003 and E-005, tech plan section 5).
// Moments are stored as UTC milliseconds since the epoch in INTEGER columns;
// due dates are local calendar dates as 'YYYY-MM-DD' text. Every table keeps
// created_at, updated_at and is_deleted so it is ready for sync (PRD 3).

/// All six node types in one table.
@DataClassName('NodeRow')
@TableIndex(
  name: 'nodes_parent_status_deleted',
  columns: {#parentId, #status, #isDeleted},
)
@TableIndex(name: 'nodes_snooze_until', columns: {#snoozeUntil})
class Nodes extends Table {
  TextColumn get id => text()();
  TextColumn get parentId => text().nullable()();
  TextColumn get type => text()();
  TextColumn get title => text()();
  TextColumn get notes => text().withDefault(const Constant(''))();

  /// 'todo' or 'done'; null for domains and streams.
  TextColumn get status => text().nullable()();
  IntColumn get sortOrder => integer()();
  IntColumn get snoozeUntil => integer().nullable()();
  BoolColumn get remindOnWake => boolean().withDefault(const Constant(true))();
  TextColumn get dueOn => text().nullable()();

  /// JSON: frequency, interval, days, repeat-from.
  TextColumn get recurrence => text().nullable()();
  IntColumn get leadDays => integer().nullable()();
  TextColumn get groupId => text().nullable()();
  IntColumn get completedAt => integer().nullable()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();

  /// The `deleted` event that flagged this row, so Undo restores exactly
  /// what that delete removed (E-003).
  TextColumn get deletedByEvent => text().nullable()();

  /// When true, `snooze_until` replaces a recurring item's computed show
  /// time for the current occurrence (E-005).
  BoolColumn get snoozeOverridesShow =>
      boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

@DataClassName('ContextGroupRow')
class ContextGroups extends Table {
  TextColumn get id => text()();
  TextColumn get name => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get sortOrder => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// One saved Summary position per project, stream or recurring item.
@DataClassName('SummarySlotRow')
class SummarySlots extends Table {
  TextColumn get ownerId => text()();
  TextColumn get groupId => text().nullable()();
  IntColumn get position => integer()();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {ownerId};
}

/// The activity log (PRD 9). Append-only: rows are never updated.
@DataClassName('EventRow')
@TableIndex(name: 'events_occurred_at', columns: {#occurredAt})
class Events extends Table {
  TextColumn get eventId => text()();
  TextColumn get eventType => text()();
  TextColumn get nodeId => text().nullable()();
  TextColumn get nodeType => text().nullable()();
  TextColumn get domainId => text().nullable()();
  TextColumn get groupId => text().nullable()();
  IntColumn get occurredAt => integer()();
  IntColumn get tzOffsetMinutes => integer()();
  TextColumn get payload => text().withDefault(const Constant('{}'))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {eventId};
}

@DataClassName('CaptureRow')
class Captures extends Table {
  TextColumn get id => text()();
  TextColumn get body => text().named('text')();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}

/// A single row (id = 1) of user settings. Defaults are the PRD's.
@DataClassName('SettingsRow')
class SettingsTable extends Table {
  @override
  String get tableName => 'settings';

  IntColumn get id => integer()();

  /// "Day starts at", in minutes after midnight (default 4:00 AM, PRD 7).
  IntColumn get dayStartMinutes => integer().withDefault(const Constant(240))();

  /// Custom set-aside presets as JSON; null means the PRD defaults.
  TextColumn get presets => text().nullable()();
  BoolColumn get notificationsEnabled =>
      boolean().withDefault(const Constant(true))();
  BoolColumn get exactReminders =>
      boolean().withDefault(const Constant(false))();

  /// Reminder time for recurring items, in minutes after midnight (9:00 AM).
  IntColumn get reminderMinutes => integer().withDefault(const Constant(540))();
  IntColumn get defaultLeadDays => integer().withDefault(const Constant(3))();
  BoolColumn get onboardingDone =>
      boolean().withDefault(const Constant(false))();
  BoolColumn get isDeleted => boolean().withDefault(const Constant(false))();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();

  @override
  Set<Column> get primaryKey => {id};
}
