import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/motion.dart';
import '../theme/tokens.dart';

import 'buttons.dart';
import 'glass.dart';
import 'layout.dart';

/// Icon + title + description (+ action). Carries the screen gutter itself;
/// pass [padding] when the parent already does.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.description,
    this.action,
    this.padding = const EdgeInsets.symmetric(horizontal: FikraSpace.screen, vertical: 24),
  });
  final IconData icon;
  final String title;
  final String description;
  final Widget? action;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Glass(
            radius: 36,
            width: 72,
            height: 72,
            padding: EdgeInsets.zero,
            child: Icon(icon, color: context.colors.textSecondary, size: 30),
          ),
          const SizedBox(height: 12),
          Text(title, style: context.text.cardTitle, textAlign: TextAlign.center),
          const SizedBox(height: 6),
          Text(
            description,
            style: context.text.body.copyWith(color: context.colors.textSecondary),
            textAlign: TextAlign.center,
          ),
          if (action != null) ...[const SizedBox(height: 20), action!],
        ],
      ),
    );
  }
}

/// "Couldn't load" state. Use instead of an empty state when a query failed.
class LoadErrorView extends StatelessWidget {
  const LoadErrorView({super.key, this.onRetry});
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FillScroll(
      child: EmptyState(
        icon: Icons.error_outline_rounded,
        title: context.l10n.loadErrorTitle,
        description: context.l10n.loadErrorBody,
        action: onRetry == null
            ? null
            : FikraButton.secondary(
                label: context.l10n.retry,
                icon: Icons.refresh_rounded,
                expand: false,
                onPressed: onRetry,
              ),
      ),
    );
  }
}

/// Renders an [AsyncValue]: a load failure gets an error state with retry
/// instead of looking like an empty list.
class AsyncBody<T> extends StatelessWidget {
  const AsyncBody({super.key, required this.value, required this.data, this.onRetry});
  final AsyncValue<T> value;
  final Widget Function(T data) data;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return FikraSwitcher(
      child: value.hasValue
          ? KeyedSubtree(key: const ValueKey('data'), child: data(value.requireValue))
          : value.hasError
          ? LoadErrorView(key: const ValueKey('error'), onRetry: onRetry)
          : const SizedBox.shrink(key: ValueKey('loading')),
    );
  }
}
