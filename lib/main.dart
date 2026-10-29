import 'package:flutter/material.dart';

void main() {
  runApp(const SahaiApp());
}

/// Placeholder until the Explorer arrives in the second M1 pull request.
class SahaiApp extends StatelessWidget {
  const SahaiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Sahai',
      home: Scaffold(body: Center(child: Text('Sahai'))),
    );
  }
}
