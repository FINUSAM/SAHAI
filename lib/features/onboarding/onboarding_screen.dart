import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/providers.dart';
import '../../app/router.dart';
import '../../data/settings.dart';
import '../../engine/node_type.dart';
import '../../shared/brand.dart';
import '../../shared/strings.dart';
import '../../shared/time.dart';
import '../explorer/action_feedback.dart';
import 'practice_view.dart';

enum _Step { welcome, areas, project, subtasks, reveal, practice, finish }

/// Onboarding (PRD 8.1, M7 frames 1 to 9). The user makes their first areas,
/// project, task and two subtasks from real work; there is no sample data.
///
/// Each step saves when Next is tapped, through the normal node actions, so
/// their `created` events are real. Back returns to an earlier step and
/// changes what it made rather than making it again. Skip, on every step,
/// keeps what was saved and opens the Summary (AT-107). The practice step
/// runs on a temporary copy and saves nothing (AT-106).
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  var _step = _Step.welcome;
  var _busy = false;

  final _area1 = TextEditingController();
  final _area2 = TextEditingController();
  final _project = TextEditingController();
  final _task = TextEditingController();
  final _sub1 = TextEditingController();
  final _sub2 = TextEditingController();

  // What has been saved so far: ids, and the titles they were saved with,
  // so going back and changing a field edits rather than creates.
  String? _area1Id;
  String? _area2Id;
  String? _projectId;
  String? _taskId;
  String? _sub1Id;
  String? _sub2Id;
  final _savedTitles = <String, String>{};

  /// The area the project goes in; the first one unless the user picks.
  var _projectInSecond = false;

  @override
  void initState() {
    super.initState();
    for (final c in _controllers) {
      c.addListener(_changed);
    }
  }

  List<TextEditingController> get _controllers => [
    _area1,
    _area2,
    _project,
    _task,
    _sub1,
    _sub2,
  ];

  void _changed() => setState(() {});

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _text(TextEditingController c) => c.text.trim();

  bool get _hasTwoAreas => _text(_area2).isNotEmpty;

  bool get _canGoOn => switch (_step) {
    _Step.areas => _text(_area1).isNotEmpty,
    _Step.project => _text(_project).isNotEmpty && _text(_task).isNotEmpty,
    _Step.subtasks => _text(_sub1).isNotEmpty && _text(_sub2).isNotEmpty,
    _ => true,
  };

  /// Makes [id] if it doesn't exist yet, or renames it if its title changed.
  Future<String> _makeOrRename(
    String? id, {
    required NodeType type,
    required String? parentId,
    required String title,
  }) async {
    final actions = ref.read(nodeActionsProvider);
    if (id == null) {
      final made = await actions.create(
        type: type,
        parentId: parentId,
        title: title,
      );
      _savedTitles[made] = title;
      return made;
    }
    if (_savedTitles[id] != title) {
      await actions.edit(id, title: title);
      _savedTitles[id] = title;
    }
    return id;
  }

  Future<void> _saveAreas() async {
    final actions = ref.read(nodeActionsProvider);
    _area1Id = await _makeOrRename(
      _area1Id,
      type: NodeType.domain,
      parentId: null,
      title: _text(_area1),
    );
    if (_hasTwoAreas) {
      _area2Id = await _makeOrRename(
        _area2Id,
        type: NodeType.domain,
        parentId: null,
        title: _text(_area2),
      );
    } else if (_area2Id case final second?) {
      // The second area was cleared after it was made. Anything already in
      // it moves to the first area, so nothing made here is lost.
      if (_projectId case final project? when _projectInSecond) {
        await actions.move(project, _area1Id!);
      }
      _projectInSecond = false;
      await actions.delete(second);
      _area2Id = null;
    }
  }

  Future<void> _saveProject() async {
    final actions = ref.read(nodeActionsProvider);
    final area = _projectInSecond && _area2Id != null ? _area2Id! : _area1Id!;
    final existing = _projectId;
    _projectId = await _makeOrRename(
      existing,
      type: NodeType.project,
      parentId: area,
      title: _text(_project),
    );
    if (existing != null) {
      final tree = await actions.loadTree();
      if (tree[existing]?.parentId != area) await actions.move(existing, area);
    }
    _taskId = await _makeOrRename(
      _taskId,
      type: NodeType.task,
      parentId: _projectId,
      title: _text(_task),
    );
  }

  Future<void> _saveSubtasks() async {
    _sub1Id = await _makeOrRename(
      _sub1Id,
      type: NodeType.subtask,
      parentId: _taskId,
      title: _text(_sub1),
    );
    _sub2Id = await _makeOrRename(
      _sub2Id,
      type: NodeType.subtask,
      parentId: _taskId,
      title: _text(_sub2),
    );
  }

  Future<void> _next() async {
    if (_busy || !_canGoOn) return;
    FocusScope.of(context).unfocus();
    final save = switch (_step) {
      _Step.areas => _saveAreas,
      _Step.project => _saveProject,
      _Step.subtasks => _saveSubtasks,
      _ => null,
    };
    if (save != null) {
      setState(() => _busy = true);
      final saved = await runAction(context, () async {
        await save();
        return true;
      });
      if (!mounted) return;
      setState(() => _busy = false);
      if (saved == null) return;
    }
    setState(() => _step = _Step.values[_step.index + 1]);
  }

  void _back() {
    if (_step == _Step.welcome) return;
    FocusScope.of(context).unfocus();
    setState(
      () => _step = _step == _Step.finish
          ? _Step.reveal
          : _Step.values[_step.index - 1],
    );
  }

  /// Skip and Go to my Summary: onboarding is done, and what was saved
  /// stays (AT-107).
  Future<void> _leave() async {
    await saveSettings(
      ref.read(databaseProvider),
      nowMillis: utcMillis(ref.read(clockProvider)),
      onboardingDone: true,
    );
    if (mounted) context.go(Routes.summary);
  }

  @override
  Widget build(BuildContext context) {
    if (_step == _Step.practice) {
      return PracticeView(
        domainId: _projectInSecond && _area2Id != null ? _area2Id! : _area1Id!,
        projectId: _projectId!,
        taskId: _taskId!,
        firstSubtaskId: _sub1Id!,
        secondSubtaskId: _sub2Id!,
        onFinished: () => setState(() => _step = _Step.finish),
        onSkip: _leave,
        onBack: () => setState(() => _step = _Step.reveal),
      );
    }
    return PopScope(
      canPop: _step == _Step.welcome,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: Scaffold(
        appBar: _step == _Step.welcome || _step == _Step.finish
            ? AppBar(
                automaticallyImplyLeading: false,
                actions: [
                  if (_step == _Step.welcome) _SkipButton(onPressed: _leave),
                ],
              )
            : AppBar(
                leading: BackButton(onPressed: _back),
                actions: [_SkipButton(onPressed: _leave)],
              ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                  child: _content(context),
                ),
              ),
              _buttons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buttons() {
    final (String label, VoidCallback? onPressed) = switch (_step) {
      _Step.welcome => (Strings.getStarted, _next),
      _Step.reveal => (Strings.tryIt, _next),
      _Step.finish => (Strings.goToSummary, _leave),
      _ => (Strings.next, _canGoOn && !_busy ? _next : null),
    };
    final wide = _step == _Step.welcome || _step == _Step.finish;
    final showBack = !wide && _step != _Step.areas;
    final primary = FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(minimumSize: const Size(64, 52)),
      child: Text(label),
    );
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      child: wide
          ? primary
          : Row(
              children: [
                if (showBack)
                  TextButton(
                    onPressed: _back,
                    child: const Text(Strings.backButton),
                  ),
                const Spacer(),
                primary,
              ],
            ),
    );
  }

  Widget _content(BuildContext context) => switch (_step) {
    _Step.welcome => const _Welcome(),
    _Step.areas => _StepPage(
      step: 1,
      title: Strings.areasTitle,
      body: Strings.areasBody,
      children: [
        _Field(
          controller: _area1,
          label: Strings.firstArea,
          hint: Strings.firstAreaHint,
          autofocus: true,
        ),
        _Field(
          controller: _area2,
          label: Strings.secondArea,
          hint: Strings.secondAreaHint,
          onSubmitted: _next,
        ),
        const _Note(Strings.areasNote),
      ],
    ),
    _Step.project => _StepPage(
      step: 2,
      title: Strings.projectTitle,
      body: Strings.projectBody,
      children: [
        if (_hasTwoAreas) ...[
          Text(Strings.whichArea, style: Theme.of(context).textTheme.bodySmall),
          Wrap(
            spacing: 8,
            children: [
              for (final (second, name) in [
                (false, _text(_area1)),
                (true, _text(_area2)),
              ])
                ChoiceChip(
                  label: Text(name),
                  selected: _projectInSecond == second,
                  onSelected: (_) => setState(() => _projectInSecond = second),
                ),
            ],
          ),
        ],
        _Field(
          controller: _project,
          label: Strings.projectLabel,
          hint: Strings.projectHint,
          autofocus: true,
        ),
        _Field(
          controller: _task,
          label: Strings.firstTaskLabel,
          hint: Strings.firstTaskHint,
          onSubmitted: _next,
        ),
      ],
    ),
    _Step.subtasks => _StepPage(
      step: 2,
      title: Strings.subtasksTitle,
      body: Strings.subtasksBody(_text(_task)),
      children: [
        _Field(
          controller: _sub1,
          label: Strings.subtaskLabel(1),
          autofocus: true,
        ),
        _Field(
          controller: _sub2,
          label: Strings.subtaskLabel(2),
          hint: Strings.subtaskHint,
          onSubmitted: _next,
        ),
        const _Note(Strings.subtasksNote),
        _Making(
          path: [
            _projectInSecond && _hasTwoAreas ? _text(_area2) : _text(_area1),
            _text(_project),
            '1. ${_text(_task)}',
          ].join(Strings.pathSeparator),
          subtasks: [_text(_sub1), _text(_sub2)],
        ),
      ],
    ),
    _Step.reveal => _StepPage(
      step: 3,
      title: Strings.revealTitle,
      body: Strings.revealBody,
      children: [
        _RevealCard(
          title: _text(_sub1),
          path: [
            _projectInSecond && _hasTwoAreas ? _text(_area2) : _text(_area1),
            _text(_project),
            '1. ${_text(_task)}',
          ].join(Strings.pathSeparator),
        ),
        _Note.rich(
          lead: Strings.whyOnlyOne,
          text: Strings.whyOnlyOneBody(_text(_sub1), _text(_sub2)),
        ),
      ],
    ),
    _Step.finish => _Finish(task: _text(_task), first: _text(_sub1)),
    _Step.practice => const SizedBox.shrink(),
  };
}

