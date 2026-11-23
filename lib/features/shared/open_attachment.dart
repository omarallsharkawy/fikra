import 'package:fikra/l10n/localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/widgets/fikra_widgets.dart';

/// Opens a PDF or photo in another app, or says why it couldn't.
Future<void> openAttachment(BuildContext context, WidgetRef ref, String path) async {
  var opened = false;
  try {
    opened = await ref.read(fileOpenerProvider)(path);
  } catch (_) {
    // Keep the viewer usable even if the platform opener itself fails.
  }
  if (!opened && context.mounted) showToast(context, context.l10n.openFileFailed);
}
