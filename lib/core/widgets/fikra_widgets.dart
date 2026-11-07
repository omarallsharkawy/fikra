import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../motion/pressable.dart';
import '../theme/tokens.dart';

/// Glass surface: gradient + hairline border (Figma "Gradient/Glass surface").
class Glass extends StatelessWidget {
  const Glass({
    super.key,
    required this.child,
    this.radius = FikraRadius.lg,
    this.padding = const EdgeInsets.all(18),
    this.borderColor,
    this.borderWidth = FikraSpace.hairline,
    this.gradient,
    this.color,
    this.width,
    this.height,
  });

  final Widget child;
  final double radius;
  final EdgeInsetsGeometry padding;
  final Color? borderColor;
  final double borderWidth;
  final Gradient? gradient;
  final Color? color;
  final double? width;
  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        gradient: color == null ? (gradient ?? context.colors.glassGradient) : null,
        color: color,
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: borderColor ?? context.colors.border, width: borderWidth),
      ),
      child: child,
    );
  }
}

enum FikraButtonStyle { primary, secondary, danger }

class FikraButton extends StatelessWidget {
  const FikraButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = FikraButtonStyle.primary,
    this.expand = true,
    this.loading = false,
  });

  const FikraButton.secondary({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  }) : style = FikraButtonStyle.secondary;

  const FikraButton.danger({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = true,
    this.loading = false,
  }) : style = FikraButtonStyle.danger;

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final FikraButtonStyle style;
  final bool expand;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final (Gradient? gradient, Color? color, Color fg, TextStyle text) = switch (style) {
      FikraButtonStyle.primary => (
        context.colors.primaryGradient,
        null,
        context.colors.textOnLight,
        context.text.button,
      ),
      FikraButtonStyle.secondary => (
        context.colors.glassGradient,
        null,
        context.colors.textPrimary,
        context.text.section,
      ),
      FikraButtonStyle.danger => (null, context.colors.dangerBg, context.colors.danger, context.text.section),
    };
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (loading)
          SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: fg))
        else if (icon != null)
          Icon(icon, color: fg, size: 20),
        if (loading || icon != null) const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            style: text.copyWith(color: fg),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Pressable(
        onTap: enabled ? onPressed : null,
        semanticLabel: label,
        child: Container(
          height: FikraSpace.button,
          width: expand ? double.infinity : null,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            gradient: gradient,
            color: color,
            borderRadius: BorderRadius.circular(FikraRadius.full),
            border: style == FikraButtonStyle.secondary
                ? Border.all(color: context.colors.border, width: FikraSpace.hairline)
                : null,
          ),
          // `alignment` would make the container fill the available width,
          // so compact buttons hug their content instead.
          alignment: expand ? Alignment.center : null,
          child: content,
        ),
      ),
    );
  }
}

/// 48px pill input on glass. Icon sits at the end (left in RTL), like the design.
class FikraField extends StatefulWidget {
  const FikraField({
    super.key,
    this.controller,
    this.hint,
    this.icon,
    this.onChanged,
    this.onSubmitted,
    this.autofocus = false,
    this.error = false,
    this.keyboardType,
    this.obscure = false,
    this.textInputAction,
    this.maxLength,
  });

  final TextEditingController? controller;
  final String? hint;
  final IconData? icon;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final bool autofocus;
  final bool error;
  final TextInputType? keyboardType;
  final bool obscure;
  final TextInputAction? textInputAction;
  final int? maxLength;

  @override
  State<FikraField> createState() => _FikraFieldState();
}

class _FikraFieldState extends State<FikraField> {
  final _focus = FocusNode();

