import '../../core/widgets/smart_text.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/motion/rolling_text.dart';
import '../../core/theme/tokens.dart';
import '../../l10n/localizations.dart';
import 'me_stats.dart';

class MeStatsTiles extends ConsumerWidget {
  const MeStatsTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final stats = ref.watch(meStatsProvider);
    final values = stats.value;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _tile(context, 'ideas', context.l10n.meIdeas, values?.notes, const Color(0xff2448e6), Colors.white),
          const SizedBox(width: 8),
          _tile(context, 'links', context.l10n.meLinks, values?.links, const Color(0xff6336d6), Colors.white),
          const SizedBox(width: 8),
          _tile(
            context,
            'days',
            context.l10n.meWeekDays,
            values?.activeDays,
            const Color(0xffc8f04a),
            const Color(0xff172000),
          ),
        ],
      ),
    );
  }

  Widget _tile(BuildContext context, String id, String label, int? value, Color fill, Color ink) => Expanded(
    child: Semantics(
      label: '$label: ${value ?? context.l10n.vtWait}',
      excludeSemantics: true,
      child: Container(
        key: ValueKey('me-stat-$id'),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(color: fill, borderRadius: BorderRadius.circular(20)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RollingText(
              value?.toString() ?? '—',
              style: context.text.title.copyWith(fontSize: 30, fontWeight: FontWeight.w800, color: ink),
            ),
            SmartText(
              label,
              style: context.text.caption.copyWith(color: ink, fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    ),
  );
}
