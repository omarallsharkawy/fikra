import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';

/// Static reading geometry for a cold /note/:id, without an endless ticker.
class NoteDetailsPlaceholder extends StatelessWidget {
  const NoteDetailsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    key: const ValueKey('note-placeholder'),
    padding: const EdgeInsets.all(FikraSpace.screen),
    child: ExcludeSemantics(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final height in [36.0, 180.0, 100.0]) ...[
            SolidSurface(
              child: Container(
                height: height,
                decoration: BoxDecoration(
                  color: context.colors.chip,
                  borderRadius: BorderRadius.circular(FikraRadius.sm),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          const NavigationInsetSpacer(extra: 24),
        ],
      ),
    ),
  );
}
