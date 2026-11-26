import 'package:intl/intl.dart' show DateFormat, Bidi;

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
TextDirection productContentDirection(String text) =>
    Bidi.detectRtlDirectionality(text) ? TextDirection.rtl : TextDirection.ltr;

String productTimestamp(BuildContext context, DateTime storedTimestamp) {
  final local = storedTimestamp.toLocal(), l10n = context.l10n;
  return '${DateFormat.EEEE(l10n.localeName).format(local)} · ${Fmt.date(l10n, local)} · ${Fmt.time(l10n, local)}';
}

String productTitle(BuildContext context, String? title) => title ?? context.l10n.productUntitledProcessing;
String processingText(BuildContext c, ProcessingState state) => switch (state) {
  ProcessingState.queued => c.l10n.productSavedQueued,
  ProcessingState.processing => c.l10n.productSavedProcessing,
  ProcessingState.completed => c.l10n.productProcessingCompleted,
  ProcessingState.failed => c.l10n.productSavedProcessingFailed,
  ProcessingState.unknown => c.l10n.productSavedStatusUnavailable,
};

class ProductView extends ConsumerWidget {
  const ProductView({super.key, required this.builder, this.listenTo});
  final Widget Function(BuildContext context, ProductRuntime runtime) builder;
  final List<Listenable> Function(ProductRuntime runtime)? listenTo;
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final runtime = ref.watch(productRuntimeProvider);
    return ListenableBuilder(
      listenable: Listenable.merge(listenTo?.call(runtime) ?? [runtime.workspace]),
      builder: (context, _) => builder(context, runtime),
    );
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
  const ProductFailureView(this.failure, {super.key, this.onRetry});
  final ProductFailure failure;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final message = switch (failure.kind) {
      FailureKind.validation => switch (failure.field) {
        'microphone' => context.l10n.productMicrophonePermissionIsRequiredEnableItInDevice,
        'code' => context.l10n.apiInvalidCode,
        'password' || 'new_password' => context.l10n.apiPasswordHint,
        'email' => context.l10n.apiInvalidEmail,
        _ => context.l10n.productCheckTheInputYourDraftHasBeenKept,
      },
      FailureKind.unauthorized => context.l10n.productSignInAgainOrCheckYourCredentials,
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
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(message, style: context.text.body.copyWith(color: context.colors.warning)),
          if (failure.retryAfter != null) _QuotaCountdown(key: ValueKey(failure), duration: failure.retryAfter!),
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
  final bool back;
  final Widget? trailing, header, footer, content, toolbar;
  final ScrollController? controller;
  final List<String> previewDetails;
  @override
  Widget build(BuildContext context) => PearlCanvas(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Align(
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
                                  onPressed: () => context.pop(),
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
                Expanded(
                  child: content != null
                      ? Padding(
                          padding: EdgeInsets.fromLTRB(
                            16,
                            4,
                            16,
                            12 + (footer == null ? NavigationInset.of(context) : 0),
                          ),
                          child: content,
                        )
                      : ListView(
                          controller: controller,
                          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: EdgeInsets.fromLTRB(
                            16,
                            8,
                            16,
                            24 + (footer == null ? NavigationInset.of(context) : 0),
                          ),
                          children: children,
                        ),
                ),
                if (footer != null)
                  Padding(padding: EdgeInsets.fromLTRB(16, 8, 16, 12 + NavigationInset.of(context)), child: footer),
              ],
            ),
          ),
        ),
      ),
    ),
  );
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
  @override
  void didUpdateWidget(covariant ProductTextInput old) {
    super.didUpdateWidget(old);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
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
      onChanged: widget.onChanged,
      onSubmitted: widget.onSubmitted,
      keyboardType: widget.keyboardType,
      textInputAction:
          widget.textInputAction ?? (widget.lines == 1 && widget.onSubmitted != null ? TextInputAction.search : null),
      autofillHints: widget.autofillHints,
      inputFormatters: widget.inputFormatters,
      textDirection: widget.textDirection,
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
  int get _seconds => (_until.difference(DateTime.now()).inMilliseconds / 1000).ceil().clamp(0, 86400);
  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_seconds == 0) _timer?.cancel();
      if (mounted) setState(() {});
    });
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
