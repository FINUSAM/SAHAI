import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../actions/capture_actions.dart';
import '../../app/theme.dart';
import '../../data/app_database.dart';
import '../../data/database.dart';
import '../../shared/strings.dart';

/// What the dialog was opened with: text another app shared, if any, and
/// where it came from.
class CaptureRequest {
  const CaptureRequest({this.text, this.source = CaptureSource.widget});

  final String? text;
  final CaptureSource source;
}

/// The Android window around the dialog (`CaptureActivity`, decision 0007).
/// Tests use a fake.
abstract interface class CaptureHost {
  /// The shared text and the source.
  Future<CaptureRequest> request();

  /// Calls [onFocused] once the window has focus, the first moment Android
  /// accepts a request for the keyboard.
  void listen({required VoidCallback onFocused});

  /// Shows [message] as a toast and closes the window.
  Future<void> saved(String message);

  /// Closes the window without saving.
  Future<void> cancel();
}

/// Talks to `CaptureActivity.kt` over a method channel.
class ChannelCaptureHost implements CaptureHost {
  const ChannelCaptureHost();

  static const _channel = MethodChannel('sahai/capture_dialog');

  @override
  Future<CaptureRequest> request() async {
    final map = await _channel.invokeMapMethod<String, Object?>('request');
    return CaptureRequest(
      text: map?['text'] as String?,
      source: map?['source'] == CaptureSource.share.dbName
          ? CaptureSource.share
          : CaptureSource.widget,
    );
  }

  @override
  void listen({required VoidCallback onFocused}) =>
      _channel.setMethodCallHandler((call) async {
        if (call.method == 'focused') onFocused();
      });

  @override
  Future<void> saved(String message) =>
      _channel.invokeMethod<void>('saved', message);

  @override
  Future<void> cancel() => _channel.invokeMethod<void>('cancel');
}

/// Saves the dialog's text as a capture from [source].
typedef SaveCapture = Future<void> Function(String text, CaptureSource source);

/// Opens the shared database, adds the capture and its `captured` event in
/// one transaction (PRD 13), and closes it again. The database is opened
/// only for the save, so a cancelled dialog never touches it.
Future<void> saveToAppDatabase(
  String text,
  CaptureSource source, {
  SahaiDatabase Function() open = openAppDatabase,
  Clock clock = const Clock(),
}) async {
  final db = open();
  try {
    await CaptureActions(db, clock: clock).add(text, source: source);
  } finally {
    await db.close();
  }
}

/// Runs from `captureMain` in main.dart: only the theme and the dialog, not
/// the router, notifications or the rest of the app, so it opens quickly.
void runCaptureDialog() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    const CaptureDialogApp(host: ChannelCaptureHost(), save: saveToAppDatabase),
  );
}

class CaptureDialogApp extends StatelessWidget {
  const CaptureDialogApp({super.key, required this.host, required this.save});

  final CaptureHost host;
  final SaveCapture save;

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: Strings.appName,
    debugShowCheckedModeBanner: false,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    home: CaptureDialog(host: host, save: save),
  );
}

/// The small dialog over whatever is on screen (E-009, E-017, M6 frames 14
/// and 16). Tapping outside it does nothing, so a half-typed thought isn't
/// lost; Cancel and Back close it.
class CaptureDialog extends StatefulWidget {
  const CaptureDialog({super.key, required this.host, required this.save});

  final CaptureHost host;
  final SaveCapture save;

  @override
  State<CaptureDialog> createState() => _CaptureDialogState();
}

class _CaptureDialogState extends State<CaptureDialog> {
  final _text = TextEditingController();
  final _focus = FocusNode();
  var _source = CaptureSource.widget;
  var _saving = false;
  var _failed = false;

  @override
  void initState() {
    super.initState();
    widget.host.listen(onFocused: _showKeyboard);
    _load();
  }

  @override
  void dispose() {
    _text.dispose();
    _focus.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final request = await widget.host.request();
    if (!mounted) return;
    setState(() {
      _source = request.source;
      final shared = request.text;
      if (shared != null && _text.text.isEmpty) {
        _text.text = shared;
        _text.selection = TextSelection.collapsed(offset: shared.length);
      }
    });
  }

  // The field asks for the keyboard on Flutter's first frame, before
  // Android gives this see-through window focus, so Android ignores it.
  void _showKeyboard() {
    if (!mounted) return;
    if (_focus.hasFocus) {
      SystemChannels.textInput.invokeMethod<void>('TextInput.show');
    } else {
      _focus.requestFocus();
    }
  }

  Future<void> _save() async {
    setState(() {
      _saving = true;
      _failed = false;
    });
    try {
      await widget.save(_text.text, _source);
    } on Object {
      // Keep the text, so nothing typed is lost. The error isn't logged:
      // it could carry the capture's text.
      if (mounted) {
        setState(() {
          _saving = false;
          _failed = true;
        });
      }
      return;
    }
    await widget.host.saved(Strings.savedToCapture);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      // The window is see-through, so this dims the app underneath.
      backgroundColor: Colors.black54,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 56, 16, 16),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: Material(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(28),
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Semantics(
                        header: true,
                        child: Text(
                          Strings.capture,
                          style: theme.textTheme.headlineSmall,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: _text,
                        focusNode: _focus,
                        autofocus: true,
                        minLines: 3,
                        maxLines: 6,
                        keyboardType: TextInputType.multiline,
                        textInputAction: TextInputAction.newline,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          hintText: Strings.captureHint,
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_failed)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: Text(
                            Strings.captureSaveFailed,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      const SizedBox(height: 12),
                      OverflowBar(
                        alignment: MainAxisAlignment.end,
                        spacing: 8,
                        children: [
                          TextButton(
                            onPressed: _saving ? null : widget.host.cancel,
                            child: const Text(Strings.cancel),
                          ),
                          ValueListenableBuilder(
                            valueListenable: _text,
                            builder: (context, value, _) => FilledButton(
                              onPressed: value.text.trim().isEmpty || _saving
                                  ? null
                                  : _save,
                              child: const Text(Strings.save),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
