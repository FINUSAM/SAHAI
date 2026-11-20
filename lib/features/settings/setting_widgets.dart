import 'package:flutter/material.dart';

import '../../shared/strings.dart';

/// A section heading on the Settings screens.
class SettingsSection extends StatelessWidget {
  const SettingsSection(this.text, {super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      header: true,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
        child: Text(
          text.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(
            letterSpacing: 0.8,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}

/// A Settings row with a label, a line saying what it does, and its value
/// on the right. At the largest font sizes the value moves below the label
/// so nothing is cut off (M7 frame 18).
class SettingValueRow extends StatelessWidget {
  const SettingValueRow({
    super.key,
    required this.title,
    required this.value,
    this.subtitle,
    this.leading,
    this.onTap,
  });

  final String title;
  final String value;
  final String? subtitle;
  final Widget? leading;
  final VoidCallback? onTap;

  /// Above this text scale the value goes on its own line.
  static const stackAt = 1.5;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stacked = MediaQuery.textScalerOf(context).scale(10) / 10 > stackAt;
    final valueText = Text(value, style: theme.textTheme.bodyLarge);
    return ListTile(
      leading: leading,
      title: Text(title),
      subtitle: stacked
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) Text(subtitle!),
                const SizedBox(height: 4),
                DefaultTextStyle.merge(
                  style: TextStyle(color: theme.colorScheme.onSurface),
                  child: valueText,
                ),
              ],
            )
          : subtitle == null
          ? null
          : Text(subtitle!),
      trailing: stacked ? null : valueText,
      onTap: onTap,
    );
  }
}

/// A dialog that asks for a whole number of days, 0 or more.
Future<int?> askDays(
  BuildContext context, {
  required String title,
  required int initial,
}) => showDialog<int>(
  context: context,
  builder: (context) => _DaysDialog(title: title, initial: initial),
);

class _DaysDialog extends StatefulWidget {
  const _DaysDialog({required this.title, required this.initial});

  final String title;
  final int initial;

  @override
  State<_DaysDialog> createState() => _DaysDialogState();
}

class _DaysDialogState extends State<_DaysDialog> {
  late final _controller = TextEditingController(text: '${widget.initial}');

  int? get _value {
    final value = int.tryParse(_controller.text.trim());
    return value != null && value >= 0 ? value : null;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final value = _value;
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        keyboardType: TextInputType.number,
        decoration: InputDecoration(
          labelText: Strings.daysLabel,
          errorText: value == null ? Strings.leadError : null,
        ),
        onChanged: (_) => setState(() {}),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(Strings.cancel),
        ),
        FilledButton(
          // Reads the field when tapped, not the value from the last build.
          onPressed: value == null
              ? null
              : () => Navigator.of(context).pop(_value),
          child: const Text(Strings.ok),
        ),
      ],
    );
  }
}

/// Android's time picker, opened in typing mode (M7 frame 12).
Future<int?> askTimeOfDay(
  BuildContext context, {
  required int initialMinutes,
  String? helpText,
}) async {
  final picked = await showTimePicker(
    context: context,
    initialTime: TimeOfDay(
      hour: initialMinutes ~/ 60,
      minute: initialMinutes % 60,
    ),
    initialEntryMode: TimePickerEntryMode.input,
    helpText: helpText,
  );
  return picked == null ? null : picked.hour * 60 + picked.minute;
}
