import 'package:flutter/material.dart';

/// The brand colours, sampled from the owner's logo files in
/// `docs/design/brand/`. The launcher icon uses the same two values in
/// `android/app/src/main/res/` (colors.xml and ic_launcher_foreground.xml),
/// so change both places together.
abstract final class Brand {
  /// Dark teal: the app's seed colour and the icon background.
  static const teal = Color(0xFF0F6469);

  /// Warm off-white: the icon's S and the logo's paper background.
  static const paper = Color(0xFFF5F2ED);
}
