/// Build-time configuration.
///
/// `flutter run` → demo (offline, mock AI).
/// `flutter run --dart-define=FIKRA_MODE=connected` → real backend. Not wired
/// yet: startup fails fast instead of silently running the mocks. See
/// docs/backend-integration.md.
enum AppMode { demo, connected }

final AppMode appMode = _parse(const String.fromEnvironment('FIKRA_MODE', defaultValue: 'demo'));

/// Drives the "تجريبي" labels in the UI.
bool get isDemo => appMode == AppMode.demo;

AppMode _parse(String raw) => switch (raw) {
  'demo' => AppMode.demo,
  'connected' => AppMode.connected,
  _ => throw ArgumentError.value(raw, 'FIKRA_MODE', 'expected demo or connected'),
};
