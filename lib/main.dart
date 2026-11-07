import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';
import 'app/app_config.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (appMode == AppMode.connected) {
    // Fail loudly instead of running the demo services under a "connected" label.
    throw UnsupportedError('FIKRA_MODE=connected is not wired yet. See docs/backend-integration.md');
  }
  await initializeDateFormatting('ar');
  runApp(const ProviderScope(child: FikraApp()));
}
