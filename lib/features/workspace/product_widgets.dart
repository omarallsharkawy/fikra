import '../../core/format.dart';

import 'dart:async';

import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/pearl_canvas.dart';
import '../../data/product/models.dart';

/// Content direction follows its script, independently of the interface locale.
/// Uses an O(1) first-strong-character scan (bounded to the first 128 code
/// units) instead of splitting the entire document with RegExps.
TextDirection productContentDirection(String text) {
  final limit = text.length < 128 ? text.length : 128;
  for (var i = 0; i < limit; i++) {
    final c = text.codeUnitAt(i);
    // Skip weak/neutral digits, combining marks, and BOM (0xFEFF).
    if ((c >= 0x0591 && c <= 0x05BD) ||
        (c >= 0x064B && c <= 0x0669) ||
        c == 0x0670 ||
        (c >= 0x06D6 && c <= 0x06ED) ||
        (c >= 0x06F0 && c <= 0x06F9) ||
        c == 0x00D7 ||
        c == 0x00F7 ||
        c == 0xFEFF) {
      continue;
    }
    // Strong RTL: Hebrew, Arabic, Syriac, Arabic Supplement, Thaana, NKo,
    // Arabic Extended, and Arabic Presentation Forms (excluding 0xFEFF BOM).
    if ((c >= 0x05BE && c <= 0x08FF) || (c >= 0xFB1D && c <= 0xFDFF) || (c >= 0xFE70 && c <= 0xFEFC)) {
      return TextDirection.rtl;
    }
    // Strong LTR: Basic Latin letters, Latin-1/Extended, Greek, Cyrillic, etc.
    if ((c >= 0x0041 && c <= 0x005A) ||
        (c >= 0x0061 && c <= 0x007A) ||
        (c >= 0x00C0 && c <= 0x02AF) ||
        (c >= 0x0370 && c <= 0x052F)) {
      return TextDirection.ltr;
    }
  }
  return TextDirection.ltr;
}

String productTimestamp(BuildContext context, DateTime storedTimestamp) {
  final local = storedTimestamp.toLocal(), l10n = context.l10n;
  return '${Fmt.weekday(l10n, local)} · ${Fmt.date(l10n, local)} · ${Fmt.time(l10n, local)}';
}

String productTitle(BuildContext context, String? title) => title ?? context.l10n.productUntitledProcessing;
String processingText(BuildContext c, ProcessingState state) => switch (state) {
  ProcessingState.queued => c.l10n.productSavedQueued,
  ProcessingState.processing => c.l10n.productSavedProcessing,
  ProcessingState.completed => c.l10n.productProcessingCompleted,
  ProcessingState.failed => c.l10n.productSavedProcessingFailed,
  ProcessingState.unknown => c.l10n.productSavedStatusUnavailable,
};

class ProductView extends ConsumerStatefulWidget {
  const ProductView({super.key, required this.builder, this.listenTo});
  final Widget Function(BuildContext context, ProductRuntime runtime) builder;
  final List<Listenable> Function(ProductRuntime runtime)? listenTo;

  @override
  ConsumerState<ProductView> createState() => _ProductViewState();
}

class _ProductViewState extends ConsumerState<ProductView> {
  Listenable? _merged;
  ProductRuntime? _runtime;
  bool _visible = true;
  bool _dirtyWhileHidden = false;

  void _attach(ProductRuntime runtime) {
    final next = Listenable.merge(widget.listenTo?.call(runtime) ?? [runtime.workspace]);
    _merged?.removeListener(_onNotify);
    _runtime = runtime;
    _merged = next;
    next.addListener(_onNotify);
  }

  void _onNotify() {
    if (!mounted) return;
    if (!_visible) {
      _dirtyWhileHidden = true;
      return;
    }
    setState(() {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final visible = TickerMode.valuesOf(context).enabled;
    _visible = visible;
    if (visible && _dirtyWhileHidden) {
      _dirtyWhileHidden = false;
    }
  }

  @override
  void didUpdateWidget(covariant ProductView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_runtime != null) _attach(_runtime!);
  }

  @override
  void dispose() {
    _merged?.removeListener(_onNotify);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final runtime = ref.watch(productRuntimeProvider);
    if (!identical(_runtime, runtime)) {
      _attach(runtime);
    }
    return widget.builder(context, runtime);
  }
}

/// UI disclosures follow the selected runtime, including protected root pages.
class ProductEnvironment extends InheritedWidget {
  const ProductEnvironment({super.key, required this.development, required super.child});
  final bool development;
  static bool previewOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ProductEnvironment>()?.development ?? true;
  @override
  bool updateShouldNotify(ProductEnvironment old) => development != old.development;
}

class DevelopmentBanner extends StatelessWidget {
  const DevelopmentBanner({super.key, this.details = const []});
  final List<String> details;
  @override
  Widget build(BuildContext context) => !ProductEnvironment.previewOf(context)
      ? const SizedBox.shrink()
      : Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            key: const ValueKey('development-banner'),
            style: TextButton.styleFrom(foregroundColor: context.colors.textSecondary),
            icon: const Icon(Icons.info_outline, size: 18),
            label: Text(context.l10n.uiPreviewNotice, style: context.text.meta),
            onPressed: () => showDialog<void>(
              context: context,
              builder: (context) => AlertDialog(
                title: Text(context.l10n.uxPreviewInfo),
                content: SingleChildScrollView(
                  child: Text(
                    [
                      context.l10n.productDevelopmentFixturesMemoryOnlyNoLiveBackend,
                      context.l10n.productDevelopmentSearchUsesLiteralFixtureMatchingNotSemantic,
                      ...details,
                    ].join('\n\n'),
                  ),
                ),
                actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(context.l10n.productBack))],
              ),
            ),
          ),
        );
}

