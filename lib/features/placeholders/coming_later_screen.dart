import 'package:flutter/material.dart';

import '../../app/home_shell.dart';
import '../../shared/strings.dart';

/// Stands in for a screen that a later milestone builds.
class ComingLaterScreen extends StatelessWidget {
  const ComingLaterScreen({
    super.key,
    required this.title,
    required this.milestone,
    required this.body,
    this.showSettings = true,
  });

  final String title;
  final String milestone;
  final String body;
  final bool showSettings;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [if (showSettings) const SettingsButton()],
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                Strings.comingIn(milestone),
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                body,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
