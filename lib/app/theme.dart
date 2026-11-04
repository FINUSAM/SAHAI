import 'package:flutter/material.dart';

import '../shared/brand.dart';

/// A plain Material 3 theme seeded with the brand teal, so the screens and
/// the launcher icon agree. The wireframes are layout only; the rest of
/// the visual design comes in M7.
ThemeData buildTheme(Brightness brightness) => ThemeData(
  colorScheme: ColorScheme.fromSeed(
    seedColor: Brand.teal,
    brightness: brightness,
  ),
);
