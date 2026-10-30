import '../engine/node_type.dart';

/// Every piece of user-facing text, kept in one place so translations can be
/// added later without rewriting screens (E-006: v1 is English-only).
abstract final class Strings {
  static const appName = 'Sahai';

  // Tabs and placeholders.
  static const summary = 'Summary';
  static const setAside = 'Set-Aside';
  static const explorer = 'Explorer';
  static const capture = 'Capture';
  static const settings = 'Settings';
  static String comingIn(String milestone) => 'Coming in $milestone';
  static const summaryLater =
      'Your next steps from every project and stream will show here.';
  static const setAsideLater =
      'Items you set aside until later will be listed here.';
  static const captureLater =
      'Quick notes to sort later will collect here, ready to turn into items.';
  static const settingsLater =
      'Day start, reminders and other settings will be here.';

  // Explorer.
  static const loadError = "Your items couldn't be loaded.";
  static const emptyTitle = 'Nothing here yet';
  static const emptyBody =
      'Start with an area of your work or life, such as your company or '
      'Personal. Projects and streams go inside it.';
  static const addADomain = 'Add a domain';
  static const addDomainButton = 'Domain';
  static String expand(String title) => 'Expand $title';
  static String collapse(String title) => 'Collapse $title';
  static String actionsFor(String title) => 'Actions for $title';
  static String markDoneTooltip(String title) => 'Mark $title done';
  static String reopenTooltip(String title) => 'Reopen $title';
  static String lockedLabel(String title) => '$title is locked';

  static String typeName(NodeType type) => switch (type) {
    NodeType.domain => 'Domain',
    NodeType.stream => 'Stream',
    NodeType.streamItem => 'Stream item',
    NodeType.project => 'Project',
    NodeType.task => 'Task',
    NodeType.subtask => 'Subtask',
  };

  static String _typeNoun(NodeType type) => switch (type) {
    NodeType.streamItem => 'stream item',
    _ => typeName(type).toLowerCase(),
  };

  /// "1 task", "3 subtasks", "2 items".
  static String count(NodeType type, int n) {
    final noun = switch (type) {
      NodeType.domain => 'domain',
      NodeType.stream => 'stream',
      NodeType.streamItem => 'item',
      NodeType.project => 'project',
      NodeType.task => 'task',
      NodeType.subtask => 'subtask',
    };
    return '$n $noun${n == 1 ? '' : 's'}';
  }

  static String _plural(NodeType type) => switch (type) {
    NodeType.streamItem => 'items',
    _ => '${_typeNoun(type)}s',
  };

  static const done = 'Done';
  static const currentTask = 'Current task';
  static const locked = 'Locked';
  static String lockedUntil(int number) => 'Locked until $number is done';
  static const separator = ' · ';
  static const pathSeparator = ' › ';

  /// What can go inside a node, e.g. "project or stream", "task".
  static String childChoice(Iterable<NodeType> types) =>
      types.map(_typeNoun).join(' or ');

  static String addChild(Iterable<NodeType> types) =>
      'Add ${childChoice(types)}';

  // Add menu (frame 4).
  static String addTo(String title) => 'Add to $title';
  static String typeDescription(NodeType type) => switch (type) {
    NodeType.project => 'An outcome with an end. Its tasks run in order.',
    NodeType.stream => 'An ongoing queue with no end, such as errands.',
    NodeType.domain => 'An area of your work or life.',
    NodeType.task => 'A step. Tasks run in order.',
    NodeType.subtask => 'A single action inside a task.',
    NodeType.streamItem => 'A single action in the stream.',
  };

  // Node actions (frame 6).
  static const edit = 'Edit';
  static const markDone = 'Mark done';
  static const reopen = 'Reopen';
  static String moveToAnother(NodeType parentType) =>
      'Move to another ${_typeNoun(parentType)}…';
  static const moveUp = 'Move up';
  static const moveDown = 'Move down';
  static String reorderChildren(NodeType? parentType) =>
      'Reorder ${_siblingNoun(parentType)}';
  static const delete = 'Delete';

  static String _siblingNoun(NodeType? parentType) => parentType == null
      ? 'domains'
      : parentType.allowedChildren.map(_plural).join(' and ');

  // Create / edit (frame 5).
  static String newNode(NodeType type) => 'New ${_typeNoun(type)}';
  static String editNode(NodeType type) => 'Edit ${_typeNoun(type)}';
  static String inParent(String title) => 'In $title';
  static const save = 'Save';
  static const close = 'Close';
  static const titleLabel = 'Title';
  static const notesLabel = 'Notes (optional)';
  static const notesHint = 'Anything worth remembering';

  // Reorder (frame 7).
  static const doneButton = 'Done';
  static const reorderHint = 'Drag a handle, or use the arrows.';
  static const reorderTasksHint =
      'Tasks run top to bottom. Drag a handle, or use the arrows.';
  static const reorderTasksNote =
      'Moving a task above the current one makes it the new current task.';
  static String moveUpTooltip(String title) => 'Move $title up';
  static String moveDownTooltip(String title) => 'Move $title down';
  static String dragHandle(String title) => 'Drag to reorder $title';

  // Move to (frame 8).
  static String moveNode(NodeType type) => 'Move ${_typeNoun(type)}';
  static String moveHint(NodeType type, NodeType parentType) =>
      'Pick a ${_typeNoun(parentType)} to move it under. Only '
      '${_plural(parentType)} are listed, because a ${_typeNoun(type)} can '
      'only live in a ${_typeNoun(parentType)}.';
  static const whereItIsNow = 'Where it is now';
  static const reopensIfMovedHere = 'Done, moving here reopens it';
  static const cancel = 'Cancel';
  static const moveHere = 'Move here';

  // Delete with Undo (frame 9).
  static String deleted(String title, int under) => under == 0
      ? 'Deleted $title'
      : 'Deleted $title and ${under == 1 ? '1 item' : '$under items'} '
            'under it';
  static const undo = 'Undo';

  // Refusals (ActionRejected reasons).
  static const notFound = 'That item no longer exists.';
  static const emptyTitleError = 'Give it a title.';
  static const invalidParent = "That item can't go there.";
  static const noStatus = "Domains and streams can't be marked done.";
  static const lockedTask = 'Finish the task before it first.';
  static const hasTodoChildren = 'Finish or delete what is inside it first.';
  static const alreadyDone = 'That item is already done.';
  static const notDone = 'That item is not done.';
}