  @override
  void initState() {
    super.initState();
    _focus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final light = Theme.of(context).brightness == Brightness.light;
    final border = widget.error
        ? context.colors.danger
        : _focus.hasFocus
        ? context.colors.borderFocus
        : light
        ? context.colors.borderGraph
        : context.colors.border;
    return Glass(
      radius: FikraRadius.full,
      padding: const EdgeInsets.symmetric(horizontal: 20),
      borderColor: border,
      // A hairline vanishes on light surfaces; inputs need a visible edge.
      borderWidth: widget.error || _focus.hasFocus || light ? 1 : FikraSpace.hairline,
      height: FikraSpace.field,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: widget.controller,
              focusNode: _focus,
              autofocus: widget.autofocus,
              onChanged: widget.onChanged,
              onSubmitted: widget.onSubmitted,
              keyboardType: widget.keyboardType,
              obscureText: widget.obscure,
              textInputAction: widget.textInputAction,
              maxLength: widget.maxLength,
              style: context.text.field,
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: context.text.field.copyWith(color: context.colors.textPlaceholder),
              ),
            ),
          ),
          if (widget.icon != null) ...[
            const SizedBox(width: 12),
            Icon(widget.icon, color: context.colors.textSecondary, size: 20),
          ],
        ],
      ),
    );
  }
}