class _SkipButton extends StatelessWidget {
  const _SkipButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) =>
      TextButton(onPressed: onPressed, child: const Text(Strings.skip));
}

/// Frame 1.
class _Welcome extends StatelessWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 48),
        ExcludeSemantics(
          child: Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Brand.teal,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'S',
              style: theme.textTheme.headlineMedium?.copyWith(
                color: Brand.paper,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        Semantics(
          header: true,
          child: Text(
            Strings.welcomeTitle,
            style: theme.textTheme.headlineMedium,
          ),
        ),
        const SizedBox(height: 16),
        Text(Strings.welcomeBody1, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        Text(Strings.welcomeBody2, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        const _Note(Strings.welcomeNote),
      ],
    );
  }
}

/// The frame around steps 1 to 3: "Step 1 of 4", the dots, the heading.
class _StepPage extends StatelessWidget {
  const _StepPage({
    required this.step,
    required this.title,
    required this.body,
    required this.children,
  });

  final int step;
  final String title;
  final String body;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _StepHeader(step: step),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(title, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: 8),
        Text(body, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        for (final child in children) ...[child, const SizedBox(height: 12)],
      ],
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.step});

  final int step;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        Expanded(
          child: Text(
            Strings.stepOf(step),
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        ExcludeSemantics(
          child: Row(
            children: [
              for (var i = 1; i <= 4; i++)
                Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.only(left: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i <= step
                        ? theme.colorScheme.onSurface
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _Field extends StatelessWidget {
  const _Field({
    required this.controller,
    required this.label,
    this.hint,
    this.autofocus = false,
    this.onSubmitted,
  });

  final TextEditingController controller;
  final String label;
  final String? hint;
  final bool autofocus;
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) => TextField(
    controller: controller,
    autofocus: autofocus,
    textCapitalization: TextCapitalization.sentences,
    textInputAction: onSubmitted == null
        ? TextInputAction.next
        : TextInputAction.done,
    inputFormatters: [LengthLimitingTextInputFormatter(200)],
    decoration: InputDecoration(
      labelText: label,
      helperText: hint,
      helperMaxLines: 3,
      border: const OutlineInputBorder(),
    ),
    onSubmitted: onSubmitted == null ? null : (_) => onSubmitted!(),
  );
}

/// The grey box with a tip.
class _Note extends StatelessWidget {
  const _Note(this.text) : lead = null;

  const _Note.rich({required String this.lead, required this.text});

  final String? lead;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text.rich(
        TextSpan(
          children: [
            if (lead != null)
              TextSpan(
                text: lead,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
            TextSpan(text: text),
          ],
        ),
      ),
    );
  }
}

/// "What you're making" under the subtasks (frame 4).
class _Making extends StatelessWidget {
  const _Making({required this.path, required this.subtasks});

  final String path;
  final List<String> subtasks;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final muted = theme.textTheme.bodyMedium?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          Strings.whatYoureMaking.toUpperCase(),
          style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.8),
        ),
        const SizedBox(height: 6),
        Text(path, style: muted),
        for (final (i, title) in subtasks.indexed)
          if (title.isNotEmpty) Text('${i + 1}. $title', style: muted),
      ],
    );
  }
}

