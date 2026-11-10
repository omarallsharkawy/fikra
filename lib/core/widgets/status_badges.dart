import 'package:flutter/material.dart';

import '../theme/tokens.dart';

import 'glass.dart';

enum BadgeKind { demo, saved, processing, failed }

class FikraBadge extends StatelessWidget {
  const FikraBadge({super.key, required this.kind, this.label});
  final BadgeKind kind;
  final String? label;

  @override
  Widget build(BuildContext context) {
    final (String text, Color fg, Color bg) = switch (kind) {
      BadgeKind.demo => ('بيانات تجريبية', context.colors.accentLight, context.colors.glassHighlight),
      BadgeKind.saved => ('تم الحفظ', context.colors.success, context.colors.successBg),
      BadgeKind.processing => ('جاري التحليل…', context.colors.accentLight, context.colors.glassHighlight),
      BadgeKind.failed => ('فشل', context.colors.danger, context.colors.dangerBg),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(FikraRadius.full)),
      child: Text(label ?? text, style: context.text.meta.copyWith(color: fg)),
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
      BannerKind.offline => (Icons.wifi_off_rounded, context.colors.warning, context.colors.glassHighlight),
      BannerKind.error => (Icons.error_outline_rounded, context.colors.danger, context.colors.dangerBg),
      BannerKind.info => (Icons.auto_awesome_outlined, context.colors.accentLight, context.colors.glassHighlight),
    };
    return Glass(
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
