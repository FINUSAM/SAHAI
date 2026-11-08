import '../engine/node_type.dart';
import '../engine/recurrence.dart';
import '../engine/scope.dart';
import '../engine/time.dart';

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
  static const captureLater =
      'Quick notes to sort later will collect here, ready to turn into items.';

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

  // Summary (M2 frames 1–7).
  static const summaryEmptyTitle = 'Nothing to show yet';
  static const summaryEmptyBody =
      'Add a domain and a project in the Explorer. The next step of each '
      'project appears here.';
  static const openExplorer = 'Open Explorer';
  static String allDone(NodeType type, int n) => 'All ${count(type, n)} done';
  static String markDoneToUnlock(String title) => 'Mark done to unlock $title';
  static const noTasksYet = 'No tasks yet';
  static const addATask = 'Add a task';
  static String doneSnack(String title) => 'Done: $title';
  static const openInTree = 'Open in tree';
  static String alsoReopens(List<String> titles) =>
      'Also reopens ${_list(titles)}';

  /// "A", "A and B", "A, B and C".
  static String _list(List<String> items) => items.length <= 1
      ? items.join()
      : '${items.sublist(0, items.length - 1).join(', ')} and ${items.last}';

  // Set aside (M3 frames 1–12).
  static const setAsideTitle = 'Set aside';
  static const changeTime = 'Change time';
  static const whatToSetAside = 'What to set aside';
  static String setAsideTooltip(String title) => 'Set aside $title';

  /// "This subtask", "Its task", "Its domain" (frame 3).
  static String scopeLabel(SetAsideLevel level, NodeType itemType) =>
      switch (level) {
        SetAsideLevel.item => 'This ${_typeNoun(itemType)}',
        SetAsideLevel.task => 'Its task',
        SetAsideLevel.project => 'Its project',
        SetAsideLevel.stream => 'Its stream',
        SetAsideLevel.domain => 'Its domain',
      };
  static String withEverythingInIt(String title) =>
      '$title, with everything in it';
  static String presetName(Preset preset) => switch (preset) {
    Preset.tonight => 'Tonight',
    Preset.tomorrowMorning => 'Tomorrow morning',
    Preset.threeDaysLater => '3 days later',
    Preset.nextWeek => 'Next week',
  };
  static const customDateTime = 'Custom date and time…';
  static const remindMe = 'Remind me';
  static const remindMeHint = "Notify me when it's back";
  static const remindOff = 'Remind me is off';
  static String setAsideUntil(String when) => 'Set aside until $when';
  static const todayWord = 'Today';
  static const tonightWord = 'Tonight';
  static String inMinutes(int n) => 'in $n min';
  static String inHours(int n) => 'in $n h';
  static String inDays(int n) => n == 1 ? 'in 1 day' : 'in $n days';

  // Due labels (M4 frame 1).
  static const dueToday = 'Due today';
  static String dueOn(String date) => 'Due $date';
  static String daysOverdue(int n) =>
      n == 1 ? '1 day overdue' : '$n days overdue';
  static const repeatsLabel = 'Repeats';

  // Repeat form (M4 frames 2 to 4).
  static const repeat = 'Repeat';
  static const repeatHint = 'For routines like bills and rent';
  static const every = 'Every';
  static const period = 'Period';
  static const onDay = 'On day';
  static const onWeekdays = 'On';
  static const inMonth = 'In month';
  static const lastDayHint =
      "Days 29 to 31 use the month's last day when needed.";
  static const nextDue = 'Next due';
  static const repeatFromLabel = 'Repeat from';
  static const dueDate = 'Due date';
  static const completionDate = 'Completion date';
  static const fromDueHint =
      'Paid late? The next date still follows the due date.';
  static const fromCompletionHint =
      'The next date counts from the day you finish it.';
  static const showBeforeDue = 'Show before due (days)';
  static const everyError = 'Enter 1 or more';
  static const leadError = 'Enter 0 or more';
  static const appearsToday = 'Appears today';
  static String appears(String date) => 'Appears $date';

  static String periodName(Frequency frequency, {required int interval}) {
    final name = switch (frequency) {
      Frequency.daily => 'Day',
      Frequency.weekly => 'Week',
      Frequency.monthly => 'Month',
      Frequency.yearly => 'Year',
    };
    return interval == 1 ? name : '${name}s';
  }

  static String frequencyName(Frequency frequency) => switch (frequency) {
    Frequency.daily => 'Daily',
    Frequency.weekly => 'Weekly',
    Frequency.monthly => 'Monthly',
    Frequency.yearly => 'Yearly',
  };

  /// "Every 2 months".
  static String everyN(int n, Frequency frequency) =>
      'Every $n ${periodName(frequency, interval: n).toLowerCase()}';

  /// Uses [DateTime.monday] to [DateTime.sunday].
  static String weekdayName(int weekday) => const [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ][weekday - 1];
  static String weekdayAbbreviation(int weekday) =>
      weekdayName(weekday).substring(0, 3);
  static String weekdayButton(int weekday) =>
      weekdayName(weekday).substring(0, 2);
  static String monthName(int month) => const [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ][month - 1];

  /// "the 1st", "the 22nd", "the 13th".
  static String theDay(int day) {
    final suffix = switch ((day % 100, day % 10)) {
      (11 || 12 || 13, _) => 'th',
      (_, 1) => 'st',
      (_, 2) => 'nd',
      (_, 3) => 'rd',
      _ => 'th',
    };
    return 'the $day$suffix';
  }

  /// "Repeats monthly on the 5th", with [every] already in lower case.
  static String repeats(
    String every, {
    String? on,
    required bool fromCompletion,
  }) => [
    'Repeats $every',
    if (on != null) 'on $on',
    if (fromCompletion) 'from completion',
  ].join(' ');

  // Recurring actions (M4 frames 5, 6, 9, 11).
  static const skipOccurrence = 'Skip this occurrence';
  static const stopRepeating = 'Stop repeating';
  static String nextDueOn(String date) => 'Next due $date';
  static String doneNextDue(String date) => 'Done. Next due $date';
  static String skippedNextDue(String date) => 'Skipped. Next due $date';
  static String noLongerRepeats(String title) => '$title no longer repeats';
  static String notOnSummary(String title, String date) =>
      "$title is set aside until $date, so this isn't on the Summary.";

  // Custom time (frame 6).
  static String enterTime(String date) => '$date · Enter time';
  static const hour = 'Hour';
  static const minute = 'Minute';
  static const am = 'AM';
  static const pm = 'PM';
  static const ok = 'OK';
  static const chooseOnClock = 'Choose on a clock';
  static const invalidTime = 'Enter a valid time';
  static String pickTimeAfter(String time) => 'Pick a time after $time';

  // Set-Aside page (frames 8–10).
  static const groupToday = 'Today';
  static const groupTomorrow = 'Tomorrow';
  static const groupLater = 'Later';
  static const wakeNow = 'Wake now';
  static String wakeNowTooltip(String title) => 'Wake $title now';
  static String hides(String counts) => 'Hides $counts';
  static const hiddenUntilThen = 'Hidden until then';
  static String backAt(String when) => 'back $when';
  static const nothingSetAside = 'Nothing set aside';
  static const nothingSetAsideBody =
      'Tap the clock on a Summary card to set something aside until later. '
      'It waits here until then.';

  // Explorer (frames 11, 12).
  static String back(String when) => 'Back $when';
  static String hiddenWhile(String title) => 'Hidden while $title is set aside';
  static const setAsideMenu = 'Set aside…';
  static const changeSetAsideTime = 'Change set-aside time';

  // Notifications (frame 13) and Settings (frame 14).
  static String isBack(String title) => '$title is back';
  static String itemsBack(int n) => '$n items are back';
  static String isDueOn(String title, String date) => '$title is due $date';
  static String isDueToday(String title) => '$title is due today';
  static String itemsDueToday(int n) => '$n items are due today';
  static String itemsDue(int n) => '$n items are due';

  /// One line of a grouped reminder whose items are due on different days.
  static String dueLine(String title, String due) => '$title$separator$due';
  static const remindersChannel = 'Reminders';
  static const remindersChannelDescription =
      'When something you set aside comes back, or a recurring item is due';
  static const remindersSection = 'Reminders';
  static const notifications = 'Notifications';
  static const notificationsHint =
      'Tell me when something I set aside comes back, or a recurring item is '
      'due';
  static const exactReminders = 'Exact reminders';
  static const exactRemindersHint =
      'Arrive on the minute instead of a few minutes late. Android asks '
      'for permission to set alarms.';
  static const laterSettings =
      'Day start, preset times, groups, backup and more come in M7.';

  // Refusals (ActionRejected reasons).
  static const notFound = 'That item no longer exists.';
  static const emptyTitleError = 'Give it a title.';
  static const invalidParent = "That item can't go there.";
  static const noStatus = "Domains and streams can't be marked done.";
  static const lockedTask = 'Finish the task before it first.';
  static const hasTodoChildren = 'Finish or delete what is inside it first.';
  static const alreadyDone = 'That item is already done.';
  static const notDone = 'That item is not done.';
  static const pastWakeTime = 'Pick a time in the future.';
  static const notSetAside = 'That item is not set aside.';
  static const cantRepeat = 'Only stream items that are not done can repeat.';
  static const notRecurring = 'That item does not repeat.';
  static const staleUndo = 'That item has already moved on.';
  static const noSuchGroup = 'That group no longer exists.';
  static const cardNotShowing = 'That item is not on the Summary right now.';
}
