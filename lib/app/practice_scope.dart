import 'package:flutter/widgets.dart';

/// Marks the onboarding practice step (M7 frames 6 to 8). Inside it, the
/// real Summary and Set-Aside screens run on a temporary copy, so anything
/// that would leave the practice is switched off: the Settings button and
/// Open in tree. [coach] is the dashed box that says what to try next,
/// shown at the top of the screen.
class PracticeScope extends InheritedWidget {
  const PracticeScope({super.key, required this.coach, required super.child});

  final Widget coach;

  /// The practice around [context], or null outside it.
  static PracticeScope? of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<PracticeScope>();

  /// Whether [context] is inside the practice, without depending on it.
  static bool isOn(BuildContext context) =>
      context.getInheritedWidgetOfExactType<PracticeScope>() != null;

  @override
  bool updateShouldNotify(PracticeScope oldWidget) => coach != oldWidget.coach;
}

/// [child] with the practice's coach box above it, inside the practice;
/// just [child] everywhere else.
class WithPracticeCoach extends StatelessWidget {
  const WithPracticeCoach({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final practice = PracticeScope.of(context);
    if (practice == null) return child;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        practice.coach,
        Expanded(child: child),
      ],
    );
  }
}