class ProductFailureView extends StatelessWidget {
  const ProductFailureView(this.failure, {super.key, this.onRetry, this.onOpenSettings});
  final ProductFailure failure;
  final VoidCallback? onRetry;
  final VoidCallback? onOpenSettings;
  @override
  Widget build(BuildContext context) {
    final message = switch (failure.kind) {
      FailureKind.validation => switch (failure.field) {
        'microphone' => context.l10n.productMicrophonePermissionIsRequiredEnableItInDevice,
        'microphone_settings' => context.l10n.micBlockedBody,
        'code' => context.l10n.apiInvalidCode,
        'password' || 'new_password' => context.l10n.apiPasswordHint,
        'email' => context.l10n.apiInvalidEmail,
        _ => context.l10n.productCheckTheInputYourDraftHasBeenKept,
      },
      FailureKind.unauthorized || FailureKind.forbidden => context.l10n.productSignInAgainOrCheckYourCredentials,
      FailureKind.unverified => context.l10n.productVerifyYourEmailBeforeSigningIn,
      FailureKind.notFound => context.l10n.productThisItemIsNoLongerAvailableReloadThe,
      FailureKind.conflict => context.l10n.productTheStateChangedReloadAndReviewBeforeActing,
      FailureKind.gone => context.l10n.productThisCreationAttemptRefersToADeletedNote,
      FailureKind.tooLarge => context.l10n.productTheInputIsTooLargeReduceItBefore,
      FailureKind.mediaType => context.l10n.productThisRecordingFormatIsNotSupported,
      FailureKind.quota => context.l10n.productRequestLimitReachedWaitBeforeTryingAgain,
      FailureKind.unavailable => context.l10n.productThisServiceIsUnavailableYourInputHasBeen,
      FailureKind.uncertain => context.l10n.productTheResultIsUncertainReconcileBeforeTryingAgain,
    };
    final showSettings =
        failure.kind == FailureKind.validation && failure.field == 'microphone_settings' && onOpenSettings != null;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: context.text.body.copyWith(color: context.colors.warning)),
          if (failure.retryAfter != null) _QuotaCountdown(key: ValueKey(failure), duration: failure.retryAfter!),
          if (showSettings) TextButton(onPressed: onOpenSettings, child: Text(context.l10n.openSettings)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text(context.l10n.productReloadRetry)),
        ],
      ),
    );
  }
}

class ProductScaffold extends StatelessWidget {
  const ProductScaffold({
    super.key,
    required this.title,
    this.children = const [],
    this.beforeItems = const [],
    this.afterItems = const [],
    this.itemCount,
    this.itemBuilder,
    this.selectable = false,
    this.back = false,
    this.trailing,
    this.header,
    this.footer,
    this.controller,
    this.content,
    this.toolbar,
    this.previewDetails = const [],
    this.subtitle,
  });
  final String title;
  final String? subtitle;
  final List<Widget> children;
  final List<Widget> beforeItems;
  final List<Widget> afterItems;
  final int? itemCount;
  final IndexedWidgetBuilder? itemBuilder;
  final bool selectable;
  final bool back;
  final Widget? trailing, header, footer, content, toolbar;
  final ScrollController? controller;
  final List<String> previewDetails;

