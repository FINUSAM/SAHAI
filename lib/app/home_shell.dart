import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../shared/strings.dart';
import 'router.dart';

/// The four bottom tabs (frame 1). Each tab keeps its own place.
class HomeShell extends StatelessWidget {
  const HomeShell({super.key, required this.shell});

  final StatefulNavigationShell shell;

  @override
  Widget build(BuildContext context) => Scaffold(
    body: shell,
    bottomNavigationBar: NavigationBar(
      selectedIndex: shell.currentIndex,
      onDestinationSelected: (i) =>
          shell.goBranch(i, initialLocation: i == shell.currentIndex),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.format_list_bulleted),
          label: Strings.summary,
        ),
        NavigationDestination(
          icon: Icon(Icons.schedule),
          label: Strings.setAside,
        ),
        NavigationDestination(
          icon: Icon(Icons.account_tree_outlined),
          selectedIcon: Icon(Icons.account_tree),
          label: Strings.explorer,
        ),
        NavigationDestination(
          icon: Icon(Icons.inbox_outlined),
          selectedIcon: Icon(Icons.inbox),
          label: Strings.capture,
        ),
      ],
    ),
  );
}

/// The Settings gear at the top right of every tab.
class SettingsButton extends StatelessWidget {
  const SettingsButton({super.key});

  @override
  Widget build(BuildContext context) => IconButton(
    icon: const Icon(Icons.settings_outlined),
    tooltip: Strings.settings,
    onPressed: () => context.push(Routes.settings),
  );
}
