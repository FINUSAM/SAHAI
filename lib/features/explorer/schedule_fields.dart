import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../engine/recurrence.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';

/// The most days each month can have, for the day list of a yearly schedule.
const _daysInMonth = [31, 29, 31, 30, 31, 30, 31, 31, 30, 31, 30, 31];

/// What the schedule fields hold while the form is open. [interval] and
/// [leadDays] are null while their fields can't be read as a number.
class ScheduleDraft {
  const ScheduleDraft({
    required this.frequency,
    required this.interval,
    required this.weekdays,
    required this.day,
    required this.month,
    required this.repeatFrom,
    required this.dueOn,
    required this.duePicked,
    required this.leadDays,
  });

  /// A new schedule: monthly, on today's date (M4 frames 2, 3).
  factory ScheduleDraft.start(DateTime today, {required int leadDays}) =>
      ScheduleDraft(
        frequency: Frequency.monthly,
        interval: 1,
        weekdays: const {},
        day: today.day,
        month: today.month,
        repeatFrom: RepeatFrom.dueDate,
        dueOn: today,
        duePicked: false,
        leadDays: leadDays,
      );

  /// The schedule [node] has now. Its due date stays until the schedule
  /// itself is changed.
  factory ScheduleDraft.of(TreeNode node, {required int defaultLeadDays}) {
    final schedule = node.schedule!;
    final dueOn = node.dueOn!;
    final dated =
        schedule.frequency == Frequency.monthly ||
        schedule.frequency == Frequency.yearly;
    return ScheduleDraft(
      frequency: schedule.frequency,
      interval: schedule.interval,
      weekdays: schedule.frequency == Frequency.weekly
          ? schedule.days.toSet()
          : const {},
      day: dated ? schedule.days.first : dueOn.day,
      month: schedule.month ?? dueOn.month,
      repeatFrom: schedule.repeatFrom,
      dueOn: dueOn,
      duePicked: false,
      leadDays: node.leadDays ?? defaultLeadDays,
    );
  }

  final Frequency frequency;
  final int? interval;
  final Set<int> weekdays;
  final int day;
  final int month;
  final RepeatFrom repeatFrom;
  final DateTime dueOn;

  /// The user chose [dueOn] themselves, so a schedule change leaves it.
  final bool duePicked;
  final int? leadDays;

  bool get isValid => (interval ?? 0) >= 1 && leadDays != null;

  /// The first date doesn't depend on the interval, so this also works while
  /// that field is being retyped.
  Schedule get schedule {
    final every = interval ?? 1;
    return switch (frequency) {
      Frequency.daily => Schedule.daily(
        interval: every,
        repeatFrom: repeatFrom,
      ),
      Frequency.weekly => Schedule.weekly(
        weekdays: weekdays.toList()..sort(),
        interval: every,
        repeatFrom: repeatFrom,
      ),
      Frequency.monthly => Schedule.monthly(
        day: day,
        interval: every,
        repeatFrom: repeatFrom,
      ),
      Frequency.yearly => Schedule.yearly(
        month: month,
        day: day,
        interval: every,
        repeatFrom: repeatFrom,
      ),
    };
  }

  /// With the schedule changed: Next due follows it, as the next matching
  /// date, until the user picks one (M4 wireframe choice).
  ScheduleDraft withSchedule({
    required DateTime today,
    Frequency? frequency,
    Set<int>? weekdays,
    int? day,
    int? month,
  }) {
    final nextFrequency = frequency ?? this.frequency;
    final nextMonth = month ?? this.month;
    final draft = _copy(
      frequency: nextFrequency,
      weekdays: weekdays,
      month: nextMonth,
      day: min(
        day ?? this.day,
        nextFrequency == Frequency.yearly ? _daysInMonth[nextMonth - 1] : 31,
      ),
    );
    return duePicked
        ? draft
        : draft._copy(dueOn: draft.schedule.firstDue(today));
  }

  ScheduleDraft withInterval(int? value) => _copy(interval: () => value);

  ScheduleDraft withLeadDays(int? value) => _copy(leadDays: () => value);

  /// Switching to or from completion can change what Next due starts as
  /// (E-016), so it follows the schedule until the user picks a date.
  ScheduleDraft withRepeatFrom(RepeatFrom value, {required DateTime today}) {
    final draft = _copy(repeatFrom: value);
    return duePicked
        ? draft
        : draft._copy(dueOn: draft.schedule.firstDue(today));
  }

