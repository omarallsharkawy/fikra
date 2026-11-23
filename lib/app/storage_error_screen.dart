import 'package:fikra/l10n/localizations.dart';
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
        title: context.l10n.storageErrorTitle,
        description: context.l10n.storageErrorBody,
        action: FikraButton(
          label: context.l10n.retry,
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
