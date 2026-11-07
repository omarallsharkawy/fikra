import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets/fikra_widgets.dart';
import 'providers.dart';

/// Shown when the local database can't be opened. Never deletes data.
class StorageErrorScreen extends ConsumerWidget {
  const StorageErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FikraScaffold(
      child: EmptyState(
        icon: Icons.sd_card_alert_outlined,
        title: 'في مشكلة في التخزين',
        description: 'مش قادرين نقرأ بياناتك دلوقتي. اتأكد إن فيه مساحة فاضية وجرّب تاني.',
        action: FikraButton(
          label: 'جرّب تاني',
          icon: Icons.refresh_rounded,
          expand: false,
          onPressed: () {
            ref.invalidate(databaseProvider);
            ref.invalidate(projectsProvider);
          },
        ),
      ),
    );
  }
}
