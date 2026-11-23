import 'package:intl/intl.dart';

import '../../core/format.dart';

import 'dart:async';

import '../../l10n/localizations.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../app/product_runtime.dart';
import '../../core/theme/tokens.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../core/widgets/pearl_canvas.dart';
import '../../data/product/models.dart';

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

class DevelopmentBanner extends StatelessWidget {
  const DevelopmentBanner({super.key});
  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('development-banner'),
    width: double.infinity,
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    decoration: BoxDecoration(
      color: context.colors.brandLime.withValues(alpha: .12),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(context.l10n.productDevelopmentFixturesMemoryOnlyNoLiveBackend, style: context.text.meta),
  );
}

class ProductFailureView extends StatelessWidget {
  const ProductFailureView(this.failure, {super.key, this.onRetry});
  final ProductFailure failure;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) {
    final message = switch (failure.kind) {
      FailureKind.validation =>
        failure.field == 'microphone'
            ? context.l10n.productMicrophonePermissionIsRequiredEnableItInDevice
            : context.l10n.productCheckTheInputYourDraftHasBeenKept,
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
  const ProductScaffold({super.key, required this.title, required this.children, this.back = false, this.trailing});
  final String title;
  final List<Widget> children;
  final bool back;
  final Widget? trailing;
  @override
  Widget build(BuildContext context) => PearlCanvas(
    child: Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.fromLTRB(24, 16, 24, 24 + NavigationInset.of(context)),
          children: [
            Row(
              children: [
                if (back)
                  IconButton(
                    tooltip: context.l10n.productBack,
                    onPressed: () => context.pop(),
                    icon: const Icon(Icons.arrow_back),
                  ),
                Expanded(child: Text(title, style: context.text.title)),
                ?trailing,
              ],
            ),
            const SizedBox(height: 16),
            const DevelopmentBanner(),
            const SizedBox(height: 20),
            ...children,
          ],
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
    this.obscure = false,
    this.enabled = true,
    this.onSubmitted,
    this.keyboardType,
  });
  final String value, label;
  final ValueChanged<String> onChanged;
  final ValueChanged<String>? onSubmitted;
  final int lines;
  final bool obscure, enabled;
  final TextInputType? keyboardType;
  @override
  State<ProductTextInput> createState() => _ProductTextInputState();
}

class _ProductTextInputState extends State<ProductTextInput> {
  late final _controller = TextEditingController(text: widget.value);
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
      obscureText: widget.obscure,
      minLines: widget.lines,
      maxLines: widget.lines == 1 ? 1 : null,
      decoration: InputDecoration(
        labelText: widget.label,
        alignLabelWithHint: true,
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
