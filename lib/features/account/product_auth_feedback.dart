import 'package:flutter/material.dart';

import '../../core/theme/tokens.dart';
import '../../data/product/models.dart';
import '../../l10n/localizations.dart';
import '../workspace/product_widgets.dart';

/// Account failures describe the current action, never note drafts or retries.
class ProductAuthFeedback extends StatefulWidget {
  const ProductAuthFeedback(this.failure, {super.key});
  final ProductFailure failure;

  @override
  State<ProductAuthFeedback> createState() => _ProductAuthFeedbackState();
}

class _ProductAuthFeedbackState extends State<ProductAuthFeedback> {
  void _reveal() => WidgetsBinding.instance.addPostFrameCallback((_) {
    if (mounted) {
      Scrollable.ensureVisible(context, alignment: 0, duration: const Duration(milliseconds: 200));
    }
  });

  @override
  void initState() {
    super.initState();
    _reveal();
  }

  @override
  void didUpdateWidget(ProductAuthFeedback oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.failure, widget.failure)) _reveal();
  }

  @override
  Widget build(BuildContext context) {
    final failure = widget.failure;
    final l = context.l10n;
    final message = switch (failure.cause) {
      FailureCause.connection => l.authConnectionError,
      FailureCause.timeout => l.authTimeoutError,
      FailureCause.secureConnection => l.authSecureConnectionError,
      FailureCause.invalidResponse => l.authResponseError,
      null => switch (failure.kind) {
        FailureKind.unauthorized => l.authCredentialsError,
        FailureKind.unavailable => l.authServiceError,
        FailureKind.uncertain => l.authRequestError,
        FailureKind.validation => switch (failure.field) {
          'email' => l.apiInvalidEmail,
          'password' || 'new_password' => l.apiPasswordHint,
          'code' => l.apiInvalidCode,
          _ => l.authCheckDetails,
        },
        _ => null,
      },
    };
    return Semantics(
      key: const ValueKey('auth-feedback'),
      liveRegion: true,
      child: Container(
        margin: const EdgeInsets.only(bottom: 20),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: context.colors.dangerBg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.colors.danger.withValues(alpha: .3)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ExcludeSemantics(child: Icon(Icons.info_outline_rounded, color: context.colors.danger, size: 22)),
            const SizedBox(width: 12),
            Expanded(
              child: message == null
                  ? ProductFailureView(failure)
                  : Text(message, style: context.text.caption.copyWith(color: context.colors.danger)),
            ),
          ],
        ),
      ),
    );
  }
}
