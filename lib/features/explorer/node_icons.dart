import 'package:flutter/material.dart';

import '../../engine/node_type.dart';

IconData iconForType(NodeType type) => switch (type) {
  NodeType.domain => Icons.folder_outlined,
  NodeType.stream => Icons.notes,
  NodeType.project => Icons.track_changes,
  NodeType.task ||
  NodeType.subtask ||
  NodeType.streamItem => Icons.radio_button_unchecked,
};
