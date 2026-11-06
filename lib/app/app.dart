import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/theme/fikra_theme.dart';
import 'providers.dart';
import 'router.dart';

class FikraApp extends ConsumerWidget {
  const FikraApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(startupMaintenanceProvider);
    return MaterialApp.router(
      title: 'فِكرة',
      debugShowCheckedModeBanner: false,
      theme: buildFikraTheme(),
      themeMode: ThemeMode.dark,
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar')],
      localizationsDelegates: GlobalMaterialLocalizations.delegates,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