  ScheduleDraft withPickedDue(DateTime value) =>
      _copy(dueOn: value, duePicked: true);

  /// [interval] and [leadDays] are functions because null is a real value.
  ScheduleDraft _copy({
    Frequency? frequency,
    int? Function()? interval,
    Set<int>? weekdays,
    int? day,
    int? month,
    RepeatFrom? repeatFrom,
    DateTime? dueOn,
    bool? duePicked,
    int? Function()? leadDays,
  }) => ScheduleDraft(
    frequency: frequency ?? this.frequency,
    interval: interval == null ? this.interval : interval(),
    weekdays: weekdays ?? this.weekdays,
    day: day ?? this.day,
    month: month ?? this.month,
    repeatFrom: repeatFrom ?? this.repeatFrom,
    dueOn: dueOn ?? this.dueOn,
    duePicked: duePicked ?? this.duePicked,
    leadDays: leadDays == null ? this.leadDays : leadDays(),
  );
}

/// Every, Period, then On day or weekday buttons, Next due, Repeat from,
/// Show before due and when it will appear (M4 frames 3, 4).
class ScheduleFields extends StatefulWidget {
  const ScheduleFields({
    super.key,
    required this.draft,
    required this.today,
    required this.onChanged,
  });

  final ScheduleDraft draft;

  /// The logical date.
  final DateTime today;
  final ValueChanged<ScheduleDraft> onChanged;

  @override
  State<ScheduleFields> createState() => _ScheduleFieldsState();
}

class _ScheduleFieldsState extends State<ScheduleFields> {
  late final _every = TextEditingController(
    text: widget.draft.interval?.toString() ?? '',
  );
  late final _lead = TextEditingController(
    text: widget.draft.leadDays?.toString() ?? '',
  );

  ScheduleDraft get _draft => widget.draft;

  @override
  void dispose() {
    _every.dispose();
    _lead.dispose();
    super.dispose();
  }

  void _schedule({
    Frequency? frequency,
    Set<int>? weekdays,
    int? day,
    int? month,
  }) => widget.onChanged(
    _draft.withSchedule(
      today: widget.today,
      frequency: frequency,
      weekdays: weekdays,
      day: day,
      month: month,
    ),
  );

  Future<void> _pickDue() async {
    final today = widget.today;
    final picked = await showDatePicker(
      context: context,
      initialDate: _draft.dueOn,
      // An overdue date has to stay on the calendar it's shown on.
      firstDate: _draft.dueOn.isBefore(today) ? _draft.dueOn : today,
      lastDate: DateTime(today.year + 10, today.month, today.day),
    );
    if (picked != null) widget.onChanged(_draft.withPickedDue(picked));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hint = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final draft = _draft;
    final interval = draft.interval ?? 0;
    final countsFromFinish = draft.schedule.countsFromFinish;
    const gap = SizedBox(height: 16);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: _NumberField(
                controller: _every,
                label: Strings.every,
                error: interval < 1 ? Strings.everyError : null,
                onChanged: (v) => widget.onChanged(draft.withInterval(v)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 3,
              child: _Dropdown<Frequency>(
                label: Strings.period,
                value: draft.frequency,
                items: {
                  for (final f in Frequency.values)
                    f: Strings.periodName(f, interval: max(interval, 1)),
                },
                onChanged: (f) => _schedule(frequency: f),
              ),
            ),
          ],
        ),
        gap,
        if (draft.frequency == Frequency.weekly) ...[
          Text(Strings.onWeekdays, style: hint),
          const SizedBox(height: 8),
          _Weekdays(
            selected: draft.weekdays,
            onChanged: (days) => _schedule(weekdays: days),
          ),
          gap,
        ],
        // Repeating from completion counts from the finish day, so the day
        // and month don't apply (E-016).
        if (draft.frequency == Frequency.yearly && !countsFromFinish) ...[
          _Dropdown<int>(
            label: Strings.inMonth,
            value: draft.month,
            items: {for (var m = 1; m <= 12; m++) m: Strings.monthName(m)},
            onChanged: (m) => _schedule(month: m),
          ),
          gap,
        ],
        if ((draft.frequency == Frequency.monthly ||
                draft.frequency == Frequency.yearly) &&
            !countsFromFinish) ...[
          _Dropdown<int>(
            label: Strings.onDay,
            value: draft.day,
            items: {
              for (
                var d = 1;
                d <=
                    (draft.frequency == Frequency.yearly
                        ? _daysInMonth[draft.month - 1]
                        : 31);
                d++
              )
                d: '$d',
            },
            onChanged: (d) => _schedule(day: d),
          ),
          if (draft.frequency == Frequency.monthly) ...[
            const SizedBox(height: 8),
            Text(Strings.lastDayHint, style: hint),
          ],
          gap,
        ],
        InkWell(
          onTap: _pickDue,
          child: InputDecorator(
            decoration: const InputDecoration(
              labelText: Strings.nextDue,
              border: OutlineInputBorder(),
            ),
            child: Text(shortDate(draft.dueOn)),
          ),
        ),
        gap,
        Text(Strings.repeatFromLabel, style: hint),
        const SizedBox(height: 8),
        SegmentedButton<RepeatFrom>(
          showSelectedIcon: false,
          segments: const [
            ButtonSegment(
              value: RepeatFrom.dueDate,
              label: Text(Strings.dueDate),
            ),
            ButtonSegment(
              value: RepeatFrom.completionDate,
              label: Text(Strings.completionDate),
            ),
          ],
          selected: {draft.repeatFrom},
          onSelectionChanged: (s) => widget.onChanged(
            draft.withRepeatFrom(s.single, today: widget.today),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          draft.repeatFrom == RepeatFrom.dueDate
              ? Strings.fromDueHint
              : Strings.fromCompletionHint,
          style: hint,
        ),
        gap,
        _NumberField(
          controller: _lead,
          label: Strings.showBeforeDue,
          error: draft.leadDays == null ? Strings.leadError : null,
          onChanged: (v) => widget.onChanged(draft.withLeadDays(v)),
        ),
        if (draft.leadDays case final lead?) ...[
          const SizedBox(height: 8),
          Text(_appears(draft.dueOn, lead), style: hint),
        ],
      ],
    );
  }

  /// "Appears Wed, Dec 2", from the date it shows (M4 frame 3).
  String _appears(DateTime dueOn, int lead) {
    final show = DateTime(dueOn.year, dueOn.month, dueOn.day - lead);
    return show.isAfter(widget.today)
        ? Strings.appears(shortDate(show))
        : Strings.appearsToday;
  }
}

