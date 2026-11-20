import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../engine/node_type.dart';
import '../features/capture/capture_screen.dart';
import '../features/capture/create_from_capture_screen.dart';
import '../features/capture/edit_capture_screen.dart';
import '../features/explorer/explorer_screen.dart';
import '../features/explorer/move_screen.dart';
import '../features/explorer/node_form_screen.dart';
import '../features/explorer/reorder_screen.dart';
import '../features/groups/group_form_screen.dart';
import '../features/groups/groups_screen.dart';
import '../features/set_aside/set_aside_screen.dart';
import '../features/settings/presets_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/summary/summary_screen.dart';
import 'home_shell.dart';

/// Paths, so screens never spell them out by hand.
abstract final class Routes {
  static const summary = '/summary';
  static const setAside = '/set-aside';
  static const explorer = '/explorer';
  static const capture = '/capture';
  static const settings = '/settings';
  static const presets = '/settings/presets';
  static const groups = '/settings/groups';
  static const newGroup = '/settings/groups/new';
  static String editGroup(String id) => '/settings/groups/$id';

  /// The Summary with [id]'s card highlighted, from a notification.
  static String summaryFocus(String id) =>
      Uri(path: summary, queryParameters: {'focus': id}).toString();

  static String newNode(NodeType type, String? parentId) => Uri(
    path: '/nodes/new',
    queryParameters: {'type': type.dbName, 'parent': ?parentId},
  ).toString();

  static String editNode(String id) => '/nodes/$id/edit';

  static String editCapture(String id) => '/capture/$id/edit';

  static String createFromCapture(String id) => '/capture/$id/create';

  /// The Explorer opened at [id], expanded and highlighted (frame 8).
  static String explorerNode(String id) =>
      Uri(path: explorer, queryParameters: {'node': id}).toString();

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
    // The Summary is the start screen (M2 wireframe choice).
    initialLocation: Routes.summary,
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => HomeShell(shell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.summary,
                builder: (context, state) => SummaryScreen(
                  focusNodeId: state.uri.queryParameters['focus'],
                ),
              ),
            ],
          ),
          _tab(Routes.setAside, const SetAsideScreen()),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: Routes.explorer,
                builder: (context, state) => ExplorerScreen(
                  focusNodeId: state.uri.queryParameters['node'],
                ),
              ),
            ],
          ),
          _tab(Routes.capture, const CaptureScreen()),
        ],
      ),
      // Full-screen routes, drawn over the bottom tabs.
      GoRoute(
        path: Routes.settings,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: Routes.presets,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const PresetsScreen(),
      ),
      GoRoute(
        path: Routes.groups,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const GroupsScreen(),
      ),
      // Before the :id route, which would otherwise match "new".
      GoRoute(
        path: Routes.newGroup,
        parentNavigatorKey: rootKey,
        builder: (context, state) => const GroupFormScreen.create(),
      ),
      GoRoute(
        path: '/settings/groups/:id',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            GroupFormScreen.edit(id: state.pathParameters['id']!),
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
        path: '/capture/:id/edit',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            EditCaptureScreen(id: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/capture/:id/create',
        parentNavigatorKey: rootKey,
        builder: (context, state) =>
            CreateFromCaptureScreen(captureId: state.pathParameters['id']!),
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
