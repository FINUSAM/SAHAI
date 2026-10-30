/// The six kinds of node in the tree (PRD 4).
enum NodeType {
  domain('domain'),
  stream('stream'),
  streamItem('stream_item'),
  project('project'),
  task('task'),
  subtask('subtask');

  const NodeType(this.dbName);

  /// The value stored in `nodes.type`.
  final String dbName;

  static NodeType fromDbName(String value) =>
      values.firstWhere((t) => t.dbName == value);

  /// Domains and streams are containers only and never get TODO/DONE (PRD 5).
  bool get hasStatus => this != domain && this != stream;

  /// The node types that can be created directly under this one (PRD 4).
  Set<NodeType> get allowedChildren => switch (this) {
    domain => const {project, stream},
    stream => const {streamItem},
    project => const {task},
    task => const {subtask},
    streamItem || subtask => const {},
  };

  /// The node type a node of this type must sit under, or null for the top
  /// level. Every type has exactly one valid parent type, which is what keeps
  /// moves from creating cycles.
  NodeType? get parentType => switch (this) {
    domain => null,
    stream || project => domain,
    streamItem => stream,
    task => project,
    subtask => task,
  };
}

/// TODO/DONE status of a node that has one (PRD 5).
enum NodeStatus {
  todo('todo'),
  done('done');

  const NodeStatus(this.dbName);

  final String dbName;

  static NodeStatus? fromDbName(String? value) =>
      value == null ? null : values.firstWhere((s) => s.dbName == value);
}

/// The node types that can be created with no parent.
const Set<NodeType> topLevelTypes = {NodeType.domain};

/// Whether a node of [child] type may sit directly under a node of [parent]
/// type, where a null [parent] means the top level.
bool canHaveChild(NodeType? parent, NodeType child) => parent == null
    ? topLevelTypes.contains(child)
    : parent.allowedChildren.contains(child);
