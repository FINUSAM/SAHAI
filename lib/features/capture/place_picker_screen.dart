import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../engine/node_type.dart';
import '../../engine/tree.dart';
import '../../shared/strings.dart';
import '../explorer/explorer_rows.dart';

/// Picks where a new [type] goes: only the places it can go, each with its
/// path, and a search box (M6 frame 9). Returns the chosen id.
Future<String?> pickPlace(
  BuildContext context, {
  required NodeType type,
  String? selected,
}) => Navigator.of(context).push<String>(
  MaterialPageRoute(
    builder: (_) => PlacePickerScreen(type: type, selected: selected),
  ),
);

/// "Personal › Paperwork": the place's path with the place itself at the
/// end, as the Create form shows it.
String placeLabel(Tree tree, TreeNode place) => [
  pathOf(tree, place),
  displayTitle(tree, place),
].where((s) => s.isNotEmpty).join(Strings.pathSeparator);

class PlacePickerScreen extends ConsumerStatefulWidget {
  const PlacePickerScreen({super.key, required this.type, this.selected});

  final NodeType type;
  final String? selected;

  @override
  ConsumerState<PlacePickerScreen> createState() => _PlacePickerScreenState();
}

class _PlacePickerScreenState extends ConsumerState<PlacePickerScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tree = ref.watch(treeProvider).value;
    final parentType = widget.type.parentType!;
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.goesIn)),
      body: tree == null
          ? const Center(child: CircularProgressIndicator())
          : ValueListenableBuilder(
              valueListenable: _search,
              builder: (context, query, _) {
                final all = inTreeOrder(tree)
                    .where((n) => n.type == parentType)
                    .toList();
                final needle = query.text.trim().toLowerCase();
                final places = [
                  for (final p in all)
                    if (needle.isEmpty ||
                        placeLabel(tree, p).toLowerCase().contains(needle))
                      p,
                ];
                return RadioGroup<String>(
                  groupValue: widget.selected,
                  onChanged: (id) => Navigator.of(context).pop(id),
                  child: ListView(
                    padding: const EdgeInsets.only(bottom: 24),
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                        child: TextField(
                          controller: _search,
                          decoration: InputDecoration(
                            prefixIcon: const Icon(Icons.search),
                            hintText: Strings.searchPlaces(parentType),
                            border: const OutlineInputBorder(),
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                        child: Text(
                          Strings.goesInHint(widget.type, parentType),
                          style: muted,
                        ),
                      ),
                      if (places.isEmpty)
                        Padding(
                          padding: const EdgeInsets.all(16),
                          child: Text(
                            all.isEmpty
                                ? Strings.noPlaces(parentType)
                                : Strings.noMatches,
                            style: muted,
                          ),
                        ),
                      for (final p in places)
                        RadioListTile<String>(
                          value: p.id,
                          title: Text(displayTitle(tree, p)),
                          subtitle: _pathOrNull(tree, p),
                        ),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget? _pathOrNull(Tree tree, TreeNode place) {
    final path = pathOf(tree, place);
    return path.isEmpty ? null : Text(path);
  }
}
