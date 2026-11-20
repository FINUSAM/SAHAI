import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../data/onboarding.dart';
import '../shared/strings.dart';
import 'providers.dart';
import 'reminder_sync.dart';
import 'router.dart';
import 'summary_refresher.dart';
import 'theme.dart';

class SahaiApp extends ConsumerStatefulWidget {
  const SahaiApp({super.key});

  @override
  ConsumerState<SahaiApp> createState() => _SahaiAppState();
}

class _SahaiAppState extends ConsumerState<SahaiApp> {
  /// Built once the first-run check is done, so the app opens straight on
  /// onboarding or the Summary, never one and then the other.
  GoRouter? _router;

  @override
  void initState() {
    super.initState();
    _start();
  }

  Future<void> _start() async {
    var onboarding = false;
    try {
      onboarding = await needsOnboarding(ref.read(databaseProvider));
    } on Exception catch (e) {
      // The Summary is always a safe place to start.
      debugPrint('First-run check failed: ${e.runtimeType}');
    }
    if (!mounted) return;
    setState(() => _router = buildRouter(onboarding: onboarding));
  }

  /// A single item's notification opens it on the Summary; a grouped one
  /// opens the Summary (M3 wireframe choice, AT-051).
  void _openFromNotification(String? nodeId) => _router?.go(
    nodeId == null ? Routes.summary : Routes.summaryFocus(nodeId),
  );

  @override
  void dispose() {
    _router?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = _router;
    if (router == null) {
      // A moment's blank screen in the theme's colour while the database
      // opens.
      final brightness = View.of(context).platformDispatcher.platformBrightness;
      return ColoredBox(color: buildTheme(brightness).colorScheme.surface);
    }
    return MaterialApp.router(
      title: Strings.appName,
      theme: buildTheme(Brightness.light),
      darkTheme: buildTheme(Brightness.dark),
      routerConfig: router,
      builder: (context, child) => SummaryRefresher(
        child: ReminderSync(onOpen: _openFromNotification, child: child!),
      ),
    );
  }
}
