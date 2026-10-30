import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../engine/node_type.dart';
import '../features/explorer/explorer_screen.dart';
import '../features/explorer/move_screen.dart';
import '../features/explorer/node_form_screen.dart';
import '../features/explorer/reorder_screen.dart';
import '../features/placeholders/coming_later_screen.dart';
import '../shared/strings.dart';
import 'home_shell.dart';

/// Paths, so screens never spell them out by hand.
abstract final class Routes {
  static const summary = '/summary';
  static const setAside = '/set-aside';
  static const explorer = '/explorer';
  static const capture = '/capture';
  static const settings = '/settings';

  static String newNode(NodeType type, String? parentId) => Uri(
    path: '/nodes/new',
    queryParameters: {'type': type.dbName, 'parent': ?parentId},
  ).toString();

  static String editNode(String id) => '/nodes/$id/edit';

  static String moveNode(String id) => '/nodes/$id/move';

  /// Reorders [parentId]'s children; no parent means the domains.
  static String reorder(String? parentId) => Uri(
    path: '/nodes/reorder',
    queryParameters: {'parent': ?parentId},
  ).toString();
}

GoRouter buildRouter() {
  final rootKey = GlobalKey<NavigatorState>();
  return GoRouter(
    navigatorKey: rootKey,
    // The Summary becomes the start screen once it exists (M2).
    initialLocation: Routes.explorer,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          _tab(
            Routes.summary,
            const ComingLaterScreen(
              title: Strings.summary,
              milestone: 'M2',
              body: Strings.summaryLater,
            ),
          ),
          _tab(
            Routes.setAside,
            const ComingLaterScreen(
              title: Strings.setAside,
              milestone: 'M3',
              body: Strings.setAsideLater,
            ),
          ),
          _tab(Routes.explorer, const ExplorerScreen()),
          _tab(
            Routes.capture,
            const ComingLaterScreen(
              title: Strings.capture,
              milestone: 'M6',
              body: Strings.captureLater,
            ),
          ),
        ],
      ),
      // Full-screen routes, drawn over the bottom tabs.
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const ComingLaterScreen(
          title: Strings.settings,
          milestone: 'M7',
          body: Strings.settingsLater,
          showSettings: false,
        ),
      ),
      GoRoute(
        path: '/nodes/new',
        parentNavigatorKey: rootKey,
        builder: (context, state) => NodeFormScreen.create(
          type: NodeType.fromDbName(state.uri.queryParameters['type']!),
          parentId: state.uri.queryParameters['parent'],
        ),
      ),
      GoRoute(
        path: '/nodes/reorder',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            ReorderScreen(parentId: state.uri.queryParameters['parent']),
      ),
      GoRoute(
        path: '/nodes/:id/edit',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            NodeFormScreen.edit(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/nodes/:id/move',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            MoveScreen(id: state.pathParameters['id']!),
      ),
    ],
  );
}

StatefulShellBranch _tab(String path, Widget screen) => StatefulShellBranch(
  routes: [GoRoute(path: path, builder: (context, state) => screen)],
);
