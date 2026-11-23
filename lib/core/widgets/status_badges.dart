import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';

import '../theme/tokens.dart';

import 'solid_surface.dart';

enum BadgeKind { demo, saved, processing, failed, warning }

class FikraBadge extends StatelessWidget {
  const FikraBadge({super.key, required this.kind, this.label});
  final BadgeKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (String text, Color fg, Color bg) = switch (kind) {
      BadgeKind.demo => (context.l10n.badgeSampleData, context.colors.textSecondary, context.colors.chip),
      BadgeKind.saved => (context.l10n.badgeSaved, context.colors.success, context.colors.successBg),
      BadgeKind.processing => (context.l10n.badgeAnalyzing, context.colors.textSecondary, context.colors.chip),
      BadgeKind.failed => (context.l10n.badgeFailed, context.colors.danger, context.colors.dangerBg),
      BadgeKind.warning => (context.l10n.noteRewriteSuggested, context.colors.warning, context.colors.warningBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(FikraRadius.full)),
      child: Text(
        label ?? text,
        style: context.text.meta.copyWith(color: fg, fontWeight: FontWeight.w600),
      ),
    );
  }
}

enum BannerKind { offline, error, info }

class StatusBanner extends StatelessWidget {
  const StatusBanner({super.key, required this.kind, required this.message});
  final BannerKind kind;
  final String message;

  @override
  Widget build(BuildContext context) {
    final (IconData icon, Color fg, Color bg) = switch (kind) {
      BannerKind.offline => (Icons.wifi_off_rounded, context.colors.warning, context.colors.warningBg),
      BannerKind.error => (Icons.error_outline_rounded, context.colors.danger, context.colors.dangerBg),
      BannerKind.info => (Icons.auto_awesome_outlined, context.colors.textSecondary, context.colors.chip),
    };
    return SolidSurface(
      radius: FikraRadius.md,
      color: bg,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: [
          Icon(icon, color: fg, size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(message, style: context.text.chip)),
        ],
      ),
    );
  }
}
