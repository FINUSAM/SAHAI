// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'database.dart';

// ignore_for_file: type=lint
class $NodesTable extends Nodes with TableInfo<$NodesTable, NodeRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $NodesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _parentIdMeta = const VerificationMeta(
    'parentId',
  );
  @override
  late final GeneratedColumn<String> parentId = GeneratedColumn<String>(
    'parent_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _typeMeta = const VerificationMeta('type');
  @override
  late final GeneratedColumn<String> type = GeneratedColumn<String>(
    'type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _notesMeta = const VerificationMeta('notes');
  @override
  late final GeneratedColumn<String> notes = GeneratedColumn<String>(
    'notes',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant(''),
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _snoozeUntilMeta = const VerificationMeta(
    'snoozeUntil',
  );
  @override
  late final GeneratedColumn<int> snoozeUntil = GeneratedColumn<int>(
    'snooze_until',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _remindOnWakeMeta = const VerificationMeta(
    'remindOnWake',
  );
  @override
  late final GeneratedColumn<bool> remindOnWake = GeneratedColumn<bool>(
    'remind_on_wake',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("remind_on_wake" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _dueOnMeta = const VerificationMeta('dueOn');
  @override
  late final GeneratedColumn<String> dueOn = GeneratedColumn<String>(
    'due_on',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _recurrenceMeta = const VerificationMeta(
    'recurrence',
  );
  @override
  late final GeneratedColumn<String> recurrence = GeneratedColumn<String>(
    'recurrence',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _leadDaysMeta = const VerificationMeta(
    'leadDays',
  );
  @override
  late final GeneratedColumn<int> leadDays = GeneratedColumn<int>(
    'lead_days',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _completedAtMeta = const VerificationMeta(
    'completedAt',
  );
  @override
  late final GeneratedColumn<int> completedAt = GeneratedColumn<int>(
    'completed_at',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _deletedByEventMeta = const VerificationMeta(
    'deletedByEvent',
  );
  @override
  late final GeneratedColumn<String> deletedByEvent = GeneratedColumn<String>(
    'deleted_by_event',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _snoozeOverridesShowMeta =
      const VerificationMeta('snoozeOverridesShow');
  @override
  late final GeneratedColumn<bool> snoozeOverridesShow = GeneratedColumn<bool>(
    'snooze_overrides_show',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("snooze_overrides_show" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    parentId,
    type,
    title,
    notes,
    status,
    sortOrder,
    snoozeUntil,
    remindOnWake,
    dueOn,
    recurrence,
    leadDays,
    groupId,
    completedAt,
    isDeleted,
    deletedByEvent,
    snoozeOverridesShow,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'nodes';
  @override
  VerificationContext validateIntegrity(
    Insertable<NodeRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('parent_id')) {
      context.handle(
        _parentIdMeta,
        parentId.isAcceptableOrUnknown(data['parent_id']!, _parentIdMeta),
      );
    }
    if (data.containsKey('type')) {
      context.handle(
        _typeMeta,
        type.isAcceptableOrUnknown(data['type']!, _typeMeta),
      );
    } else if (isInserting) {
      context.missing(_typeMeta);
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('notes')) {
      context.handle(
        _notesMeta,
        notes.isAcceptableOrUnknown(data['notes']!, _notesMeta),
      );
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('snooze_until')) {
      context.handle(
        _snoozeUntilMeta,
        snoozeUntil.isAcceptableOrUnknown(
          data['snooze_until']!,
          _snoozeUntilMeta,
        ),
      );
    }
    if (data.containsKey('remind_on_wake')) {
      context.handle(
        _remindOnWakeMeta,
        remindOnWake.isAcceptableOrUnknown(
          data['remind_on_wake']!,
          _remindOnWakeMeta,
        ),
      );
    }
    if (data.containsKey('due_on')) {
      context.handle(
        _dueOnMeta,
        dueOn.isAcceptableOrUnknown(data['due_on']!, _dueOnMeta),
      );
    }
    if (data.containsKey('recurrence')) {
      context.handle(
        _recurrenceMeta,
        recurrence.isAcceptableOrUnknown(data['recurrence']!, _recurrenceMeta),
      );
    }
    if (data.containsKey('lead_days')) {
      context.handle(
        _leadDaysMeta,
        leadDays.isAcceptableOrUnknown(data['lead_days']!, _leadDaysMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('completed_at')) {
      context.handle(
        _completedAtMeta,
        completedAt.isAcceptableOrUnknown(
          data['completed_at']!,
          _completedAtMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('deleted_by_event')) {
      context.handle(
        _deletedByEventMeta,
        deletedByEvent.isAcceptableOrUnknown(
          data['deleted_by_event']!,
          _deletedByEventMeta,
        ),
      );
    }
    if (data.containsKey('snooze_overrides_show')) {
      context.handle(
        _snoozeOverridesShowMeta,
        snoozeOverridesShow.isAcceptableOrUnknown(
          data['snooze_overrides_show']!,
          _snoozeOverridesShowMeta,
        ),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  NodeRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return NodeRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      parentId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}parent_id'],
      ),
      type: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}type'],
      )!,
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      notes: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}notes'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      snoozeUntil: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}snooze_until'],
      ),
      remindOnWake: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}remind_on_wake'],
      )!,
      dueOn: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}due_on'],
      ),
      recurrence: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}recurrence'],
      ),
      leadDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}lead_days'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      completedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}completed_at'],
      ),
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      deletedByEvent: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}deleted_by_event'],
      ),
      snoozeOverridesShow: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}snooze_overrides_show'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $NodesTable createAlias(String alias) {
    return $NodesTable(attachedDatabase, alias);
  }
}

class NodeRow extends DataClass implements Insertable<NodeRow> {
  final String id;
  final String? parentId;
  final String type;
  final String title;
  final String notes;

  /// 'todo' or 'done'; null for domains and streams.
  final String? status;
  final int sortOrder;
  final int? snoozeUntil;
  final bool remindOnWake;
  final String? dueOn;

  /// JSON: frequency, interval, days, repeat-from.
  final String? recurrence;
  final int? leadDays;
  final String? groupId;
  final int? completedAt;
  final bool isDeleted;

  /// The `deleted` event that flagged this row, so Undo restores exactly
  /// what that delete removed (E-003).
  final String? deletedByEvent;

