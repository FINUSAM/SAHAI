import 'package:flutter/material.dart';

import '../../engine/due.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';

/// A one-off item's due date and Remind me choice while a form is open
/// (E-019). [dueOn] is null when there is no due date.
class DueDraft {
  const DueDraft({this.dueOn, this.reminder = DueReminder.onTheDay});

  final DateTime? dueOn;
  final DueReminder reminder;

  @override
  bool operator ==(Object other) =>
      other is DueDraft && other.dueOn == dueOn && other.reminder == reminder;

  @override
  int get hashCode => Object.hash(dueOn, reminder);
}

/// When [reminder] for [dueOn] arrives, or null for No reminder.
DateTime? reminderMoment(
  DateTime dueOn,
  DueReminder reminder, {
  required int reminderMinutes,
  required int dayStartMinutes,
}) => switch (reminder.daysBefore) {
  final days? => dueReminderAt(
    dueOn,
    days,
    reminderMinutes: reminderMinutes,
    dayStartMinutes: dayStartMinutes,
  ),
  null => null,
};

/// The Due date row, and once a date is set, the Remind me row and a tip
/// (M7 frames 19 and 21). Days before [today] can't be picked; a date
/// already in the past stays as it is until it's changed.
class DueDateFields extends StatelessWidget {
  const DueDateFields({
    super.key,
    required this.draft,
    required this.today,
    required this.now,
    required this.reminderMinutes,
    required this.dayStartMinutes,
    required this.onChanged,
  });

  final DueDraft draft;

  /// The logical date, by Day starts at.
  final DateTime today;
  final DateTime now;
  final int reminderMinutes;
  final int dayStartMinutes;
  final ValueChanged<DueDraft> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dueOn = draft.dueOn;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ListTile(
          contentPadding: EdgeInsets.zero,
          leading: const Icon(Icons.calendar_today_outlined),
          title: const Text(Strings.dueDate),
          subtitle: dueOn == null
              ? const Text(Strings.dueDateNone)
              : Text(
                  shortDueDate(dueOn, today),
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
          trailing: dueOn == null
              ? TextButton(
                  onPressed: () => _pickDate(context),
                  child: const Text(
                    Strings.addDueDate,
                    semanticsLabel: Strings.addDueDateLabel,
                  ),
                )
              : IconButton(
                  icon: const Icon(Icons.close),
                  tooltip: Strings.clearDueDate,
                  onPressed: () => onChanged(const DueDraft()),
                ),
          onTap: () => _pickDate(context),
        ),
        if (dueOn != null) ...[
          const Divider(height: 1),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.notifications_none),
            title: const Text(Strings.remindMe),
            subtitle: Text(_reminderLine(dueOn)),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _pickReminder(context, dueOn),
          ),
          if (_tip(dueOn) case final tip?)
            Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(tip, style: theme.textTheme.bodyMedium),
            ),
        ],
      ],
    );
  }

  /// "3 days before · Tue, Nov 17, 9:00 AM", or "No reminder".
  String _reminderLine(DateTime dueOn) {
    final at = reminderMoment(
      dueOn,
      draft.reminder,
      reminderMinutes: reminderMinutes,
      dayStartMinutes: dayStartMinutes,
    );
    final name = Strings.dueReminderName(draft.reminder);
    if (at == null) return name;
    return Strings.remindAt(
      name,
      '${shortDueDate(at, today)}, ${minutesClock(reminderMinutes)}',
    );
  }

  String? _tip(DateTime dueOn) => switch (draft.reminder) {
    DueReminder.none => null,
    DueReminder.onTheDay => Strings.dueTipOnTheDay,
    _ => Strings.dueTipEarly(shortDueDate(dueOn, today)),
  };

  Future<void> _pickDate(BuildContext context) async {
    final current = draft.dueOn;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? today,
      // An overdue date stays on the calendar it's shown on, but only it
      // and today onwards can be picked (E-019).
      firstDate: current != null && current.isBefore(today) ? current : today,
      lastDate: DateTime(today.year + 10, today.month, today.day),
      selectableDayPredicate: (day) => !day.isBefore(today) || day == current,
    );
    if (picked == null) return;
    final due = DateTime(picked.year, picked.month, picked.day);
    // An early reminder the new date has put in the past falls back to
    // On the day, which is never earlier than the date itself.
    final at = reminderMoment(
      due,
      draft.reminder,
      reminderMinutes: reminderMinutes,
      dayStartMinutes: dayStartMinutes,
    );
    final reminder =
        at != null && !at.isAfter(now) && draft.reminder.daysBefore! > 0
        ? DueReminder.onTheDay
        : draft.reminder;
    onChanged(DueDraft(dueOn: due, reminder: reminder));
  }

  Future<void> _pickReminder(BuildContext context, DateTime dueOn) async {
    final picked = await showRemindMeSheet(
      context,
      dueOn: dueOn,
      current: draft.reminder,
      today: today,
      now: now,
      reminderMinutes: reminderMinutes,
      dayStartMinutes: dayStartMinutes,
    );
    if (picked != null) onChanged(DueDraft(dueOn: dueOn, reminder: picked));
  }
}

/// The five Remind me choices with their dates; a choice already in the
/// past is greyed and can't be picked (M7 frame 22).
Future<DueReminder?> showRemindMeSheet(
  BuildContext context, {
  required DateTime dueOn,
  required DueReminder current,
  required DateTime today,
  required DateTime now,
  required int reminderMinutes,
  required int dayStartMinutes,
}) => showModalBottomSheet<DueReminder>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      child: RadioGroup<DueReminder>(
        groupValue: current,
        onChanged: (value) {
          if (value != null) Navigator.of(context).pop(value);
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(Strings.remindMe, style: theme.textTheme.headlineSmall),
                  Text(
                    Strings.dueOnDay(shortDueDate(dueOn, today)),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
            for (final choice in DueReminder.values)
              _choiceTile(
                theme,
                choice,
                at: reminderMoment(
                  dueOn,
                  choice,
                  reminderMinutes: reminderMinutes,
                  dayStartMinutes: dayStartMinutes,
                ),
                today: today,
                now: now,
                selected: choice == current,
              ),
            const Divider(indent: 24, endIndent: 24),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
              child: Text(
                Strings.remindSheetFooter(minutesClock(reminderMinutes)),
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  },
);

Widget _choiceTile(
  ThemeData theme,
  DueReminder choice, {
  required DateTime? at,
  required DateTime today,
  required DateTime now,
  required bool selected,
}) {
  // On the day stays pickable even late on the due day: the reminder is
  // then simply skipped, and the label still shows.
  final past = at != null && !at.isAfter(now) && (choice.daysBefore ?? 0) > 0;
  return RadioListTile<DueReminder>(
    value: choice,
    enabled: !past,
    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
    title: Text(
      Strings.dueReminderName(choice),
      style: selected ? const TextStyle(fontWeight: FontWeight.w700) : null,
    ),
    secondary: at == null ? null : Text(shortDueDate(at, today)),
  );
}
