import 'package:flutter/material.dart';

import '../settings/settings_screen.dart';

/// The persistent Me branch reuses the existing settings controls and guards.
class MeScreen extends StatelessWidget {
  const MeScreen({super.key});

  @override
  Widget build(BuildContext context) => const SettingsScreen();
}
