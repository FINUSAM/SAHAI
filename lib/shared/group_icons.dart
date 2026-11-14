import 'package:flutter/material.dart';

/// The fixed set of group icons (M5 frame 13), by the name stored in
/// `context_groups.icon`. They come from the Material icon font the app
/// already ships, so no new package. The order is the picker's.
const groupIcons = <String, IconData>{
  'laptop': Icons.laptop_outlined,
  'bag': Icons.shopping_bag_outlined,
  'home': Icons.home_outlined,
  'phone': Icons.smartphone_outlined,
  'car': Icons.directions_car_outlined,
  'work': Icons.work_outline,
  'person': Icons.person_outline,
  'document': Icons.description_outlined,
  'place': Icons.place_outlined,
};

/// The icon for [name], or null for none or a name this version doesn't
/// know.
IconData? groupIcon(String? name) => groupIcons[name];