  /// When true, `snooze_until` replaces a recurring item's computed show
  /// time for the current occurrence (E-005).
  final bool snoozeOverridesShow;
  final int createdAt;
  final int updatedAt;
  const NodeRow({
    required this.id,
    this.parentId,
    required this.type,
    required this.title,
    required this.notes,
    this.status,
    required this.sortOrder,
    this.snoozeUntil,
    required this.remindOnWake,
    this.dueOn,
    this.recurrence,
    this.leadDays,
    this.groupId,
    this.completedAt,
    required this.isDeleted,
    this.deletedByEvent,
    required this.snoozeOverridesShow,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    if (!nullToAbsent || parentId != null) {
      map['parent_id'] = Variable<String>(parentId);
    }
    map['type'] = Variable<String>(type);
    map['title'] = Variable<String>(title);
    map['notes'] = Variable<String>(notes);
    if (!nullToAbsent || status != null) {
      map['status'] = Variable<String>(status);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    if (!nullToAbsent || snoozeUntil != null) {
      map['snooze_until'] = Variable<int>(snoozeUntil);
    }
    map['remind_on_wake'] = Variable<bool>(remindOnWake);
    if (!nullToAbsent || dueOn != null) {
      map['due_on'] = Variable<String>(dueOn);
    }
    if (!nullToAbsent || recurrence != null) {
      map['recurrence'] = Variable<String>(recurrence);
    }
    if (!nullToAbsent || leadDays != null) {
      map['lead_days'] = Variable<int>(leadDays);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    if (!nullToAbsent || completedAt != null) {
      map['completed_at'] = Variable<int>(completedAt);
    }
    map['is_deleted'] = Variable<bool>(isDeleted);
    if (!nullToAbsent || deletedByEvent != null) {
      map['deleted_by_event'] = Variable<String>(deletedByEvent);
    }
    map['snooze_overrides_show'] = Variable<bool>(snoozeOverridesShow);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  NodesCompanion toCompanion(bool nullToAbsent) {
    return NodesCompanion(
      id: Value(id),
      parentId: parentId == null && nullToAbsent
          ? const Value.absent()
          : Value(parentId),
      type: Value(type),
      title: Value(title),
      notes: Value(notes),
      status: status == null && nullToAbsent
          ? const Value.absent()
          : Value(status),
      sortOrder: Value(sortOrder),
      snoozeUntil: snoozeUntil == null && nullToAbsent
          ? const Value.absent()
          : Value(snoozeUntil),
      remindOnWake: Value(remindOnWake),
      dueOn: dueOn == null && nullToAbsent
          ? const Value.absent()
          : Value(dueOn),
      recurrence: recurrence == null && nullToAbsent
          ? const Value.absent()
          : Value(recurrence),
      leadDays: leadDays == null && nullToAbsent
          ? const Value.absent()
          : Value(leadDays),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      completedAt: completedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(completedAt),
      isDeleted: Value(isDeleted),
      deletedByEvent: deletedByEvent == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedByEvent),
      snoozeOverridesShow: Value(snoozeOverridesShow),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory NodeRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return NodeRow(
      id: serializer.fromJson<String>(json['id']),
      parentId: serializer.fromJson<String?>(json['parentId']),
      type: serializer.fromJson<String>(json['type']),
      title: serializer.fromJson<String>(json['title']),
      notes: serializer.fromJson<String>(json['notes']),
      status: serializer.fromJson<String?>(json['status']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      snoozeUntil: serializer.fromJson<int?>(json['snoozeUntil']),
      remindOnWake: serializer.fromJson<bool>(json['remindOnWake']),
      dueOn: serializer.fromJson<String?>(json['dueOn']),
      recurrence: serializer.fromJson<String?>(json['recurrence']),
      leadDays: serializer.fromJson<int?>(json['leadDays']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      completedAt: serializer.fromJson<int?>(json['completedAt']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      deletedByEvent: serializer.fromJson<String?>(json['deletedByEvent']),
      snoozeOverridesShow: serializer.fromJson<bool>(
        json['snoozeOverridesShow'],
      ),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'parentId': serializer.toJson<String?>(parentId),
      'type': serializer.toJson<String>(type),
      'title': serializer.toJson<String>(title),
      'notes': serializer.toJson<String>(notes),
      'status': serializer.toJson<String?>(status),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'snoozeUntil': serializer.toJson<int?>(snoozeUntil),
      'remindOnWake': serializer.toJson<bool>(remindOnWake),
      'dueOn': serializer.toJson<String?>(dueOn),
      'recurrence': serializer.toJson<String?>(recurrence),
      'leadDays': serializer.toJson<int?>(leadDays),
      'groupId': serializer.toJson<String?>(groupId),
      'completedAt': serializer.toJson<int?>(completedAt),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'deletedByEvent': serializer.toJson<String?>(deletedByEvent),
      'snoozeOverridesShow': serializer.toJson<bool>(snoozeOverridesShow),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  NodeRow copyWith({
    String? id,
    Value<String?> parentId = const Value.absent(),
    String? type,
    String? title,
    String? notes,
    Value<String?> status = const Value.absent(),
    int? sortOrder,
    Value<int?> snoozeUntil = const Value.absent(),
    bool? remindOnWake,
    Value<String?> dueOn = const Value.absent(),
    Value<String?> recurrence = const Value.absent(),
    Value<int?> leadDays = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    Value<int?> completedAt = const Value.absent(),
    bool? isDeleted,
    Value<String?> deletedByEvent = const Value.absent(),
    bool? snoozeOverridesShow,
    int? createdAt,
    int? updatedAt,
  }) => NodeRow(
    id: id ?? this.id,
    parentId: parentId.present ? parentId.value : this.parentId,
    type: type ?? this.type,
    title: title ?? this.title,
    notes: notes ?? this.notes,
    status: status.present ? status.value : this.status,
    sortOrder: sortOrder ?? this.sortOrder,
    snoozeUntil: snoozeUntil.present ? snoozeUntil.value : this.snoozeUntil,
    remindOnWake: remindOnWake ?? this.remindOnWake,
    dueOn: dueOn.present ? dueOn.value : this.dueOn,
    recurrence: recurrence.present ? recurrence.value : this.recurrence,
    leadDays: leadDays.present ? leadDays.value : this.leadDays,
    groupId: groupId.present ? groupId.value : this.groupId,
    completedAt: completedAt.present ? completedAt.value : this.completedAt,
    isDeleted: isDeleted ?? this.isDeleted,
    deletedByEvent: deletedByEvent.present
        ? deletedByEvent.value
        : this.deletedByEvent,
    snoozeOverridesShow: snoozeOverridesShow ?? this.snoozeOverridesShow,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  NodeRow copyWithCompanion(NodesCompanion data) {
    return NodeRow(
      id: data.id.present ? data.id.value : this.id,
      parentId: data.parentId.present ? data.parentId.value : this.parentId,
      type: data.type.present ? data.type.value : this.type,
      title: data.title.present ? data.title.value : this.title,
      notes: data.notes.present ? data.notes.value : this.notes,
      status: data.status.present ? data.status.value : this.status,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      snoozeUntil: data.snoozeUntil.present
          ? data.snoozeUntil.value
          : this.snoozeUntil,
      remindOnWake: data.remindOnWake.present
          ? data.remindOnWake.value
          : this.remindOnWake,
      dueOn: data.dueOn.present ? data.dueOn.value : this.dueOn,
      recurrence: data.recurrence.present
          ? data.recurrence.value
          : this.recurrence,
      leadDays: data.leadDays.present ? data.leadDays.value : this.leadDays,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      completedAt: data.completedAt.present
          ? data.completedAt.value
          : this.completedAt,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      deletedByEvent: data.deletedByEvent.present
          ? data.deletedByEvent.value
          : this.deletedByEvent,
      snoozeOverridesShow: data.snoozeOverridesShow.present
          ? data.snoozeOverridesShow.value
          : this.snoozeOverridesShow,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('NodeRow(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('remindOnWake: $remindOnWake, ')
          ..write('dueOn: $dueOn, ')
          ..write('recurrence: $recurrence, ')
          ..write('leadDays: $leadDays, ')
          ..write('groupId: $groupId, ')
          ..write('completedAt: $completedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedByEvent: $deletedByEvent, ')
          ..write('snoozeOverridesShow: $snoozeOverridesShow, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    parentId,
    type,
    title,
    notes,
    status,
    sortOrder,
    snoozeUntil,
    remindOnWake,
    dueOn,
    recurrence,
    leadDays,
    groupId,
    completedAt,
    isDeleted,
    deletedByEvent,
    snoozeOverridesShow,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is NodeRow &&
          other.id == this.id &&
          other.parentId == this.parentId &&
          other.type == this.type &&
          other.title == this.title &&
          other.notes == this.notes &&
          other.status == this.status &&
          other.sortOrder == this.sortOrder &&
          other.snoozeUntil == this.snoozeUntil &&
          other.remindOnWake == this.remindOnWake &&
          other.dueOn == this.dueOn &&
          other.recurrence == this.recurrence &&
          other.leadDays == this.leadDays &&
          other.groupId == this.groupId &&
          other.completedAt == this.completedAt &&
          other.isDeleted == this.isDeleted &&
          other.deletedByEvent == this.deletedByEvent &&
          other.snoozeOverridesShow == this.snoozeOverridesShow &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class NodesCompanion extends UpdateCompanion<NodeRow> {
  final Value<String> id;
  final Value<String?> parentId;
  final Value<String> type;
  final Value<String> title;
  final Value<String> notes;
  final Value<String?> status;
  final Value<int> sortOrder;
  final Value<int?> snoozeUntil;
  final Value<bool> remindOnWake;
  final Value<String?> dueOn;
  final Value<String?> recurrence;
  final Value<int?> leadDays;
  final Value<String?> groupId;
  final Value<int?> completedAt;
  final Value<bool> isDeleted;
  final Value<String?> deletedByEvent;
  final Value<bool> snoozeOverridesShow;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const NodesCompanion({
    this.id = const Value.absent(),
    this.parentId = const Value.absent(),
    this.type = const Value.absent(),
    this.title = const Value.absent(),
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.snoozeUntil = const Value.absent(),
    this.remindOnWake = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.leadDays = const Value.absent(),
    this.groupId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedByEvent = const Value.absent(),
    this.snoozeOverridesShow = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  NodesCompanion.insert({
    required String id,
    this.parentId = const Value.absent(),
    required String type,
    required String title,
    this.notes = const Value.absent(),
    this.status = const Value.absent(),
    required int sortOrder,
    this.snoozeUntil = const Value.absent(),
    this.remindOnWake = const Value.absent(),
    this.dueOn = const Value.absent(),
    this.recurrence = const Value.absent(),
    this.leadDays = const Value.absent(),
    this.groupId = const Value.absent(),
    this.completedAt = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.deletedByEvent = const Value.absent(),
    this.snoozeOverridesShow = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       type = Value(type),
       title = Value(title),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<NodeRow> custom({
    Expression<String>? id,
    Expression<String>? parentId,
    Expression<String>? type,
    Expression<String>? title,
    Expression<String>? notes,
    Expression<String>? status,
    Expression<int>? sortOrder,
    Expression<int>? snoozeUntil,
    Expression<bool>? remindOnWake,
    Expression<String>? dueOn,
    Expression<String>? recurrence,
    Expression<int>? leadDays,
    Expression<String>? groupId,
    Expression<int>? completedAt,
    Expression<bool>? isDeleted,
    Expression<String>? deletedByEvent,
    Expression<bool>? snoozeOverridesShow,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (parentId != null) 'parent_id': parentId,
      if (type != null) 'type': type,
      if (title != null) 'title': title,
      if (notes != null) 'notes': notes,
      if (status != null) 'status': status,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (snoozeUntil != null) 'snooze_until': snoozeUntil,
      if (remindOnWake != null) 'remind_on_wake': remindOnWake,
      if (dueOn != null) 'due_on': dueOn,
      if (recurrence != null) 'recurrence': recurrence,
      if (leadDays != null) 'lead_days': leadDays,
      if (groupId != null) 'group_id': groupId,
      if (completedAt != null) 'completed_at': completedAt,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (deletedByEvent != null) 'deleted_by_event': deletedByEvent,
      if (snoozeOverridesShow != null)
        'snooze_overrides_show': snoozeOverridesShow,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  NodesCompanion copyWith({
    Value<String>? id,
    Value<String?>? parentId,
    Value<String>? type,
    Value<String>? title,
    Value<String>? notes,
    Value<String?>? status,
    Value<int>? sortOrder,
    Value<int?>? snoozeUntil,
    Value<bool>? remindOnWake,
    Value<String?>? dueOn,
    Value<String?>? recurrence,
    Value<int?>? leadDays,
    Value<String?>? groupId,
    Value<int?>? completedAt,
    Value<bool>? isDeleted,
    Value<String?>? deletedByEvent,
    Value<bool>? snoozeOverridesShow,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return NodesCompanion(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      type: type ?? this.type,
      title: title ?? this.title,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      sortOrder: sortOrder ?? this.sortOrder,
      snoozeUntil: snoozeUntil ?? this.snoozeUntil,
      remindOnWake: remindOnWake ?? this.remindOnWake,
      dueOn: dueOn ?? this.dueOn,
      recurrence: recurrence ?? this.recurrence,
      leadDays: leadDays ?? this.leadDays,
      groupId: groupId ?? this.groupId,
      completedAt: completedAt ?? this.completedAt,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedByEvent: deletedByEvent ?? this.deletedByEvent,
      snoozeOverridesShow: snoozeOverridesShow ?? this.snoozeOverridesShow,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (parentId.present) {
      map['parent_id'] = Variable<String>(parentId.value);
    }
    if (type.present) {
      map['type'] = Variable<String>(type.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (notes.present) {
      map['notes'] = Variable<String>(notes.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (snoozeUntil.present) {
      map['snooze_until'] = Variable<int>(snoozeUntil.value);
    }
    if (remindOnWake.present) {
      map['remind_on_wake'] = Variable<bool>(remindOnWake.value);
    }
    if (dueOn.present) {
      map['due_on'] = Variable<String>(dueOn.value);
    }
    if (recurrence.present) {
      map['recurrence'] = Variable<String>(recurrence.value);
    }
    if (leadDays.present) {
      map['lead_days'] = Variable<int>(leadDays.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (completedAt.present) {
      map['completed_at'] = Variable<int>(completedAt.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (deletedByEvent.present) {
      map['deleted_by_event'] = Variable<String>(deletedByEvent.value);
    }
    if (snoozeOverridesShow.present) {
      map['snooze_overrides_show'] = Variable<bool>(snoozeOverridesShow.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('NodesCompanion(')
          ..write('id: $id, ')
          ..write('parentId: $parentId, ')
          ..write('type: $type, ')
          ..write('title: $title, ')
          ..write('notes: $notes, ')
          ..write('status: $status, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('snoozeUntil: $snoozeUntil, ')
          ..write('remindOnWake: $remindOnWake, ')
          ..write('dueOn: $dueOn, ')
          ..write('recurrence: $recurrence, ')
          ..write('leadDays: $leadDays, ')
          ..write('groupId: $groupId, ')
          ..write('completedAt: $completedAt, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('deletedByEvent: $deletedByEvent, ')
          ..write('snoozeOverridesShow: $snoozeOverridesShow, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ContextGroupsTable extends ContextGroups
    with TableInfo<$ContextGroupsTable, ContextGroupRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ContextGroupsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nameMeta = const VerificationMeta('name');
  @override
  late final GeneratedColumn<String> name = GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _iconMeta = const VerificationMeta('icon');
  @override
  late final GeneratedColumn<String> icon = GeneratedColumn<String>(
    'icon',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sortOrderMeta = const VerificationMeta(
    'sortOrder',
  );
  @override
  late final GeneratedColumn<int> sortOrder = GeneratedColumn<int>(
    'sort_order',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    name,
    icon,
    sortOrder,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'context_groups';
  @override
  VerificationContext validateIntegrity(
    Insertable<ContextGroupRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('icon')) {
      context.handle(
        _iconMeta,
        icon.isAcceptableOrUnknown(data['icon']!, _iconMeta),
      );
    }
    if (data.containsKey('sort_order')) {
      context.handle(
        _sortOrderMeta,
        sortOrder.isAcceptableOrUnknown(data['sort_order']!, _sortOrderMeta),
      );
    } else if (isInserting) {
      context.missing(_sortOrderMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  ContextGroupRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ContextGroupRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      icon: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}icon'],
      ),
      sortOrder: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sort_order'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $ContextGroupsTable createAlias(String alias) {
    return $ContextGroupsTable(attachedDatabase, alias);
  }
}

class ContextGroupRow extends DataClass implements Insertable<ContextGroupRow> {
  final String id;
  final String name;
  final String? icon;
  final int sortOrder;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  const ContextGroupRow({
    required this.id,
    required this.name,
    this.icon,
    required this.sortOrder,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['name'] = Variable<String>(name);
    if (!nullToAbsent || icon != null) {
      map['icon'] = Variable<String>(icon);
    }
    map['sort_order'] = Variable<int>(sortOrder);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  ContextGroupsCompanion toCompanion(bool nullToAbsent) {
    return ContextGroupsCompanion(
      id: Value(id),
      name: Value(name),
      icon: icon == null && nullToAbsent ? const Value.absent() : Value(icon),
      sortOrder: Value(sortOrder),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory ContextGroupRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ContextGroupRow(
      id: serializer.fromJson<String>(json['id']),
      name: serializer.fromJson<String>(json['name']),
      icon: serializer.fromJson<String?>(json['icon']),
      sortOrder: serializer.fromJson<int>(json['sortOrder']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'name': serializer.toJson<String>(name),
      'icon': serializer.toJson<String?>(icon),
      'sortOrder': serializer.toJson<int>(sortOrder),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  ContextGroupRow copyWith({
    String? id,
    String? name,
    Value<String?> icon = const Value.absent(),
    int? sortOrder,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) => ContextGroupRow(
    id: id ?? this.id,
    name: name ?? this.name,
    icon: icon.present ? icon.value : this.icon,
    sortOrder: sortOrder ?? this.sortOrder,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  ContextGroupRow copyWithCompanion(ContextGroupsCompanion data) {
    return ContextGroupRow(
      id: data.id.present ? data.id.value : this.id,
      name: data.name.present ? data.name.value : this.name,
      icon: data.icon.present ? data.icon.value : this.icon,
      sortOrder: data.sortOrder.present ? data.sortOrder.value : this.sortOrder,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ContextGroupRow(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(id, name, icon, sortOrder, isDeleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ContextGroupRow &&
          other.id == this.id &&
          other.name == this.name &&
          other.icon == this.icon &&
          other.sortOrder == this.sortOrder &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class ContextGroupsCompanion extends UpdateCompanion<ContextGroupRow> {
  final Value<String> id;
  final Value<String> name;
  final Value<String?> icon;
  final Value<int> sortOrder;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const ContextGroupsCompanion({
    this.id = const Value.absent(),
    this.name = const Value.absent(),
    this.icon = const Value.absent(),
    this.sortOrder = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ContextGroupsCompanion.insert({
    required String id,
    required String name,
    this.icon = const Value.absent(),
    required int sortOrder,
    this.isDeleted = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       name = Value(name),
       sortOrder = Value(sortOrder),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<ContextGroupRow> custom({
    Expression<String>? id,
    Expression<String>? name,
    Expression<String>? icon,
    Expression<int>? sortOrder,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (icon != null) 'icon': icon,
      if (sortOrder != null) 'sort_order': sortOrder,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ContextGroupsCompanion copyWith({
    Value<String>? id,
    Value<String>? name,
    Value<String?>? icon,
    Value<int>? sortOrder,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return ContextGroupsCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      sortOrder: sortOrder ?? this.sortOrder,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = Variable<String>(name.value);
    }
    if (icon.present) {
      map['icon'] = Variable<String>(icon.value);
    }
    if (sortOrder.present) {
      map['sort_order'] = Variable<int>(sortOrder.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ContextGroupsCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('icon: $icon, ')
          ..write('sortOrder: $sortOrder, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SummarySlotsTable extends SummarySlots
    with TableInfo<$SummarySlotsTable, SummarySlotRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SummarySlotsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _ownerIdMeta = const VerificationMeta(
    'ownerId',
  );
  @override
  late final GeneratedColumn<String> ownerId = GeneratedColumn<String>(
    'owner_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    ownerId,
    groupId,
    position,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'summary_slots';
  @override
  VerificationContext validateIntegrity(
    Insertable<SummarySlotRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('owner_id')) {
      context.handle(
        _ownerIdMeta,
        ownerId.isAcceptableOrUnknown(data['owner_id']!, _ownerIdMeta),
      );
    } else if (isInserting) {
      context.missing(_ownerIdMeta);
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    } else if (isInserting) {
      context.missing(_positionMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {ownerId};
  @override
  SummarySlotRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SummarySlotRow(
      ownerId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}owner_id'],
      )!,
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SummarySlotsTable createAlias(String alias) {
    return $SummarySlotsTable(attachedDatabase, alias);
  }
}

class SummarySlotRow extends DataClass implements Insertable<SummarySlotRow> {
  final String ownerId;
  final String? groupId;
  final int position;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  const SummarySlotRow({
    required this.ownerId,
    this.groupId,
    required this.position,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['owner_id'] = Variable<String>(ownerId);
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['position'] = Variable<int>(position);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SummarySlotsCompanion toCompanion(bool nullToAbsent) {
    return SummarySlotsCompanion(
      ownerId: Value(ownerId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      position: Value(position),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SummarySlotRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SummarySlotRow(
      ownerId: serializer.fromJson<String>(json['ownerId']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      position: serializer.fromJson<int>(json['position']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'ownerId': serializer.toJson<String>(ownerId),
      'groupId': serializer.toJson<String?>(groupId),
      'position': serializer.toJson<int>(position),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SummarySlotRow copyWith({
    String? ownerId,
    Value<String?> groupId = const Value.absent(),
    int? position,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) => SummarySlotRow(
    ownerId: ownerId ?? this.ownerId,
    groupId: groupId.present ? groupId.value : this.groupId,
    position: position ?? this.position,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SummarySlotRow copyWithCompanion(SummarySlotsCompanion data) {
    return SummarySlotRow(
      ownerId: data.ownerId.present ? data.ownerId.value : this.ownerId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      position: data.position.present ? data.position.value : this.position,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SummarySlotRow(')
          ..write('ownerId: $ownerId, ')
          ..write('groupId: $groupId, ')
          ..write('position: $position, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode =>
      Object.hash(ownerId, groupId, position, isDeleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SummarySlotRow &&
          other.ownerId == this.ownerId &&
          other.groupId == this.groupId &&
          other.position == this.position &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SummarySlotsCompanion extends UpdateCompanion<SummarySlotRow> {
  final Value<String> ownerId;
  final Value<String?> groupId;
  final Value<int> position;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const SummarySlotsCompanion({
    this.ownerId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.position = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  SummarySlotsCompanion.insert({
    required String ownerId,
    this.groupId = const Value.absent(),
    required int position,
    this.isDeleted = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : ownerId = Value(ownerId),
       position = Value(position),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SummarySlotRow> custom({
    Expression<String>? ownerId,
    Expression<String>? groupId,
    Expression<int>? position,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (ownerId != null) 'owner_id': ownerId,
      if (groupId != null) 'group_id': groupId,
      if (position != null) 'position': position,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  SummarySlotsCompanion copyWith({
    Value<String>? ownerId,
    Value<String?>? groupId,
    Value<int>? position,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return SummarySlotsCompanion(
      ownerId: ownerId ?? this.ownerId,
      groupId: groupId ?? this.groupId,
      position: position ?? this.position,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (ownerId.present) {
      map['owner_id'] = Variable<String>(ownerId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SummarySlotsCompanion(')
          ..write('ownerId: $ownerId, ')
          ..write('groupId: $groupId, ')
          ..write('position: $position, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $EventsTable extends Events with TableInfo<$EventsTable, EventRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $EventsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _eventIdMeta = const VerificationMeta(
    'eventId',
  );
  @override
  late final GeneratedColumn<String> eventId = GeneratedColumn<String>(
    'event_id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _eventTypeMeta = const VerificationMeta(
    'eventType',
  );
  @override
  late final GeneratedColumn<String> eventType = GeneratedColumn<String>(
    'event_type',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _nodeIdMeta = const VerificationMeta('nodeId');
  @override
  late final GeneratedColumn<String> nodeId = GeneratedColumn<String>(
    'node_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _nodeTypeMeta = const VerificationMeta(
    'nodeType',
  );
  @override
  late final GeneratedColumn<String> nodeType = GeneratedColumn<String>(
    'node_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _domainIdMeta = const VerificationMeta(
    'domainId',
  );
  @override
  late final GeneratedColumn<String> domainId = GeneratedColumn<String>(
    'domain_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _groupIdMeta = const VerificationMeta(
    'groupId',
  );
  @override
  late final GeneratedColumn<String> groupId = GeneratedColumn<String>(
    'group_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _occurredAtMeta = const VerificationMeta(
    'occurredAt',
  );
  @override
  late final GeneratedColumn<int> occurredAt = GeneratedColumn<int>(
    'occurred_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _tzOffsetMinutesMeta = const VerificationMeta(
    'tzOffsetMinutes',
  );
  @override
  late final GeneratedColumn<int> tzOffsetMinutes = GeneratedColumn<int>(
    'tz_offset_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _payloadMeta = const VerificationMeta(
    'payload',
  );
  @override
  late final GeneratedColumn<String> payload = GeneratedColumn<String>(
    'payload',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const Constant('{}'),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    eventId,
    eventType,
    nodeId,
    nodeType,
    domainId,
    groupId,
    occurredAt,
    tzOffsetMinutes,
    payload,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'events';
  @override
  VerificationContext validateIntegrity(
    Insertable<EventRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('event_id')) {
      context.handle(
        _eventIdMeta,
        eventId.isAcceptableOrUnknown(data['event_id']!, _eventIdMeta),
      );
    } else if (isInserting) {
      context.missing(_eventIdMeta);
    }
    if (data.containsKey('event_type')) {
      context.handle(
        _eventTypeMeta,
        eventType.isAcceptableOrUnknown(data['event_type']!, _eventTypeMeta),
      );
    } else if (isInserting) {
      context.missing(_eventTypeMeta);
    }
    if (data.containsKey('node_id')) {
      context.handle(
        _nodeIdMeta,
        nodeId.isAcceptableOrUnknown(data['node_id']!, _nodeIdMeta),
      );
    }
    if (data.containsKey('node_type')) {
      context.handle(
        _nodeTypeMeta,
        nodeType.isAcceptableOrUnknown(data['node_type']!, _nodeTypeMeta),
      );
    }
    if (data.containsKey('domain_id')) {
      context.handle(
        _domainIdMeta,
        domainId.isAcceptableOrUnknown(data['domain_id']!, _domainIdMeta),
      );
    }
    if (data.containsKey('group_id')) {
      context.handle(
        _groupIdMeta,
        groupId.isAcceptableOrUnknown(data['group_id']!, _groupIdMeta),
      );
    }
    if (data.containsKey('occurred_at')) {
      context.handle(
        _occurredAtMeta,
        occurredAt.isAcceptableOrUnknown(data['occurred_at']!, _occurredAtMeta),
      );
    } else if (isInserting) {
      context.missing(_occurredAtMeta);
    }
    if (data.containsKey('tz_offset_minutes')) {
      context.handle(
        _tzOffsetMinutesMeta,
        tzOffsetMinutes.isAcceptableOrUnknown(
          data['tz_offset_minutes']!,
          _tzOffsetMinutesMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_tzOffsetMinutesMeta);
    }
    if (data.containsKey('payload')) {
      context.handle(
        _payloadMeta,
        payload.isAcceptableOrUnknown(data['payload']!, _payloadMeta),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {eventId};
  @override
  EventRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return EventRow(
      eventId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_id'],
      )!,
      eventType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}event_type'],
      )!,
      nodeId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_id'],
      ),
      nodeType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}node_type'],
      ),
      domainId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}domain_id'],
      ),
      groupId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}group_id'],
      ),
      occurredAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}occurred_at'],
      )!,
      tzOffsetMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}tz_offset_minutes'],
      )!,
      payload: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}payload'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $EventsTable createAlias(String alias) {
    return $EventsTable(attachedDatabase, alias);
  }
}

class EventRow extends DataClass implements Insertable<EventRow> {
  final String eventId;
  final String eventType;
  final String? nodeId;
  final String? nodeType;
  final String? domainId;
  final String? groupId;
  final int occurredAt;
  final int tzOffsetMinutes;
  final String payload;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  const EventRow({
    required this.eventId,
    required this.eventType,
    this.nodeId,
    this.nodeType,
    this.domainId,
    this.groupId,
    required this.occurredAt,
    required this.tzOffsetMinutes,
    required this.payload,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['event_id'] = Variable<String>(eventId);
    map['event_type'] = Variable<String>(eventType);
    if (!nullToAbsent || nodeId != null) {
      map['node_id'] = Variable<String>(nodeId);
    }
    if (!nullToAbsent || nodeType != null) {
      map['node_type'] = Variable<String>(nodeType);
    }
    if (!nullToAbsent || domainId != null) {
      map['domain_id'] = Variable<String>(domainId);
    }
    if (!nullToAbsent || groupId != null) {
      map['group_id'] = Variable<String>(groupId);
    }
    map['occurred_at'] = Variable<int>(occurredAt);
    map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes);
    map['payload'] = Variable<String>(payload);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  EventsCompanion toCompanion(bool nullToAbsent) {
    return EventsCompanion(
      eventId: Value(eventId),
      eventType: Value(eventType),
      nodeId: nodeId == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeId),
      nodeType: nodeType == null && nullToAbsent
          ? const Value.absent()
          : Value(nodeType),
      domainId: domainId == null && nullToAbsent
          ? const Value.absent()
          : Value(domainId),
      groupId: groupId == null && nullToAbsent
          ? const Value.absent()
          : Value(groupId),
      occurredAt: Value(occurredAt),
      tzOffsetMinutes: Value(tzOffsetMinutes),
      payload: Value(payload),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory EventRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return EventRow(
      eventId: serializer.fromJson<String>(json['eventId']),
      eventType: serializer.fromJson<String>(json['eventType']),
      nodeId: serializer.fromJson<String?>(json['nodeId']),
      nodeType: serializer.fromJson<String?>(json['nodeType']),
      domainId: serializer.fromJson<String?>(json['domainId']),
      groupId: serializer.fromJson<String?>(json['groupId']),
      occurredAt: serializer.fromJson<int>(json['occurredAt']),
      tzOffsetMinutes: serializer.fromJson<int>(json['tzOffsetMinutes']),
      payload: serializer.fromJson<String>(json['payload']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'eventId': serializer.toJson<String>(eventId),
      'eventType': serializer.toJson<String>(eventType),
      'nodeId': serializer.toJson<String?>(nodeId),
      'nodeType': serializer.toJson<String?>(nodeType),
      'domainId': serializer.toJson<String?>(domainId),
      'groupId': serializer.toJson<String?>(groupId),
      'occurredAt': serializer.toJson<int>(occurredAt),
      'tzOffsetMinutes': serializer.toJson<int>(tzOffsetMinutes),
      'payload': serializer.toJson<String>(payload),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  EventRow copyWith({
    String? eventId,
    String? eventType,
    Value<String?> nodeId = const Value.absent(),
    Value<String?> nodeType = const Value.absent(),
    Value<String?> domainId = const Value.absent(),
    Value<String?> groupId = const Value.absent(),
    int? occurredAt,
    int? tzOffsetMinutes,
    String? payload,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) => EventRow(
    eventId: eventId ?? this.eventId,
    eventType: eventType ?? this.eventType,
    nodeId: nodeId.present ? nodeId.value : this.nodeId,
    nodeType: nodeType.present ? nodeType.value : this.nodeType,
    domainId: domainId.present ? domainId.value : this.domainId,
    groupId: groupId.present ? groupId.value : this.groupId,
    occurredAt: occurredAt ?? this.occurredAt,
    tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
    payload: payload ?? this.payload,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  EventRow copyWithCompanion(EventsCompanion data) {
    return EventRow(
      eventId: data.eventId.present ? data.eventId.value : this.eventId,
      eventType: data.eventType.present ? data.eventType.value : this.eventType,
      nodeId: data.nodeId.present ? data.nodeId.value : this.nodeId,
      nodeType: data.nodeType.present ? data.nodeType.value : this.nodeType,
      domainId: data.domainId.present ? data.domainId.value : this.domainId,
      groupId: data.groupId.present ? data.groupId.value : this.groupId,
      occurredAt: data.occurredAt.present
          ? data.occurredAt.value
          : this.occurredAt,
      tzOffsetMinutes: data.tzOffsetMinutes.present
          ? data.tzOffsetMinutes.value
          : this.tzOffsetMinutes,
      payload: data.payload.present ? data.payload.value : this.payload,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('EventRow(')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('nodeId: $nodeId, ')
          ..write('nodeType: $nodeType, ')
          ..write('domainId: $domainId, ')
          ..write('groupId: $groupId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('payload: $payload, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    eventId,
    eventType,
    nodeId,
    nodeType,
    domainId,
    groupId,
    occurredAt,
    tzOffsetMinutes,
    payload,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is EventRow &&
          other.eventId == this.eventId &&
          other.eventType == this.eventType &&
          other.nodeId == this.nodeId &&
          other.nodeType == this.nodeType &&
          other.domainId == this.domainId &&
          other.groupId == this.groupId &&
          other.occurredAt == this.occurredAt &&
          other.tzOffsetMinutes == this.tzOffsetMinutes &&
          other.payload == this.payload &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class EventsCompanion extends UpdateCompanion<EventRow> {
  final Value<String> eventId;
  final Value<String> eventType;
  final Value<String?> nodeId;
  final Value<String?> nodeType;
  final Value<String?> domainId;
  final Value<String?> groupId;
  final Value<int> occurredAt;
  final Value<int> tzOffsetMinutes;
  final Value<String> payload;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const EventsCompanion({
    this.eventId = const Value.absent(),
    this.eventType = const Value.absent(),
    this.nodeId = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.domainId = const Value.absent(),
    this.groupId = const Value.absent(),
    this.occurredAt = const Value.absent(),
    this.tzOffsetMinutes = const Value.absent(),
    this.payload = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  EventsCompanion.insert({
    required String eventId,
    required String eventType,
    this.nodeId = const Value.absent(),
    this.nodeType = const Value.absent(),
    this.domainId = const Value.absent(),
    this.groupId = const Value.absent(),
    required int occurredAt,
    required int tzOffsetMinutes,
    this.payload = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : eventId = Value(eventId),
       eventType = Value(eventType),
       occurredAt = Value(occurredAt),
       tzOffsetMinutes = Value(tzOffsetMinutes),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<EventRow> custom({
    Expression<String>? eventId,
    Expression<String>? eventType,
    Expression<String>? nodeId,
    Expression<String>? nodeType,
    Expression<String>? domainId,
    Expression<String>? groupId,
    Expression<int>? occurredAt,
    Expression<int>? tzOffsetMinutes,
    Expression<String>? payload,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (eventId != null) 'event_id': eventId,
      if (eventType != null) 'event_type': eventType,
      if (nodeId != null) 'node_id': nodeId,
      if (nodeType != null) 'node_type': nodeType,
      if (domainId != null) 'domain_id': domainId,
      if (groupId != null) 'group_id': groupId,
      if (occurredAt != null) 'occurred_at': occurredAt,
      if (tzOffsetMinutes != null) 'tz_offset_minutes': tzOffsetMinutes,
      if (payload != null) 'payload': payload,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  EventsCompanion copyWith({
    Value<String>? eventId,
    Value<String>? eventType,
    Value<String?>? nodeId,
    Value<String?>? nodeType,
    Value<String?>? domainId,
    Value<String?>? groupId,
    Value<int>? occurredAt,
    Value<int>? tzOffsetMinutes,
    Value<String>? payload,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return EventsCompanion(
      eventId: eventId ?? this.eventId,
      eventType: eventType ?? this.eventType,
      nodeId: nodeId ?? this.nodeId,
      nodeType: nodeType ?? this.nodeType,
      domainId: domainId ?? this.domainId,
      groupId: groupId ?? this.groupId,
      occurredAt: occurredAt ?? this.occurredAt,
      tzOffsetMinutes: tzOffsetMinutes ?? this.tzOffsetMinutes,
      payload: payload ?? this.payload,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (eventId.present) {
      map['event_id'] = Variable<String>(eventId.value);
    }
    if (eventType.present) {
      map['event_type'] = Variable<String>(eventType.value);
    }
    if (nodeId.present) {
      map['node_id'] = Variable<String>(nodeId.value);
    }
    if (nodeType.present) {
      map['node_type'] = Variable<String>(nodeType.value);
    }
    if (domainId.present) {
      map['domain_id'] = Variable<String>(domainId.value);
    }
    if (groupId.present) {
      map['group_id'] = Variable<String>(groupId.value);
    }
    if (occurredAt.present) {
      map['occurred_at'] = Variable<int>(occurredAt.value);
    }
    if (tzOffsetMinutes.present) {
      map['tz_offset_minutes'] = Variable<int>(tzOffsetMinutes.value);
    }
    if (payload.present) {
      map['payload'] = Variable<String>(payload.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('EventsCompanion(')
          ..write('eventId: $eventId, ')
          ..write('eventType: $eventType, ')
          ..write('nodeId: $nodeId, ')
          ..write('nodeType: $nodeType, ')
          ..write('domainId: $domainId, ')
          ..write('groupId: $groupId, ')
          ..write('occurredAt: $occurredAt, ')
          ..write('tzOffsetMinutes: $tzOffsetMinutes, ')
          ..write('payload: $payload, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $CapturesTable extends Captures
    with TableInfo<$CapturesTable, CaptureRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $CapturesTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _bodyMeta = const VerificationMeta('body');
  @override
  late final GeneratedColumn<String> body = GeneratedColumn<String>(
    'text',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    body,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'captures';
  @override
  VerificationContext validateIntegrity(
    Insertable<CaptureRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('text')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['text']!, _bodyMeta),
      );
    } else if (isInserting) {
      context.missing(_bodyMeta);
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  CaptureRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return CaptureRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      body: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}text'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $CapturesTable createAlias(String alias) {
    return $CapturesTable(attachedDatabase, alias);
  }
}

class CaptureRow extends DataClass implements Insertable<CaptureRow> {
  final String id;
  final String body;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  const CaptureRow({
    required this.id,
    required this.body,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['text'] = Variable<String>(body);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  CapturesCompanion toCompanion(bool nullToAbsent) {
    return CapturesCompanion(
      id: Value(id),
      body: Value(body),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory CaptureRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return CaptureRow(
      id: serializer.fromJson<String>(json['id']),
      body: serializer.fromJson<String>(json['body']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'body': serializer.toJson<String>(body),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  CaptureRow copyWith({
    String? id,
    String? body,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) => CaptureRow(
    id: id ?? this.id,
    body: body ?? this.body,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  CaptureRow copyWithCompanion(CapturesCompanion data) {
    return CaptureRow(
      id: data.id.present ? data.id.value : this.id,
      body: data.body.present ? data.body.value : this.body,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('CaptureRow(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(id, body, isDeleted, createdAt, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is CaptureRow &&
          other.id == this.id &&
          other.body == this.body &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class CapturesCompanion extends UpdateCompanion<CaptureRow> {
  final Value<String> id;
  final Value<String> body;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  final Value<int> rowid;
  const CapturesCompanion({
    this.id = const Value.absent(),
    this.body = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  CapturesCompanion.insert({
    required String id,
    required String body,
    this.isDeleted = const Value.absent(),
    required int createdAt,
    required int updatedAt,
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       body = Value(body),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<CaptureRow> custom({
    Expression<String>? id,
    Expression<String>? body,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (body != null) 'text': body,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  CapturesCompanion copyWith({
    Value<String>? id,
    Value<String>? body,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
    Value<int>? updatedAt,
    Value<int>? rowid,
  }) {
    return CapturesCompanion(
      id: id ?? this.id,
      body: body ?? this.body,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (body.present) {
      map['text'] = Variable<String>(body.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('CapturesCompanion(')
          ..write('id: $id, ')
          ..write('body: $body, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $SettingsTableTable extends SettingsTable
    with TableInfo<$SettingsTableTable, SettingsRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $SettingsTableTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<int> id = GeneratedColumn<int>(
    'id',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _dayStartMinutesMeta = const VerificationMeta(
    'dayStartMinutes',
  );
  @override
  late final GeneratedColumn<int> dayStartMinutes = GeneratedColumn<int>(
    'day_start_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(240),
  );
  static const VerificationMeta _presetsMeta = const VerificationMeta(
    'presets',
  );
  @override
  late final GeneratedColumn<String> presets = GeneratedColumn<String>(
    'presets',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _notificationsEnabledMeta =
      const VerificationMeta('notificationsEnabled');
  @override
  late final GeneratedColumn<bool> notificationsEnabled = GeneratedColumn<bool>(
    'notifications_enabled',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("notifications_enabled" IN (0, 1))',
    ),
    defaultValue: const Constant(true),
  );
  static const VerificationMeta _exactRemindersMeta = const VerificationMeta(
    'exactReminders',
  );
  @override
  late final GeneratedColumn<bool> exactReminders = GeneratedColumn<bool>(
    'exact_reminders',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("exact_reminders" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _reminderMinutesMeta = const VerificationMeta(
    'reminderMinutes',
  );
  @override
  late final GeneratedColumn<int> reminderMinutes = GeneratedColumn<int>(
    'reminder_minutes',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(540),
  );
  static const VerificationMeta _defaultLeadDaysMeta = const VerificationMeta(
    'defaultLeadDays',
  );
  @override
  late final GeneratedColumn<int> defaultLeadDays = GeneratedColumn<int>(
    'default_lead_days',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(3),
  );
  static const VerificationMeta _onboardingDoneMeta = const VerificationMeta(
    'onboardingDone',
  );
  @override
  late final GeneratedColumn<bool> onboardingDone = GeneratedColumn<bool>(
    'onboarding_done',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("onboarding_done" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _isDeletedMeta = const VerificationMeta(
    'isDeleted',
  );
  @override
  late final GeneratedColumn<bool> isDeleted = GeneratedColumn<bool>(
    'is_deleted',
    aliasedName,
    false,
    type: DriftSqlType.bool,
    requiredDuringInsert: false,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'CHECK ("is_deleted" IN (0, 1))',
    ),
    defaultValue: const Constant(false),
  );
  static const VerificationMeta _createdAtMeta = const VerificationMeta(
    'createdAt',
  );
  @override
  late final GeneratedColumn<int> createdAt = GeneratedColumn<int>(
    'created_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _updatedAtMeta = const VerificationMeta(
    'updatedAt',
  );
  @override
  late final GeneratedColumn<int> updatedAt = GeneratedColumn<int>(
    'updated_at',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    id,
    dayStartMinutes,
    presets,
    notificationsEnabled,
    exactReminders,
    reminderMinutes,
    defaultLeadDays,
    onboardingDone,
    isDeleted,
    createdAt,
    updatedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'settings';
  @override
  VerificationContext validateIntegrity(
    Insertable<SettingsRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('day_start_minutes')) {
      context.handle(
        _dayStartMinutesMeta,
        dayStartMinutes.isAcceptableOrUnknown(
          data['day_start_minutes']!,
          _dayStartMinutesMeta,
        ),
      );
    }
    if (data.containsKey('presets')) {
      context.handle(
        _presetsMeta,
        presets.isAcceptableOrUnknown(data['presets']!, _presetsMeta),
      );
    }
    if (data.containsKey('notifications_enabled')) {
      context.handle(
        _notificationsEnabledMeta,
        notificationsEnabled.isAcceptableOrUnknown(
          data['notifications_enabled']!,
          _notificationsEnabledMeta,
        ),
      );
    }
    if (data.containsKey('exact_reminders')) {
      context.handle(
        _exactRemindersMeta,
        exactReminders.isAcceptableOrUnknown(
          data['exact_reminders']!,
          _exactRemindersMeta,
        ),
      );
    }
    if (data.containsKey('reminder_minutes')) {
      context.handle(
        _reminderMinutesMeta,
        reminderMinutes.isAcceptableOrUnknown(
          data['reminder_minutes']!,
          _reminderMinutesMeta,
        ),
      );
    }
    if (data.containsKey('default_lead_days')) {
      context.handle(
        _defaultLeadDaysMeta,
        defaultLeadDays.isAcceptableOrUnknown(
          data['default_lead_days']!,
          _defaultLeadDaysMeta,
        ),
      );
    }
    if (data.containsKey('onboarding_done')) {
      context.handle(
        _onboardingDoneMeta,
        onboardingDone.isAcceptableOrUnknown(
          data['onboarding_done']!,
          _onboardingDoneMeta,
        ),
      );
    }
    if (data.containsKey('is_deleted')) {
      context.handle(
        _isDeletedMeta,
        isDeleted.isAcceptableOrUnknown(data['is_deleted']!, _isDeletedMeta),
      );
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    } else if (isInserting) {
      context.missing(_createdAtMeta);
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    } else if (isInserting) {
      context.missing(_updatedAtMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  SettingsRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return SettingsRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}id'],
      )!,
      dayStartMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}day_start_minutes'],
      )!,
      presets: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}presets'],
      ),
      notificationsEnabled: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}notifications_enabled'],
      )!,
      exactReminders: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}exact_reminders'],
      )!,
      reminderMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}reminder_minutes'],
      )!,
      defaultLeadDays: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}default_lead_days'],
      )!,
      onboardingDone: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}onboarding_done'],
      )!,
      isDeleted: attachedDatabase.typeMapping.read(
        DriftSqlType.bool,
        data['${effectivePrefix}is_deleted'],
      )!,
      createdAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}created_at'],
      )!,
      updatedAt: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}updated_at'],
      )!,
    );
  }

  @override
  $SettingsTableTable createAlias(String alias) {
    return $SettingsTableTable(attachedDatabase, alias);
  }
}

class SettingsRow extends DataClass implements Insertable<SettingsRow> {
  final int id;

  /// "Day starts at", in minutes after midnight (default 4:00 AM, PRD 7).
  final int dayStartMinutes;

  /// Custom set-aside presets as JSON; null means the PRD defaults.
  final String? presets;
  final bool notificationsEnabled;
  final bool exactReminders;

  /// Reminder time for recurring items, in minutes after midnight (9:00 AM).
  final int reminderMinutes;
  final int defaultLeadDays;
  final bool onboardingDone;
  final bool isDeleted;
  final int createdAt;
  final int updatedAt;
  const SettingsRow({
    required this.id,
    required this.dayStartMinutes,
    this.presets,
    required this.notificationsEnabled,
    required this.exactReminders,
    required this.reminderMinutes,
    required this.defaultLeadDays,
    required this.onboardingDone,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<int>(id);
    map['day_start_minutes'] = Variable<int>(dayStartMinutes);
    if (!nullToAbsent || presets != null) {
      map['presets'] = Variable<String>(presets);
    }
    map['notifications_enabled'] = Variable<bool>(notificationsEnabled);
    map['exact_reminders'] = Variable<bool>(exactReminders);
    map['reminder_minutes'] = Variable<int>(reminderMinutes);
    map['default_lead_days'] = Variable<int>(defaultLeadDays);
    map['onboarding_done'] = Variable<bool>(onboardingDone);
    map['is_deleted'] = Variable<bool>(isDeleted);
    map['created_at'] = Variable<int>(createdAt);
    map['updated_at'] = Variable<int>(updatedAt);
    return map;
  }

  SettingsTableCompanion toCompanion(bool nullToAbsent) {
    return SettingsTableCompanion(
      id: Value(id),
      dayStartMinutes: Value(dayStartMinutes),
      presets: presets == null && nullToAbsent
          ? const Value.absent()
          : Value(presets),
      notificationsEnabled: Value(notificationsEnabled),
      exactReminders: Value(exactReminders),
      reminderMinutes: Value(reminderMinutes),
      defaultLeadDays: Value(defaultLeadDays),
      onboardingDone: Value(onboardingDone),
      isDeleted: Value(isDeleted),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
    );
  }

  factory SettingsRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return SettingsRow(
      id: serializer.fromJson<int>(json['id']),
      dayStartMinutes: serializer.fromJson<int>(json['dayStartMinutes']),
      presets: serializer.fromJson<String?>(json['presets']),
      notificationsEnabled: serializer.fromJson<bool>(
        json['notificationsEnabled'],
      ),
      exactReminders: serializer.fromJson<bool>(json['exactReminders']),
      reminderMinutes: serializer.fromJson<int>(json['reminderMinutes']),
      defaultLeadDays: serializer.fromJson<int>(json['defaultLeadDays']),
      onboardingDone: serializer.fromJson<bool>(json['onboardingDone']),
      isDeleted: serializer.fromJson<bool>(json['isDeleted']),
      createdAt: serializer.fromJson<int>(json['createdAt']),
      updatedAt: serializer.fromJson<int>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<int>(id),
      'dayStartMinutes': serializer.toJson<int>(dayStartMinutes),
      'presets': serializer.toJson<String?>(presets),
      'notificationsEnabled': serializer.toJson<bool>(notificationsEnabled),
      'exactReminders': serializer.toJson<bool>(exactReminders),
      'reminderMinutes': serializer.toJson<int>(reminderMinutes),
      'defaultLeadDays': serializer.toJson<int>(defaultLeadDays),
      'onboardingDone': serializer.toJson<bool>(onboardingDone),
      'isDeleted': serializer.toJson<bool>(isDeleted),
      'createdAt': serializer.toJson<int>(createdAt),
      'updatedAt': serializer.toJson<int>(updatedAt),
    };
  }

  SettingsRow copyWith({
    int? id,
    int? dayStartMinutes,
    Value<String?> presets = const Value.absent(),
    bool? notificationsEnabled,
    bool? exactReminders,
    int? reminderMinutes,
    int? defaultLeadDays,
    bool? onboardingDone,
    bool? isDeleted,
    int? createdAt,
    int? updatedAt,
  }) => SettingsRow(
    id: id ?? this.id,
    dayStartMinutes: dayStartMinutes ?? this.dayStartMinutes,
    presets: presets.present ? presets.value : this.presets,
    notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
    exactReminders: exactReminders ?? this.exactReminders,
    reminderMinutes: reminderMinutes ?? this.reminderMinutes,
    defaultLeadDays: defaultLeadDays ?? this.defaultLeadDays,
    onboardingDone: onboardingDone ?? this.onboardingDone,
    isDeleted: isDeleted ?? this.isDeleted,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  SettingsRow copyWithCompanion(SettingsTableCompanion data) {
    return SettingsRow(
      id: data.id.present ? data.id.value : this.id,
      dayStartMinutes: data.dayStartMinutes.present
          ? data.dayStartMinutes.value
          : this.dayStartMinutes,
      presets: data.presets.present ? data.presets.value : this.presets,
      notificationsEnabled: data.notificationsEnabled.present
          ? data.notificationsEnabled.value
          : this.notificationsEnabled,
      exactReminders: data.exactReminders.present
          ? data.exactReminders.value
          : this.exactReminders,
      reminderMinutes: data.reminderMinutes.present
          ? data.reminderMinutes.value
          : this.reminderMinutes,
      defaultLeadDays: data.defaultLeadDays.present
          ? data.defaultLeadDays.value
          : this.defaultLeadDays,
      onboardingDone: data.onboardingDone.present
          ? data.onboardingDone.value
          : this.onboardingDone,
      isDeleted: data.isDeleted.present ? data.isDeleted.value : this.isDeleted,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('SettingsRow(')
          ..write('id: $id, ')
          ..write('dayStartMinutes: $dayStartMinutes, ')
          ..write('presets: $presets, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('exactReminders: $exactReminders, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('defaultLeadDays: $defaultLeadDays, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    dayStartMinutes,
    presets,
    notificationsEnabled,
    exactReminders,
    reminderMinutes,
    defaultLeadDays,
    onboardingDone,
    isDeleted,
    createdAt,
    updatedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is SettingsRow &&
          other.id == this.id &&
          other.dayStartMinutes == this.dayStartMinutes &&
          other.presets == this.presets &&
          other.notificationsEnabled == this.notificationsEnabled &&
          other.exactReminders == this.exactReminders &&
          other.reminderMinutes == this.reminderMinutes &&
          other.defaultLeadDays == this.defaultLeadDays &&
          other.onboardingDone == this.onboardingDone &&
          other.isDeleted == this.isDeleted &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt);
}

class SettingsTableCompanion extends UpdateCompanion<SettingsRow> {
  final Value<int> id;
  final Value<int> dayStartMinutes;
  final Value<String?> presets;
  final Value<bool> notificationsEnabled;
  final Value<bool> exactReminders;
  final Value<int> reminderMinutes;
  final Value<int> defaultLeadDays;
  final Value<bool> onboardingDone;
  final Value<bool> isDeleted;
  final Value<int> createdAt;
  final Value<int> updatedAt;
  const SettingsTableCompanion({
    this.id = const Value.absent(),
    this.dayStartMinutes = const Value.absent(),
    this.presets = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.exactReminders = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.defaultLeadDays = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.isDeleted = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
  });
  SettingsTableCompanion.insert({
    this.id = const Value.absent(),
    this.dayStartMinutes = const Value.absent(),
    this.presets = const Value.absent(),
    this.notificationsEnabled = const Value.absent(),
    this.exactReminders = const Value.absent(),
    this.reminderMinutes = const Value.absent(),
    this.defaultLeadDays = const Value.absent(),
    this.onboardingDone = const Value.absent(),
    this.isDeleted = const Value.absent(),
    required int createdAt,
    required int updatedAt,
  }) : createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<SettingsRow> custom({
    Expression<int>? id,
    Expression<int>? dayStartMinutes,
    Expression<String>? presets,
    Expression<bool>? notificationsEnabled,
    Expression<bool>? exactReminders,
    Expression<int>? reminderMinutes,
    Expression<int>? defaultLeadDays,
    Expression<bool>? onboardingDone,
    Expression<bool>? isDeleted,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (dayStartMinutes != null) 'day_start_minutes': dayStartMinutes,
      if (presets != null) 'presets': presets,
      if (notificationsEnabled != null)
        'notifications_enabled': notificationsEnabled,
      if (exactReminders != null) 'exact_reminders': exactReminders,
      if (reminderMinutes != null) 'reminder_minutes': reminderMinutes,
      if (defaultLeadDays != null) 'default_lead_days': defaultLeadDays,
      if (onboardingDone != null) 'onboarding_done': onboardingDone,
      if (isDeleted != null) 'is_deleted': isDeleted,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
    });
  }

  SettingsTableCompanion copyWith({
    Value<int>? id,
    Value<int>? dayStartMinutes,
    Value<String?>? presets,
    Value<bool>? notificationsEnabled,
    Value<bool>? exactReminders,
    Value<int>? reminderMinutes,
    Value<int>? defaultLeadDays,
    Value<bool>? onboardingDone,
    Value<bool>? isDeleted,
    Value<int>? createdAt,
    Value<int>? updatedAt,
  }) {
    return SettingsTableCompanion(
      id: id ?? this.id,
      dayStartMinutes: dayStartMinutes ?? this.dayStartMinutes,
      presets: presets ?? this.presets,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      exactReminders: exactReminders ?? this.exactReminders,
      reminderMinutes: reminderMinutes ?? this.reminderMinutes,
      defaultLeadDays: defaultLeadDays ?? this.defaultLeadDays,
      onboardingDone: onboardingDone ?? this.onboardingDone,
      isDeleted: isDeleted ?? this.isDeleted,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<int>(id.value);
    }
    if (dayStartMinutes.present) {
      map['day_start_minutes'] = Variable<int>(dayStartMinutes.value);
    }
    if (presets.present) {
      map['presets'] = Variable<String>(presets.value);
    }
    if (notificationsEnabled.present) {
      map['notifications_enabled'] = Variable<bool>(notificationsEnabled.value);
    }
    if (exactReminders.present) {
      map['exact_reminders'] = Variable<bool>(exactReminders.value);
    }
    if (reminderMinutes.present) {
      map['reminder_minutes'] = Variable<int>(reminderMinutes.value);
    }
    if (defaultLeadDays.present) {
      map['default_lead_days'] = Variable<int>(defaultLeadDays.value);
    }
    if (onboardingDone.present) {
      map['onboarding_done'] = Variable<bool>(onboardingDone.value);
    }
    if (isDeleted.present) {
      map['is_deleted'] = Variable<bool>(isDeleted.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(updatedAt.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('SettingsTableCompanion(')
          ..write('id: $id, ')
          ..write('dayStartMinutes: $dayStartMinutes, ')
          ..write('presets: $presets, ')
          ..write('notificationsEnabled: $notificationsEnabled, ')
          ..write('exactReminders: $exactReminders, ')
          ..write('reminderMinutes: $reminderMinutes, ')
          ..write('defaultLeadDays: $defaultLeadDays, ')
          ..write('onboardingDone: $onboardingDone, ')
          ..write('isDeleted: $isDeleted, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }
}

abstract class _$SahaiDatabase extends GeneratedDatabase {
  _$SahaiDatabase(QueryExecutor e) : super(e);
  $SahaiDatabaseManager get managers => $SahaiDatabaseManager(this);
  late final $NodesTable nodes = $NodesTable(this);
  late final $ContextGroupsTable contextGroups = $ContextGroupsTable(this);
  late final $SummarySlotsTable summarySlots = $SummarySlotsTable(this);
  late final $EventsTable events = $EventsTable(this);
  late final $CapturesTable captures = $CapturesTable(this);
  late final $SettingsTableTable settingsTable = $SettingsTableTable(this);
  late final Index nodesParentStatusDeleted = Index(
    'nodes_parent_status_deleted',
    'CREATE INDEX nodes_parent_status_deleted ON nodes (parent_id, status, is_deleted)',
  );
  late final Index nodesSnoozeUntil = Index(
    'nodes_snooze_until',
    'CREATE INDEX nodes_snooze_until ON nodes (snooze_until)',
  );
  late final Index eventsOccurredAt = Index(
    'events_occurred_at',
    'CREATE INDEX events_occurred_at ON events (occurred_at)',
  );
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    nodes,
    contextGroups,
    summarySlots,
    events,
    captures,
    settingsTable,
    nodesParentStatusDeleted,
    nodesSnoozeUntil,
    eventsOccurredAt,
  ];
}

typedef $$NodesTableCreateCompanionBuilder = NodesCompanion Function({
  required String id,
  Value<String?> parentId,
  required String type,
  required String title,
  Value<String> notes,
  Value<String?> status,
  required int sortOrder,
  Value<int?> snoozeUntil,
  Value<bool> remindOnWake,
  Value<String?> dueOn,
  Value<String?> recurrence,
  Value<int?> leadDays,
  Value<String?> groupId,
  Value<int?> completedAt,
  Value<bool> isDeleted,
  Value<String?> deletedByEvent,
  Value<bool> snoozeOverridesShow,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$NodesTableUpdateCompanionBuilder = NodesCompanion Function({
  Value<String> id,
  Value<String?> parentId,
  Value<String> type,
  Value<String> title,
  Value<String> notes,
  Value<String?> status,
  Value<int> sortOrder,
  Value<int?> snoozeUntil,
  Value<bool> remindOnWake,
  Value<String?> dueOn,
  Value<String?> recurrence,
  Value<int?> leadDays,
  Value<String?> groupId,
  Value<int?> completedAt,
  Value<bool> isDeleted,
  Value<String?> deletedByEvent,
  Value<bool> snoozeOverridesShow,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$NodesTableFilterComposer
    extends Composer<_$SahaiDatabase, $NodesTable> {
  $$NodesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get snoozeUntil => $composableBuilder(
    column: $table.snoozeUntil,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get remindOnWake => $composableBuilder(
    column: $table.remindOnWake,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get leadDays => $composableBuilder(
    column: $table.leadDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get deletedByEvent => $composableBuilder(
    column: $table.deletedByEvent,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get snoozeOverridesShow => $composableBuilder(
    column: $table.snoozeOverridesShow,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$NodesTableOrderingComposer
    extends Composer<_$SahaiDatabase, $NodesTable> {
  $$NodesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get parentId => $composableBuilder(
    column: $table.parentId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get type => $composableBuilder(
    column: $table.type,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get notes => $composableBuilder(
    column: $table.notes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get snoozeUntil => $composableBuilder(
    column: $table.snoozeUntil,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get remindOnWake => $composableBuilder(
    column: $table.remindOnWake,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get dueOn => $composableBuilder(
    column: $table.dueOn,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get leadDays => $composableBuilder(
    column: $table.leadDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get deletedByEvent => $composableBuilder(
    column: $table.deletedByEvent,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get snoozeOverridesShow => $composableBuilder(
    column: $table.snoozeOverridesShow,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$NodesTableAnnotationComposer
    extends Composer<_$SahaiDatabase, $NodesTable> {
  $$NodesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get parentId =>
      $composableBuilder(column: $table.parentId, builder: (column) => column);

  GeneratedColumn<String> get type =>
      $composableBuilder(column: $table.type, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get notes =>
      $composableBuilder(column: $table.notes, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<int> get snoozeUntil => $composableBuilder(
    column: $table.snoozeUntil,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get remindOnWake => $composableBuilder(
    column: $table.remindOnWake,
    builder: (column) => column,
  );

  GeneratedColumn<String> get dueOn =>
      $composableBuilder(column: $table.dueOn, builder: (column) => column);

  GeneratedColumn<String> get recurrence => $composableBuilder(
    column: $table.recurrence,
    builder: (column) => column,
  );

  GeneratedColumn<int> get leadDays =>
      $composableBuilder(column: $table.leadDays, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get completedAt => $composableBuilder(
    column: $table.completedAt,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<String> get deletedByEvent => $composableBuilder(
    column: $table.deletedByEvent,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get snoozeOverridesShow => $composableBuilder(
    column: $table.snoozeOverridesShow,
    builder: (column) => column,
  );

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$NodesTableTableManager
    extends
        RootTableManager<
          _$SahaiDatabase,
          $NodesTable,
          NodeRow,
          $$NodesTableFilterComposer,
          $$NodesTableOrderingComposer,
          $$NodesTableAnnotationComposer,
          $$NodesTableCreateCompanionBuilder,
          $$NodesTableUpdateCompanionBuilder,
          (NodeRow, BaseReferences<_$SahaiDatabase, $NodesTable, NodeRow>),
          NodeRow,
          PrefetchHooks Function()
        > {
  $$NodesTableTableManager(_$SahaiDatabase db, $NodesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$NodesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$NodesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$NodesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String?> parentId = const Value.absent(),
                Value<String> type = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String> notes = const Value.absent(),
                Value<String?> status = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<int?> snoozeUntil = const Value.absent(),
                Value<bool> remindOnWake = const Value.absent(),
                Value<String?> dueOn = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> leadDays = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> deletedByEvent = const Value.absent(),
                Value<bool> snoozeOverridesShow = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion(
                id: id,
                parentId: parentId,
                type: type,
                title: title,
                notes: notes,
                status: status,
                sortOrder: sortOrder,
                snoozeUntil: snoozeUntil,
                remindOnWake: remindOnWake,
                dueOn: dueOn,
                recurrence: recurrence,
                leadDays: leadDays,
                groupId: groupId,
                completedAt: completedAt,
                isDeleted: isDeleted,
                deletedByEvent: deletedByEvent,
                snoozeOverridesShow: snoozeOverridesShow,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                Value<String?> parentId = const Value.absent(),
                required String type,
                required String title,
                Value<String> notes = const Value.absent(),
                Value<String?> status = const Value.absent(),
                required int sortOrder,
                Value<int?> snoozeUntil = const Value.absent(),
                Value<bool> remindOnWake = const Value.absent(),
                Value<String?> dueOn = const Value.absent(),
                Value<String?> recurrence = const Value.absent(),
                Value<int?> leadDays = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int?> completedAt = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<String?> deletedByEvent = const Value.absent(),
                Value<bool> snoozeOverridesShow = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => NodesCompanion.insert(
                id: id,
                parentId: parentId,
                type: type,
                title: title,
                notes: notes,
                status: status,
                sortOrder: sortOrder,
                snoozeUntil: snoozeUntil,
                remindOnWake: remindOnWake,
                dueOn: dueOn,
                recurrence: recurrence,
                leadDays: leadDays,
                groupId: groupId,
                completedAt: completedAt,
                isDeleted: isDeleted,
                deletedByEvent: deletedByEvent,
                snoozeOverridesShow: snoozeOverridesShow,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$NodesTable, NodeRow>(table),
                  BaseReferences<_$SahaiDatabase, $NodesTable, NodeRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$NodesTableProcessedTableManager =
    ProcessedTableManager<
      _$SahaiDatabase,
      $NodesTable,
      NodeRow,
      $$NodesTableFilterComposer,
      $$NodesTableOrderingComposer,
      $$NodesTableAnnotationComposer,
      $$NodesTableCreateCompanionBuilder,
      $$NodesTableUpdateCompanionBuilder,
      (NodeRow, BaseReferences<_$SahaiDatabase, $NodesTable, NodeRow>),
      NodeRow,
      PrefetchHooks Function()
    >;
typedef $$ContextGroupsTableCreateCompanionBuilder =
    ContextGroupsCompanion Function({
      required String id,
      required String name,
      Value<String?> icon,
      required int sortOrder,
      Value<bool> isDeleted,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$ContextGroupsTableUpdateCompanionBuilder =
    ContextGroupsCompanion Function({
      Value<String> id,
      Value<String> name,
      Value<String?> icon,
      Value<int> sortOrder,
      Value<bool> isDeleted,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$ContextGroupsTableFilterComposer
    extends Composer<_$SahaiDatabase, $ContextGroupsTable> {
  $$ContextGroupsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ContextGroupsTableOrderingComposer
    extends Composer<_$SahaiDatabase, $ContextGroupsTable> {
  $$ContextGroupsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get icon => $composableBuilder(
    column: $table.icon,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sortOrder => $composableBuilder(
    column: $table.sortOrder,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ContextGroupsTableAnnotationComposer
    extends Composer<_$SahaiDatabase, $ContextGroupsTable> {
  $$ContextGroupsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  GeneratedColumn<String> get icon =>
      $composableBuilder(column: $table.icon, builder: (column) => column);

  GeneratedColumn<int> get sortOrder =>
      $composableBuilder(column: $table.sortOrder, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$ContextGroupsTableTableManager
    extends
        RootTableManager<
          _$SahaiDatabase,
          $ContextGroupsTable,
          ContextGroupRow,
          $$ContextGroupsTableFilterComposer,
          $$ContextGroupsTableOrderingComposer,
          $$ContextGroupsTableAnnotationComposer,
          $$ContextGroupsTableCreateCompanionBuilder,
          $$ContextGroupsTableUpdateCompanionBuilder,
          (
            ContextGroupRow,
            BaseReferences<
              _$SahaiDatabase,
              $ContextGroupsTable,
              ContextGroupRow
            >,
          ),
          ContextGroupRow,
          PrefetchHooks Function()
        > {
  $$ContextGroupsTableTableManager(
    _$SahaiDatabase db,
    $ContextGroupsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ContextGroupsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ContextGroupsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ContextGroupsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> name = const Value.absent(),
                Value<String?> icon = const Value.absent(),
                Value<int> sortOrder = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ContextGroupsCompanion(
                id: id,
                name: name,
                icon: icon,
                sortOrder: sortOrder,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String name,
                Value<String?> icon = const Value.absent(),
                required int sortOrder,
                Value<bool> isDeleted = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => ContextGroupsCompanion.insert(
                id: id,
                name: name,
                icon: icon,
                sortOrder: sortOrder,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$ContextGroupsTable, ContextGroupRow>(table),
                  BaseReferences<
                    _$SahaiDatabase,
                    $ContextGroupsTable,
                    ContextGroupRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ContextGroupsTableProcessedTableManager =
    ProcessedTableManager<
      _$SahaiDatabase,
      $ContextGroupsTable,
      ContextGroupRow,
      $$ContextGroupsTableFilterComposer,
      $$ContextGroupsTableOrderingComposer,
      $$ContextGroupsTableAnnotationComposer,
      $$ContextGroupsTableCreateCompanionBuilder,
      $$ContextGroupsTableUpdateCompanionBuilder,
      (
        ContextGroupRow,
        BaseReferences<_$SahaiDatabase, $ContextGroupsTable, ContextGroupRow>,
      ),
      ContextGroupRow,
      PrefetchHooks Function()
    >;
typedef $$SummarySlotsTableCreateCompanionBuilder =
    SummarySlotsCompanion Function({
      required String ownerId,
      Value<String?> groupId,
      required int position,
      Value<bool> isDeleted,
      required int createdAt,
      required int updatedAt,
      Value<int> rowid,
    });
typedef $$SummarySlotsTableUpdateCompanionBuilder =
    SummarySlotsCompanion Function({
      Value<String> ownerId,
      Value<String?> groupId,
      Value<int> position,
      Value<bool> isDeleted,
      Value<int> createdAt,
      Value<int> updatedAt,
      Value<int> rowid,
    });

class $$SummarySlotsTableFilterComposer
    extends Composer<_$SahaiDatabase, $SummarySlotsTable> {
  $$SummarySlotsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SummarySlotsTableOrderingComposer
    extends Composer<_$SahaiDatabase, $SummarySlotsTable> {
  $$SummarySlotsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get ownerId => $composableBuilder(
    column: $table.ownerId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SummarySlotsTableAnnotationComposer
    extends Composer<_$SahaiDatabase, $SummarySlotsTable> {
  $$SummarySlotsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get ownerId =>
      $composableBuilder(column: $table.ownerId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SummarySlotsTableTableManager
    extends
        RootTableManager<
          _$SahaiDatabase,
          $SummarySlotsTable,
          SummarySlotRow,
          $$SummarySlotsTableFilterComposer,
          $$SummarySlotsTableOrderingComposer,
          $$SummarySlotsTableAnnotationComposer,
          $$SummarySlotsTableCreateCompanionBuilder,
          $$SummarySlotsTableUpdateCompanionBuilder,
          (
            SummarySlotRow,
            BaseReferences<_$SahaiDatabase, $SummarySlotsTable, SummarySlotRow>,
          ),
          SummarySlotRow,
          PrefetchHooks Function()
        > {
  $$SummarySlotsTableTableManager(_$SahaiDatabase db, $SummarySlotsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SummarySlotsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SummarySlotsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SummarySlotsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> ownerId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => SummarySlotsCompanion(
                ownerId: ownerId,
                groupId: groupId,
                position: position,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String ownerId,
                Value<String?> groupId = const Value.absent(),
                required int position,
                Value<bool> isDeleted = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => SummarySlotsCompanion.insert(
                ownerId: ownerId,
                groupId: groupId,
                position: position,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SummarySlotsTable, SummarySlotRow>(table),
                  BaseReferences<
                    _$SahaiDatabase,
                    $SummarySlotsTable,
                    SummarySlotRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SummarySlotsTableProcessedTableManager =
    ProcessedTableManager<
      _$SahaiDatabase,
      $SummarySlotsTable,
      SummarySlotRow,
      $$SummarySlotsTableFilterComposer,
      $$SummarySlotsTableOrderingComposer,
      $$SummarySlotsTableAnnotationComposer,
      $$SummarySlotsTableCreateCompanionBuilder,
      $$SummarySlotsTableUpdateCompanionBuilder,
      (
        SummarySlotRow,
        BaseReferences<_$SahaiDatabase, $SummarySlotsTable, SummarySlotRow>,
      ),
      SummarySlotRow,
      PrefetchHooks Function()
    >;
typedef $$EventsTableCreateCompanionBuilder = EventsCompanion Function({
  required String eventId,
  required String eventType,
  Value<String?> nodeId,
  Value<String?> nodeType,
  Value<String?> domainId,
  Value<String?> groupId,
  required int occurredAt,
  required int tzOffsetMinutes,
  Value<String> payload,
  Value<bool> isDeleted,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$EventsTableUpdateCompanionBuilder = EventsCompanion Function({
  Value<String> eventId,
  Value<String> eventType,
  Value<String?> nodeId,
  Value<String?> nodeType,
  Value<String?> domainId,
  Value<String?> groupId,
  Value<int> occurredAt,
  Value<int> tzOffsetMinutes,
  Value<String> payload,
  Value<bool> isDeleted,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$EventsTableFilterComposer
    extends Composer<_$SahaiDatabase, $EventsTable> {
  $$EventsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get domainId => $composableBuilder(
    column: $table.domainId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$EventsTableOrderingComposer
    extends Composer<_$SahaiDatabase, $EventsTable> {
  $$EventsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get eventId => $composableBuilder(
    column: $table.eventId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get eventType => $composableBuilder(
    column: $table.eventType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeId => $composableBuilder(
    column: $table.nodeId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get nodeType => $composableBuilder(
    column: $table.nodeType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get domainId => $composableBuilder(
    column: $table.domainId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get groupId => $composableBuilder(
    column: $table.groupId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get payload => $composableBuilder(
    column: $table.payload,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$EventsTableAnnotationComposer
    extends Composer<_$SahaiDatabase, $EventsTable> {
  $$EventsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get eventId =>
      $composableBuilder(column: $table.eventId, builder: (column) => column);

  GeneratedColumn<String> get eventType =>
      $composableBuilder(column: $table.eventType, builder: (column) => column);

  GeneratedColumn<String> get nodeId =>
      $composableBuilder(column: $table.nodeId, builder: (column) => column);

  GeneratedColumn<String> get nodeType =>
      $composableBuilder(column: $table.nodeType, builder: (column) => column);

  GeneratedColumn<String> get domainId =>
      $composableBuilder(column: $table.domainId, builder: (column) => column);

  GeneratedColumn<String> get groupId =>
      $composableBuilder(column: $table.groupId, builder: (column) => column);

  GeneratedColumn<int> get occurredAt => $composableBuilder(
    column: $table.occurredAt,
    builder: (column) => column,
  );

  GeneratedColumn<int> get tzOffsetMinutes => $composableBuilder(
    column: $table.tzOffsetMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get payload =>
      $composableBuilder(column: $table.payload, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$EventsTableTableManager
    extends
        RootTableManager<
          _$SahaiDatabase,
          $EventsTable,
          EventRow,
          $$EventsTableFilterComposer,
          $$EventsTableOrderingComposer,
          $$EventsTableAnnotationComposer,
          $$EventsTableCreateCompanionBuilder,
          $$EventsTableUpdateCompanionBuilder,
          (EventRow, BaseReferences<_$SahaiDatabase, $EventsTable, EventRow>),
          EventRow,
          PrefetchHooks Function()
        > {
  $$EventsTableTableManager(_$SahaiDatabase db, $EventsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$EventsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$EventsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$EventsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> eventId = const Value.absent(),
                Value<String> eventType = const Value.absent(),
                Value<String?> nodeId = const Value.absent(),
                Value<String?> nodeType = const Value.absent(),
                Value<String?> domainId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                Value<int> occurredAt = const Value.absent(),
                Value<int> tzOffsetMinutes = const Value.absent(),
                Value<String> payload = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion(
                eventId: eventId,
                eventType: eventType,
                nodeId: nodeId,
                nodeType: nodeType,
                domainId: domainId,
                groupId: groupId,
                occurredAt: occurredAt,
                tzOffsetMinutes: tzOffsetMinutes,
                payload: payload,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String eventId,
                required String eventType,
                Value<String?> nodeId = const Value.absent(),
                Value<String?> nodeType = const Value.absent(),
                Value<String?> domainId = const Value.absent(),
                Value<String?> groupId = const Value.absent(),
                required int occurredAt,
                required int tzOffsetMinutes,
                Value<String> payload = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => EventsCompanion.insert(
                eventId: eventId,
                eventType: eventType,
                nodeId: nodeId,
                nodeType: nodeType,
                domainId: domainId,
                groupId: groupId,
                occurredAt: occurredAt,
                tzOffsetMinutes: tzOffsetMinutes,
                payload: payload,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$EventsTable, EventRow>(table),
                  BaseReferences<_$SahaiDatabase, $EventsTable, EventRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$EventsTableProcessedTableManager =
    ProcessedTableManager<
      _$SahaiDatabase,
      $EventsTable,
      EventRow,
      $$EventsTableFilterComposer,
      $$EventsTableOrderingComposer,
      $$EventsTableAnnotationComposer,
      $$EventsTableCreateCompanionBuilder,
      $$EventsTableUpdateCompanionBuilder,
      (EventRow, BaseReferences<_$SahaiDatabase, $EventsTable, EventRow>),
      EventRow,
      PrefetchHooks Function()
    >;
typedef $$CapturesTableCreateCompanionBuilder = CapturesCompanion Function({
  required String id,
  required String body,
  Value<bool> isDeleted,
  required int createdAt,
  required int updatedAt,
  Value<int> rowid,
});
typedef $$CapturesTableUpdateCompanionBuilder = CapturesCompanion Function({
  Value<String> id,
  Value<String> body,
  Value<bool> isDeleted,
  Value<int> createdAt,
  Value<int> updatedAt,
  Value<int> rowid,
});

class $$CapturesTableFilterComposer
    extends Composer<_$SahaiDatabase, $CapturesTable> {
  $$CapturesTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$CapturesTableOrderingComposer
    extends Composer<_$SahaiDatabase, $CapturesTable> {
  $$CapturesTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$CapturesTableAnnotationComposer
    extends Composer<_$SahaiDatabase, $CapturesTable> {
  $$CapturesTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$CapturesTableTableManager
    extends
        RootTableManager<
          _$SahaiDatabase,
          $CapturesTable,
          CaptureRow,
          $$CapturesTableFilterComposer,
          $$CapturesTableOrderingComposer,
          $$CapturesTableAnnotationComposer,
          $$CapturesTableCreateCompanionBuilder,
          $$CapturesTableUpdateCompanionBuilder,
          (
            CaptureRow,
            BaseReferences<_$SahaiDatabase, $CapturesTable, CaptureRow>,
          ),
          CaptureRow,
          PrefetchHooks Function()
        > {
  $$CapturesTableTableManager(_$SahaiDatabase db, $CapturesTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$CapturesTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$CapturesTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$CapturesTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> body = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => CapturesCompanion(
                id: id,
                body: body,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String body,
                Value<bool> isDeleted = const Value.absent(),
                required int createdAt,
                required int updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => CapturesCompanion.insert(
                id: id,
                body: body,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$CapturesTable, CaptureRow>(table),
                  BaseReferences<_$SahaiDatabase, $CapturesTable, CaptureRow>(
                    db,
                    table,
                    e,
                  ),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$CapturesTableProcessedTableManager =
    ProcessedTableManager<
      _$SahaiDatabase,
      $CapturesTable,
      CaptureRow,
      $$CapturesTableFilterComposer,
      $$CapturesTableOrderingComposer,
      $$CapturesTableAnnotationComposer,
      $$CapturesTableCreateCompanionBuilder,
      $$CapturesTableUpdateCompanionBuilder,
      (CaptureRow, BaseReferences<_$SahaiDatabase, $CapturesTable, CaptureRow>),
      CaptureRow,
      PrefetchHooks Function()
    >;
typedef $$SettingsTableTableCreateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<int> id,
      Value<int> dayStartMinutes,
      Value<String?> presets,
      Value<bool> notificationsEnabled,
      Value<bool> exactReminders,
      Value<int> reminderMinutes,
      Value<int> defaultLeadDays,
      Value<bool> onboardingDone,
      Value<bool> isDeleted,
      required int createdAt,
      required int updatedAt,
    });
typedef $$SettingsTableTableUpdateCompanionBuilder =
    SettingsTableCompanion Function({
      Value<int> id,
      Value<int> dayStartMinutes,
      Value<String?> presets,
      Value<bool> notificationsEnabled,
      Value<bool> exactReminders,
      Value<int> reminderMinutes,
      Value<int> defaultLeadDays,
      Value<bool> onboardingDone,
      Value<bool> isDeleted,
      Value<int> createdAt,
      Value<int> updatedAt,
    });

class $$SettingsTableTableFilterComposer
    extends Composer<_$SahaiDatabase, $SettingsTableTable> {
  $$SettingsTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get dayStartMinutes => $composableBuilder(
    column: $table.dayStartMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get presets => $composableBuilder(
    column: $table.presets,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get exactReminders => $composableBuilder(
    column: $table.exactReminders,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get defaultLeadDays => $composableBuilder(
    column: $table.defaultLeadDays,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnFilters(column),
  );
}

class $$SettingsTableTableOrderingComposer
    extends Composer<_$SahaiDatabase, $SettingsTableTable> {
  $$SettingsTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get dayStartMinutes => $composableBuilder(
    column: $table.dayStartMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get presets => $composableBuilder(
    column: $table.presets,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get exactReminders => $composableBuilder(
    column: $table.exactReminders,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get defaultLeadDays => $composableBuilder(
    column: $table.defaultLeadDays,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<bool> get isDeleted => $composableBuilder(
    column: $table.isDeleted,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$SettingsTableTableAnnotationComposer
    extends Composer<_$SahaiDatabase, $SettingsTableTable> {
  $$SettingsTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<int> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<int> get dayStartMinutes => $composableBuilder(
    column: $table.dayStartMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<String> get presets =>
      $composableBuilder(column: $table.presets, builder: (column) => column);

  GeneratedColumn<bool> get notificationsEnabled => $composableBuilder(
    column: $table.notificationsEnabled,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get exactReminders => $composableBuilder(
    column: $table.exactReminders,
    builder: (column) => column,
  );

  GeneratedColumn<int> get reminderMinutes => $composableBuilder(
    column: $table.reminderMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get defaultLeadDays => $composableBuilder(
    column: $table.defaultLeadDays,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get onboardingDone => $composableBuilder(
    column: $table.onboardingDone,
    builder: (column) => column,
  );

  GeneratedColumn<bool> get isDeleted =>
      $composableBuilder(column: $table.isDeleted, builder: (column) => column);

  GeneratedColumn<int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumn<int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$SettingsTableTableTableManager
    extends
        RootTableManager<
          _$SahaiDatabase,
          $SettingsTableTable,
          SettingsRow,
          $$SettingsTableTableFilterComposer,
          $$SettingsTableTableOrderingComposer,
          $$SettingsTableTableAnnotationComposer,
          $$SettingsTableTableCreateCompanionBuilder,
          $$SettingsTableTableUpdateCompanionBuilder,
          (
            SettingsRow,
            BaseReferences<_$SahaiDatabase, $SettingsTableTable, SettingsRow>,
          ),
          SettingsRow,
          PrefetchHooks Function()
        > {
  $$SettingsTableTableTableManager(
    _$SahaiDatabase db,
    $SettingsTableTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$SettingsTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$SettingsTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$SettingsTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayStartMinutes = const Value.absent(),
                Value<String?> presets = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> exactReminders = const Value.absent(),
                Value<int> reminderMinutes = const Value.absent(),
                Value<int> defaultLeadDays = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                Value<int> createdAt = const Value.absent(),
                Value<int> updatedAt = const Value.absent(),
              }) => SettingsTableCompanion(
                id: id,
                dayStartMinutes: dayStartMinutes,
                presets: presets,
                notificationsEnabled: notificationsEnabled,
                exactReminders: exactReminders,
                reminderMinutes: reminderMinutes,
                defaultLeadDays: defaultLeadDays,
                onboardingDone: onboardingDone,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          createCompanionCallback:
              ({
                Value<int> id = const Value.absent(),
                Value<int> dayStartMinutes = const Value.absent(),
                Value<String?> presets = const Value.absent(),
                Value<bool> notificationsEnabled = const Value.absent(),
                Value<bool> exactReminders = const Value.absent(),
                Value<int> reminderMinutes = const Value.absent(),
                Value<int> defaultLeadDays = const Value.absent(),
                Value<bool> onboardingDone = const Value.absent(),
                Value<bool> isDeleted = const Value.absent(),
                required int createdAt,
                required int updatedAt,
              }) => SettingsTableCompanion.insert(
                id: id,
                dayStartMinutes: dayStartMinutes,
                presets: presets,
                notificationsEnabled: notificationsEnabled,
                exactReminders: exactReminders,
                reminderMinutes: reminderMinutes,
                defaultLeadDays: defaultLeadDays,
                onboardingDone: onboardingDone,
                isDeleted: isDeleted,
                createdAt: createdAt,
                updatedAt: updatedAt,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable<$SettingsTableTable, SettingsRow>(table),
                  BaseReferences<
                    _$SahaiDatabase,
                    $SettingsTableTable,
                    SettingsRow
                  >(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$SettingsTableTableProcessedTableManager =
    ProcessedTableManager<
      _$SahaiDatabase,
      $SettingsTableTable,
      SettingsRow,
      $$SettingsTableTableFilterComposer,
      $$SettingsTableTableOrderingComposer,
      $$SettingsTableTableAnnotationComposer,
      $$SettingsTableTableCreateCompanionBuilder,
      $$SettingsTableTableUpdateCompanionBuilder,
      (
        SettingsRow,
        BaseReferences<_$SahaiDatabase, $SettingsTableTable, SettingsRow>,
      ),
      SettingsRow,
      PrefetchHooks Function()
    >;

class $SahaiDatabaseManager {
  final _$SahaiDatabase _db;
  $SahaiDatabaseManager(this._db);
  $$NodesTableTableManager get nodes =>
      $$NodesTableTableManager(_db, _db.nodes);
  $$ContextGroupsTableTableManager get contextGroups =>
      $$ContextGroupsTableTableManager(_db, _db.contextGroups);
  $$SummarySlotsTableTableManager get summarySlots =>
      $$SummarySlotsTableTableManager(_db, _db.summarySlots);
  $$EventsTableTableManager get events =>
      $$EventsTableTableManager(_db, _db.events);
  $$CapturesTableTableManager get captures =>
      $$CapturesTableTableManager(_db, _db.captures);
  $$SettingsTableTableTableManager get settingsTable =>
      $$SettingsTableTableTableManager(_db, _db.settingsTable);
}