  Widget _buildBody(BuildContext context) {
    if (content != null) {
      final padded = Padding(padding: const EdgeInsets.fromLTRB(16, 4, 16, 12), child: content);
      return footer == null ? NavigationInsetPadding(child: padded) : padded;
    }
    final scroll = itemBuilder != null
        ? CustomScrollView(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            slivers: [
              if (beforeItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  sliver: SliverList.list(children: beforeItems),
                ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(16, beforeItems.isEmpty ? 8 : 0, 16, 0),
                sliver: SliverList.builder(itemCount: itemCount ?? 0, itemBuilder: itemBuilder!),
              ),
              if (afterItems.isNotEmpty)
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverList.list(children: afterItems),
                ),
              SliverToBoxAdapter(
                child: footer == null ? const NavigationInsetSpacer(extra: 24) : const SizedBox(height: 24),
              ),
            ],
          )
        : ListView(
            controller: controller,
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            children: [
              ...children,
              footer == null ? const NavigationInsetSpacer(extra: 24) : const SizedBox(height: 24),
            ],
          );
    return selectable ? SelectionArea(child: scroll) : scroll;
  }

  @override
  Widget build(BuildContext context) {
    final inShell = context.getInheritedWidgetOfExactType<NavigationInset>() != null;
    final body = Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Column(
                children: [
                  header ??
                      Row(
                        children: [
                          if (back)
                            IconButton(
                              tooltip: context.l10n.productBack,
                              onPressed: () {
                                if (context.canPop()) {
                                  context.pop();
                                } else {
                                  context.go('/notes');
                                }
                              },
                              icon: const Icon(Icons.arrow_back),
                            ),
                          const FikraBrandMark(),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  style: context.text.title,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                if (subtitle != null)
                                  Text(
                                    subtitle!,
                                    style: context.text.caption,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                              ],
                            ),
                          ),
                          ?trailing,
                        ],
                      ),
                  DevelopmentBanner(details: previewDetails),
                  ?toolbar,
                ],
              ),
            ),
            Expanded(child: _buildBody(context)),
            if (footer != null)
              NavigationInsetPadding(
                child: Padding(padding: const EdgeInsets.fromLTRB(16, 8, 16, 12), child: footer),
              ),
          ],
        ),
      ),
    );
    if (inShell) {
      return SafeArea(top: false, child: body);
    }
    return PearlCanvas(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(child: body),
      ),
    );
  }
}

class ProductTextInput extends StatefulWidget {
  const ProductTextInput({
    super.key,
    required this.value,
    required this.onChanged,
    required this.label,
    this.lines = 1,
    this.maxLines,
    this.obscure = false,
    this.enabled = true,
    this.onSubmitted,
    this.keyboardType,
    this.suffix,
    this.textInputAction,
    this.autofillHints,
    this.textDirection,
    this.inputFormatters,
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final int lines;
  final int? maxLines;
  final bool obscure, enabled;
  final TextInputType? keyboardType;
  final Widget? suffix;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final TextDirection? textDirection;
  final List<TextInputFormatter>? inputFormatters;
  @override
  State<ProductTextInput> createState() => _ProductTextInputState();
}

class _ProductTextInputState extends State<ProductTextInput> {
  late final _controller = TextEditingController(text: widget.value);
  bool _revealed = false;
  TextDirection? _detectedDirection;

  @override
  void initState() {
    super.initState();
    _detectedDirection = _controller.text.isEmpty ? null : productContentDirection(_controller.text);
  }

  @override
  void didUpdateWidget(covariant ProductTextInput old) {
    super.didUpdateWidget(old);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
      _detectedDirection = widget.value.isEmpty ? null : productContentDirection(widget.value);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextField(
      controller: _controller,
      enabled: widget.enabled,
      onChanged: (value) {
        widget.onChanged(value);
        if (widget.textDirection == null) {
          final nextDirection = value.isEmpty ? null : productContentDirection(value);
          if (nextDirection != _detectedDirection) {
            setState(() => _detectedDirection = nextDirection);
          }
        }
      },
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction:
          widget.textInputAction ?? (widget.lines == 1 && widget.onSubmitted != null ? TextInputAction.search : null),
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      textDirection: widget.textDirection ?? _detectedDirection ?? Directionality.of(context),
      obscureText: widget.obscure && !_revealed,
      enableSuggestions: !widget.obscure,
      autocorrect: !widget.obscure,
      minLines: widget.lines,
      maxLines: widget.maxLines ?? (widget.lines == 1 ? 1 : null),
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: true,
        suffixIcon: widget.obscure
            ? IconButton(
                tooltip: _revealed ? context.l10n.uiHidePassword : context.l10n.uiShowPassword,
                onPressed: widget.enabled ? () => setState(() => _revealed = !_revealed) : null,
                icon: Icon(_revealed ? Icons.visibility_off_outlined : Icons.visibility_outlined),
              )
            : widget.suffix,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
      ),
    ),
  );
}

class _QuotaCountdown extends StatefulWidget {
  const _QuotaCountdown({super.key, required this.duration});
  final Duration duration;
  @override
  State<_QuotaCountdown> createState() => _QuotaCountdownState();
}

class _QuotaCountdownState extends State<_QuotaCountdown> {
  late final DateTime _until = DateTime.now().add(widget.duration);
  Timer? _timer;
  bool _tickersEnabled = false;
  int get _seconds => (_until.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(0, 86400);

  void _syncTimer(bool enabled) {
    if (enabled && _seconds > 0) {
      _timer ??= Timer.periodic(const Duration(seconds: 1), (_) {
        if (_seconds == 0) {
          _timer?.cancel();
          _timer = null;
        }
        if (mounted) setState(() {});
      });
    } else {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final enabled = TickerMode.valuesOf(context).enabled;
    final resumed = enabled && !_tickersEnabled;
    _tickersEnabled = enabled;
    _syncTimer(enabled);
    if (resumed && mounted) setState(() {});
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      Text(_seconds == 0 ? context.l10n.retry : context.l10n.productRetryAfterSeconds(_seconds));
}
