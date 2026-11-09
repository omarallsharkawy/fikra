import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../core/widgets/fikra_widgets.dart';

/// Opens a PDF or photo in another app, or says why it couldn't.
Future<void> openAttachment(BuildContext context, WidgetRef ref, String path) async {
  final opened = await ref.read(fileOpenerProvider)(path);
  if (!opened && context.mounted) showToast(context, 'معرفناش نفتح الملف. اتأكد إن عندك تطبيق بيفتحه.');
}
