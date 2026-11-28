import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'app/app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterError.onError = (details) {
    if (kDebugMode) {
      FlutterError.presentError(details);
    } else {
      debugPrint('FIKRA_ERROR ${details.exception.runtimeType}');
    }
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    if (kDebugMode) {
      debugPrint('FIKRA_ASYNC_ERROR $error\n$stack');
    } else {
      debugPrint('FIKRA_ASYNC_ERROR ${error.runtimeType}');
    }
    return true;
  };
  if (kReleaseMode) {
    ErrorWidget.builder = (_) => const Material(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Icon(Icons.error_outline, size: 32),
        ),
      ),
    );
  }
  await initializeDateFormatting();
  runApp(const ProviderScope(child: FikraApp()));
}
