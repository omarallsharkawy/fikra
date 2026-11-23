import 'package:flutter/material.dart';

import '../../core/format.dart';
import '../../core/widgets/fikra_widgets.dart';
import '../../data/transcription/service_config.dart';
import '../../l10n/localizations.dart';

Future<bool> confirmServiceConsent(BuildContext context, TranscriptionService service) {
  if (service.consented) return Future.value(true);
  final l = context.l10n;
  return confirmDestructive(
    context,
    danger: false,
    title: l.vsConsentTitle(Fmt.isolate(service.name)),
    message:
        '${l.vsConsentBody(Fmt.isolate(service.name), Fmt.isolate(Uri.parse(service.baseUrl).origin))}'
        '${service.insecure ? '\n\n${l.vsHttpWarning}' : ''}',
    confirmLabel: l.vsConsentConfirm,
  );
}