class _NumberField extends StatelessWidget {
  const _NumberField({
    required this.controller,
    required this.label,
    required this.error,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final String? error;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    keyboardType: TextInputType.number,
    inputFormatters: [
      FilteringTextInputFormatter.digitsOnly,
      LengthLimitingTextInputFormatter(3),
    ],
    decoration: InputDecoration(
      labelText: label,
      errorText: error,
      errorMaxLines: 2,
      border: const OutlineInputBorder(),
    ),
    onChanged: (text) => onChanged(int.tryParse(text)),
  );
}

class _Dropdown<T> extends StatelessWidget {
  const _Dropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String label;
  final T value;
  final Map<T, String> items;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<T>(
    // The field keeps its first value otherwise; a new month can change it.
    key: ValueKey(value),
    initialValue: value,
    isExpanded: true,
    decoration: InputDecoration(
      labelText: label,
      border: const OutlineInputBorder(),
    ),
    items: [
      for (final MapEntry(:key, value: text) in items.entries)
        DropdownMenuItem(value: key, child: Text(text)),
    ],
    onChanged: (v) {
      if (v != null) onChanged(v);
    },
  );
}

/// Round buttons for the days of a weekly schedule (M4 frame 4). None chosen
/// just counts weeks, like a haircut every 4 weeks (AT-069).
class _Weekdays extends StatelessWidget {
  const _Weekdays({required this.selected, required this.onChanged});

  final Set<int> selected;
  final ValueChanged<Set<int>> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Wrap(
      children: [
        for (var day = DateTime.monday; day <= DateTime.sunday; day++)
          Semantics(
            button: true,
            selected: selected.contains(day),
            label: Strings.weekdayName(day),
            excludeSemantics: true,
            child: InkResponse(
              onTap: () => onChanged(
                selected.contains(day)
                    ? ({...selected}..remove(day))
                    : {...selected, day},
              ),
              child: SizedBox.square(
                dimension: 48,
                child: Center(
                  child: CircleAvatar(
                    radius: 21,
                    backgroundColor: selected.contains(day)
                        ? colors.primary
                        : colors.surfaceContainerHighest,
                    foregroundColor: selected.contains(day)
                        ? colors.onPrimary
                        : colors.onSurface,
                    child: Text(Strings.weekdayButton(day)),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