/// Frame 5: a picture of the Summary with only the first subtask. Its
/// buttons are drawn, not live; the practice step is where they work.
class _RevealCard extends StatelessWidget {
  const _RevealCard({required this.title, required this.path});

  final String title;
  final String path;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        border: Border.all(color: theme.colorScheme.outlineVariant),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            Strings.summary.toUpperCase(),
            style: theme.textTheme.labelMedium?.copyWith(letterSpacing: 0.8),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 10, 10),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border.all(color: theme.colorScheme.outlineVariant),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Strings.typeName(NodeType.subtask).toUpperCase(),
                        style: theme.textTheme.labelSmall?.copyWith(
                          letterSpacing: 0.8,
                        ),
                      ),
                      Text(title, style: theme.textTheme.titleMedium),
                      Text(
                        path,
                        style: theme.textTheme.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const ExcludeSemantics(
                  child: Row(
                    children: [
                      Icon(Icons.schedule),
                      SizedBox(width: 12),
                      Icon(Icons.radio_button_unchecked),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Frame 9.
class _Finish extends StatelessWidget {
  const _Finish({required this.task, required this.first});

  final String task;
  final String first;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    Widget tick(String text) => Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const ExcludeSemantics(child: Icon(Icons.check)),
          const SizedBox(width: 16),
          Expanded(child: Text(text, style: theme.textTheme.bodyLarge)),
        ],
      ),
    );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const _StepHeader(step: 4),
        const SizedBox(height: 12),
        Semantics(
          header: true,
          child: Text(
            Strings.finishTitle,
            style: theme.textTheme.headlineSmall,
          ),
        ),
        const SizedBox(height: 8),
        Text(Strings.finishBody, style: theme.textTheme.bodyLarge),
        const SizedBox(height: 16),
        _Note.rich(lead: Strings.oneMoreThing, text: Strings.signOffNote(task)),
        tick(Strings.practiceUndone(first)),
        tick(Strings.addTheRest),
      ],
    );
  }
}
