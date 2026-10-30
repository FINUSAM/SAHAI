import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Which Explorer rows are open. Kept in memory only: after a restart the
/// tree starts collapsed.
class ExpandedNodes extends Notifier<Set<String>> {
  @override
  Set<String> build() => const {};

  void toggle(String id) =>
      state = state.contains(id) ? ({...state}..remove(id)) : {...state, id};

  void open(Iterable<String> ids) => state = {...state, ...ids};
}

final expandedProvider = NotifierProvider<ExpandedNodes, Set<String>>(
  ExpandedNodes.new,
);
