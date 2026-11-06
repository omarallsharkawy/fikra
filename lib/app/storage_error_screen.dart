import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/tokens.dart';
import '../core/widgets/fikra_widgets.dart';
import 'providers.dart';

/// Shown when the local database can't be opened. Never deletes data.
class StorageErrorScreen extends ConsumerWidget {
  const StorageErrorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return DecoratedBox(
      decoration: const BoxDecoration(gradient: FikraColors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: EmptyState(
            icon: Icons.sd_card_alert_outlined,
            title: 'مش قادرين نفتح بياناتك',
            description: 'نوتسك لسه موجودة على الموبايل. اتأكد إن في مساحة فاضية وجرّب تاني.',
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
        ),
      ),
    );
  }
}