class FikraChip extends StatelessWidget {
  const FikraChip({super.key, required this.label, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      selected: onTap == null ? null : selected,
      minTarget: onTap != null,
      child: Container(
        height: onTap == null ? 30 : 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        decoration: BoxDecoration(
          gradient: selected ? context.colors.selectedGradient : null,
          color: selected ? null : context.colors.glassHighlight,
          borderRadius: BorderRadius.circular(FikraRadius.full),
          border: selected ? null : Border.all(color: context.colors.border, width: FikraSpace.hairline),
        ),
        child: Center(
          widthFactor: 1,
          child: Text(
            label,
            style: context.text.chip.copyWith(
              color: selected ? context.colors.textOnSelected : context.colors.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}

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

/// Segmented control: the selected pill slides with the smooth spring
/// (instantly under Remove animations). Each segment is a 48 dp target.
class SegmentedPill extends StatefulWidget {
  const SegmentedPill({super.key, required this.options, required this.selected, required this.onChanged});
  final List<String> options;
  final int selected;
  final ValueChanged<int> onChanged;

  @override
  State<SegmentedPill> createState() => _SegmentedPillState();
}

class _SegmentedPillState extends State<SegmentedPill> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController.unbounded(vsync: this, value: widget.selected.toDouble());

  @override
  void didUpdateWidget(covariant SegmentedPill old) {
    super.didUpdateWidget(old);
    if (old.selected == widget.selected) return;
    final target = widget.selected.toDouble();
    if (MediaQuery.maybeDisableAnimationsOf(context) ?? false) {
      _c.value = target;
    } else {
      _c.animateWith(SpringSimulation(FikraSprings.smooth, _c.value, target, _c.velocity));
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Glass(
      radius: FikraRadius.full,
      padding: const EdgeInsets.all(4),
      height: Pressable.minTargetSize + 10,
      child: LayoutBuilder(
        builder: (context, c) {
          final w = c.maxWidth / widget.options.length;
          final rtl = Directionality.of(context) == TextDirection.rtl;
          return Stack(
            children: [
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Positioned(
                  left: rtl ? null : _c.value * w,
                  right: rtl ? _c.value * w : null,
                  top: 0,
                  bottom: 0,
                  width: w,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: context.colors.selectedGradient,
                      borderRadius: BorderRadius.all(Radius.circular(FikraRadius.full)),
                    ),
                  ),
                ),
              ),
              AnimatedBuilder(
                animation: _c,
                builder: (context, _) => Row(
                  children: [
                    for (var i = 0; i < widget.options.length; i++)
                      Expanded(
                        child: Semantics(
                          button: true,
                          selected: i == widget.selected,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () => widget.onChanged(i),
                            child: Center(
                              child: Text(
                                widget.options[i],
                                // Follows the pill, so a label is never light-on-light mid-slide.
                                style: context.text.chip.copyWith(
                                  color: Color.lerp(
                                    context.colors.textSecondary,
                                    context.colors.textOnSelected,
                                    (1 - (_c.value - i).abs()).clamp(0.0, 1.0),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Bottom sheet shell: top radius 38, handle, title, fit to content.
Future<T?> showFikraSheet<T>(BuildContext context, {required String title, required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: BoxDecoration(
          gradient: context.colors.screenGradient,
          borderRadius: BorderRadius.vertical(top: Radius.circular(FikraRadius.xxl)),
          border: Border(
            top: BorderSide(color: context.colors.border, width: FikraSpace.hairline),
          ),
        ),
        padding: const EdgeInsets.fromLTRB(22, 12, 22, 28),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(color: context.colors.borderGraph, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 16),
              Text(title, style: context.text.cardTitle),
              const SizedBox(height: 16),
              builder(context),
            ],
          ),
        ),
      ),
    ),
  );
}

/// Option row used inside sheets (rename, delete, …).
class SheetOption extends StatelessWidget {
  const SheetOption({super.key, required this.label, required this.icon, required this.onTap, this.danger = false});
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final fg = danger ? context.colors.danger : context.colors.textPrimary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Pressable(
        onTap: onTap,
        pressedScale: 0.98,
        child: Glass(
          radius: FikraRadius.md,
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: fg, size: 20),
              const SizedBox(width: 12),
              Text(label, style: context.text.section.copyWith(color: fg)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Destructive confirmation. Returns true when confirmed.
Future<bool> confirmDestructive(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'حذف',
}) async {
  final ok = await showDialog<bool>(
    context: context,
    barrierColor: context.colors.scrim,
    builder: (context) => Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 35),
      child: Glass(
        radius: FikraRadius.xl,
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Semantics(namesRoute: true, header: true, child: Text(title, style: context.text.cardTitle)),
            const SizedBox(height: 8),
            Text(message, style: context.text.body.copyWith(color: context.colors.textSecondary)),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: FikraButton.danger(label: confirmLabel, onPressed: () => Navigator.pop(context, true)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FikraButton.secondary(label: 'إلغاء', onPressed: () => Navigator.pop(context, false)),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
  return ok ?? false;
}

void showToast(BuildContext context, String message) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), duration: const Duration(seconds: 3)));
}

/// Full-screen page outside the tab shell: screen gradient + transparent
/// Scaffold + SafeArea. Tab screens get the same chrome from AppShell.
class FikraScaffold extends StatelessWidget {
  const FikraScaffold({super.key, required this.child, this.safeBottom = true});
  final Widget child;
  final bool safeBottom;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(gradient: context.colors.screenGradient),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(bottom: safeBottom, child: child),
      ),
    );
  }
}

/// Round glass icon button (back, more, zoom…). [label] is read by screen
/// readers; the hit area is at least 48 dp whatever the visual [size].
class FikraIconButton extends StatelessWidget {
  const FikraIconButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.size = 44,
    this.solid = false,
  });
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final double size;

  /// Opaque background, for buttons floating over content.
  final bool solid;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      semanticLabel: label,
      minTarget: true,
      child: Glass(
        radius: FikraRadius.full,
        width: size,
        height: size,
        padding: EdgeInsets.zero,
        color: solid ? context.colors.glass : null,
        child: Icon(icon, size: size * 0.48),
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
    if (value.hasValue) return data(value.requireValue);
    if (!value.hasError) return const SizedBox.shrink(); // first load: local db, near-instant
    return LoadErrorView(onRetry: onRetry);
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
        title: 'مش قادرين نحمّل البيانات',
        description: 'حصلت مشكلة وإحنا بنقرا البيانات. جرّب تاني.',
        action: onRetry == null
            ? null
            : FikraButton.secondary(label: 'جرّب تاني', icon: Icons.refresh_rounded, expand: false, onPressed: onRetry),
      ),
    );
  }
}

/// Runs a user action, showing [success] only after it completes and a toast
/// on failure. Returns whether it succeeded.
Future<bool> runAction(
  BuildContext context,
  Future<void> Function() action, {
  String? success,
  String failure = 'حصلت مشكلة، جرّب تاني',
}) async {
  final messenger = ScaffoldMessenger.maybeOf(context);
  void toast(String m) => messenger
    ?..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(m), duration: const Duration(seconds: 3)));
  try {
    await action();
    if (success != null) toast(success);
    return true;
  } catch (_) {
    toast(failure);
    return false;
  }
}

/// Fills the available height and centers [child], scrolling instead of
/// overflowing when the window is short (landscape, large text, keyboard).
class FillScroll extends StatelessWidget {
  const FillScroll({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, box) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: box.maxHeight),
          child: Center(child: child),
        ),
      ),
    );
  }
}
