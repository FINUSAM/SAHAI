import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/strings.dart';
import 'router.dart';
import 'summary_refresher.dart';
import 'theme.dart';

class SahaiApp extends StatefulWidget {
  const SahaiApp({super.key});

  @override
  State<SahaiApp> createState() => _SahaiAppState();
}

class _SahaiAppState extends State<SahaiApp> {
  final GoRouter _router = buildRouter();

  @override
  void dispose() {
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    title: Strings.appName,
    theme: buildTheme(Brightness.light),
    darkTheme: buildTheme(Brightness.dark),
    routerConfig: _router,
    builder: (context, child) => SummaryRefresher(child: child!),
  );
}
