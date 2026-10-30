import 'package:flutter/material.dart';

/// A plain Material 3 theme. The wireframes are layout only; visual design
/// comes in M7.
ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: const Color(0xFF3F51B5),
    brightness: brightness,
  ),
);
