import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../engine/scope.dart';
import '../../engine/time.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../../shared/time_format.dart';
import '../explorer/explorer_rows.dart';

/// What the user chose in the set-aside picker.
class SetAsideChoice {
  const SetAsideChoice({
    required this.target,
    required this.level,
    required this.until,
    required this.preset,
    required this.remind,
  });

  /// The node that gets the wake time: the item or one of its parents.
  final TreeNode target;
  final SetAsideLevel level;
  final DateTime until;

  /// Null for a custom date and time.
  final Preset? preset;
  final bool remind;
}

/// The set-aside picker (frames 2 to 4): what to set aside, the presets
/// with their real times, Custom, and Remind me. One tap on a preset
/// chooses it; there is no Save button.
///
/// [withScope] shows the scope dropdown, for cards on the Summary; the
/// Explorer picks the node directly. [changeTime] is the Change time
/// variant (frame 9), which keeps Remind me as it was and so hides it.
Future<SetAsideChoice?> showSetAsidePicker(
  BuildContext context, {
  required Tree tree,
  required TreeNode node,
  required Clock clock,
  int dayStartMinutes = defaultDayStartMinutes,
  bool withScope = true,
  bool changeTime = false,
}) => showModalBottomSheet<SetAsideChoice>(
  context: context,
  isScrollControlled: true,
  useSafeArea: true,
  showDragHandle: true,
  builder: (context) => _PickerSheet(
    tree: tree,
    node: node,
    clock: clock,
    dayStartMinutes: dayStartMinutes,
    withScope: withScope && !changeTime,
    changeTime: changeTime,
  ),
);

class _PickerSheet extends StatefulWidget {
  const _PickerSheet({
    required this.tree,
    required this.node,
    required this.clock,
    required this.dayStartMinutes,
    required this.withScope,
    required this.changeTime,
  });

  final Tree tree;
  final TreeNode node;
  final Clock clock;
  final int dayStartMinutes;
  final bool withScope;
  final bool changeTime;

  @override
  State<_PickerSheet> createState() => _PickerSheetState();
}

class _PickerSheetState extends State<_PickerSheet> {
  late final List<ScopeOption> _scopes = widget.withScope
      ? setAsideScopes(widget.tree, widget.node.id)
      : [ScopeOption(widget.node, SetAsideLevel.item)];
  var _scope = 0;

  // On each time the picker opens; not remembered (M3 wireframe choice).
  var _remind = true;

  void _choose(DateTime until, Preset? preset) {
    final scope = _scopes[_scope];
    Navigator.of(context).pop(
      SetAsideChoice(
        target: scope.node,
        level: scope.level,
        until: until,
        preset: preset,
        remind: _remind,
      ),
    );
  }

