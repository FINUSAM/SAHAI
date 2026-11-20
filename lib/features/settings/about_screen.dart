import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../shared/brand.dart';
import '../../shared/strings.dart';

/// About Sahai (PRD 8.6, M7 frame 15): the version, where the data lives,
/// what's coming in plain words, and the open-source licences. The privacy
/// policy link comes in M8 (AT-122).
class AboutScreen extends ConsumerWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final version = ref.watch(appVersionProvider).value;
    final heading = theme.textTheme.titleSmall?.copyWith(
      color: theme.colorScheme.onSurfaceVariant,
    );
    final bold = theme.textTheme.titleSmall?.copyWith(
      fontWeight: FontWeight.w700,
    );
    Widget section(String text) => Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 4),
      child: Semantics(header: true, child: Text(text, style: heading)),
    );
    Widget bullets(List<String> lines) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (final line in lines)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const ExcludeSemantics(child: Text('•  ')),
                Expanded(child: Text(line)),
              ],
            ),
          ),
      ],
    );
    return Scaffold(
      appBar: AppBar(title: const Text(Strings.aboutSahai)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
        children: [
          Row(
            children: [
              ExcludeSemantics(
                child: Container(
                  width: 48,
                  height: 48,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Brand.teal,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'S',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: Brand.paper,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(Strings.appName, style: theme.textTheme.titleLarge),
                    if (version != null)
                      Text(
                        Strings.versionLine(version),
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          section(Strings.yourData),
          const Text(Strings.yourDataBody),
          section(Strings.whatsComing),
          Text(Strings.nextHeading, style: bold),
          bullets(Strings.comingNext),
          const SizedBox(height: 12),
          Text(Strings.laterHeading, style: bold),
          bullets(Strings.comingLater),
          section(Strings.moreHeading),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text(Strings.licences),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => showLicensePage(
              context: context,
              applicationName: Strings.appName,
              applicationVersion: version,
            ),
          ),
        ],
      ),
    );
  }
}