  Future<void> _custom() async {
    final until = await pickCustomTime(context, widget.clock);
    if (until != null && mounted) _choose(until, null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final now = widget.clock.now();
    final presets = presetsAt(now, dayStartMinutes: widget.dayStartMinutes);
    return SingleChildScrollView(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 0, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.changeTime
                      ? Strings.changeTime
                      : Strings.setAsideTitle,
                  style: theme.textTheme.titleLarge,
                ),
                Text(
                  displayTitle(widget.tree, widget.node),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
          ),
          if (_scopes.length > 1)
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 4, 24, 8),
              child: _ScopeField(
                tree: widget.tree,
                item: widget.node,
                scopes: _scopes,
                selected: _scope,
                onChanged: (i) => setState(() => _scope = i),
              ),
            ),
          for (final p in presets)
            ListTile(
              leading: Icon(_presetIcon(p.preset)),
              // The time sits at the right, or wraps under the name when
              // large text leaves no room beside it.
              title: Wrap(
                alignment: WrapAlignment.spaceBetween,
                spacing: 12,
                children: [
                  Text(Strings.presetName(p.preset)),
                  Text(
                    wakeLabel(p.wakeAt, now, tonight: false),
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onTap: () => _choose(p.wakeAt, p.preset),
            ),
          ListTile(
            leading: const Icon(Icons.edit_calendar_outlined),
            title: const Text(Strings.customDateTime),
            contentPadding: const EdgeInsets.symmetric(horizontal: 24),
            onTap: _custom,
          ),
          if (!widget.changeTime) ...[
            const Divider(height: 1, indent: 24, endIndent: 24),
            SwitchListTile(
              secondary: const Icon(Icons.notifications_outlined),
              title: const Text(Strings.remindMe),
              subtitle: const Text(Strings.remindMeHint),
              value: _remind,
              contentPadding: const EdgeInsets.symmetric(horizontal: 24),
              onChanged: (on) => setState(() => _remind = on),
            ),
          ],
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

IconData _presetIcon(Preset preset) => switch (preset) {
  Preset.tonight => Icons.bedtime_outlined,
  Preset.tomorrowMorning => Icons.wb_twilight,
  Preset.threeDaysLater => Icons.calendar_month_outlined,
  Preset.nextWeek => Icons.next_week_outlined,
};

/// The scope dropdown (frame 3): each option names the node it sets aside.
class _ScopeField extends StatelessWidget {
  const _ScopeField({
    required this.tree,
    required this.item,
    required this.scopes,
    required this.selected,
    required this.onChanged,
  });

  final Tree tree;
  final TreeNode item;
  final List<ScopeOption> scopes;
  final int selected;
  final ValueChanged<int> onChanged;

  String _label(ScopeOption o) => Strings.scopeLabel(o.level, item.type);

  String _detail(ScopeOption o) {
    final title = displayTitle(tree, o.node);
    return o.level == SetAsideLevel.domain
        ? Strings.withEverythingInIt(title)
        : title;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DropdownButtonFormField<int>(
      initialValue: selected,
      isExpanded: true,
      itemHeight: null,
      decoration: const InputDecoration(
        labelText: Strings.whatToSetAside,
        border: OutlineInputBorder(),
      ),
      selectedItemBuilder: (context) => [
        for (final o in scopes)
          Align(alignment: Alignment.centerLeft, child: Text(_label(o))),
      ],
      items: [
        for (final (i, o) in scopes.indexed)
          DropdownMenuItem(
            value: i,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(_label(o)),
                  Text(
                    _detail(o),
                    style: theme.textTheme.bodySmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
      ],
      onChanged: (i) {
        if (i != null) onChanged(i);
      },
    );
  }
}

/// Custom date and time (frames 5 and 6): Android's date picker with past
/// days greyed, then a time step that won't accept a time already past.
/// Returns the chosen moment, or null if the user backs out.
Future<DateTime?> pickCustomTime(BuildContext context, Clock clock) async {
  final now = clock.now().toLocal();
  final today = DateTime(now.year, now.month, now.day);
  final date = await showDatePicker(
    context: context,
    initialDate: today,
    currentDate: today,
    firstDate: today,
    lastDate: DateTime(now.year + 2, now.month, now.day),
  );
  if (date == null || !context.mounted) return null;
  return showDialog<DateTime>(
    context: context,
    builder: (context) => CustomTimeDialog(date: date, clock: clock),
  );
}

/// The time step of Custom (frame 6). Android's own time picker can't
/// refuse a time, so this dialog does the typing itself, says "Pick a time
/// after 3:00 PM" for a past time on today, and keeps OK disabled until the
/// time is in the future (AT-045). The clock button opens Android's dial.
class CustomTimeDialog extends StatefulWidget {
  const CustomTimeDialog({super.key, required this.date, required this.clock});

  /// The chosen day, as local midnight.
  final DateTime date;
  final Clock clock;

  @override
  State<CustomTimeDialog> createState() => _CustomTimeDialogState();
}

class _CustomTimeDialogState extends State<CustomTimeDialog> {
  final _hour = TextEditingController();
  final _minute = TextEditingController();
  var _pm = false;

  @override
  void initState() {
    super.initState();
    _set(_initialTime());
  }

  /// The next whole hour on today, otherwise 8:00 AM like the presets.
  TimeOfDay _initialTime() {
    final now = widget.clock.now().toLocal();
    final isToday =
        widget.date.year == now.year &&
        widget.date.month == now.month &&
        widget.date.day == now.day;
    if (!isToday) return const TimeOfDay(hour: 8, minute: 0);
    if (now.hour == 23) return const TimeOfDay(hour: 23, minute: 59);
    return TimeOfDay(hour: now.hour + 1, minute: 0);
  }

  void _set(TimeOfDay time) {
    final h12 = time.hourOfPeriod == 0 ? 12 : time.hourOfPeriod;
    _hour.text = h12.toString().padLeft(2, '0');
    _minute.text = time.minute.toString().padLeft(2, '0');
    _pm = time.period == DayPeriod.pm;
  }

  /// The typed moment, or null when the fields don't make a time.
  DateTime? get _chosen {
    final h = int.tryParse(_hour.text);
    final m = int.tryParse(_minute.text);
    if (h == null || m == null || h < 1 || h > 12 || m < 0 || m > 59) {
      return null;
    }
    final hour24 = h % 12 + (_pm ? 12 : 0);
    final d = widget.date;
    return DateTime(d.year, d.month, d.day, hour24, m);
  }

  String? get _error {
    final chosen = _chosen;
    if (chosen == null) return Strings.invalidTime;
    final now = widget.clock.now();
    if (!isValidWakeTime(chosen, now)) {
      return Strings.pickTimeAfter(clockTime(now));
    }
    return null;
  }

  Future<void> _dial() async {
    final chosen = _chosen;
    final picked = await showTimePicker(
      context: context,
      initialTime: chosen == null
          ? _initialTime()
          : TimeOfDay.fromDateTime(chosen),
    );
    if (picked != null && mounted) setState(() => _set(picked));
  }

  @override
  void dispose() {
    _hour.dispose();
    _minute.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final error = _error;
    Widget field(TextEditingController controller, String label) => Expanded(
      child: TextField(
        controller: controller,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 2,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        style: theme.textTheme.displaySmall,
        decoration: InputDecoration(
          border: const OutlineInputBorder(),
          counterText: '',
          helperText: label,
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
    return AlertDialog(
      title: Text(
        Strings.enterTime(shortDate(widget.date)),
        style: theme.textTheme.labelLarge,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              field(_hour, Strings.hour),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(':', style: theme.textTheme.displaySmall),
              ),
              field(_minute, Strings.minute),
              const SizedBox(width: 8),
              ToggleButtons(
                direction: Axis.vertical,
                isSelected: [!_pm, _pm],
                onPressed: (i) => setState(() => _pm = i == 1),
                children: const [Text(Strings.am), Text(Strings.pm)],
              ),
            ],
          ),
          if (error != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      error,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.schedule),
          tooltip: Strings.chooseOnClock,
          onPressed: _dial,
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Strings.cancel),
        ),
        TextButton(
          onPressed: error == null
              ? () => Navigator.of(context).pop(_chosen)
              : null,
          child: const Text(Strings.ok),
        ),
      ],
    );
  }
}
