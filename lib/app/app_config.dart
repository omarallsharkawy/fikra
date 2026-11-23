/// Build-time configuration.
///
/// `flutter run` → development (explicit volatile product fixtures).
/// `flutter run --dart-define=FIKRA_MODE=demo` → preserved legacy local app.
/// `flutter run --dart-define=FIKRA_MODE=connected` → real backend. Not wired
/// yet: startup fails fast instead of silently running the mocks. See
/// docs/features/backend-aligned-journeys/implementation.md.
enum AppMode { development, demo, connected }

final AppMode appMode = _parse(const String.fromEnvironment('FIKRA_MODE', defaultValue: 'development'));

/// Drives the "تجريبي" labels in the UI.
bool get isDemo => appMode != AppMode.connected;

AppMode _parse(String raw) => switch (raw) {
  'development' => AppMode.development,
  'demo' => AppMode.demo,
  'connected' => AppMode.connected,
  _ => throw ArgumentError.value(raw, 'FIKRA_MODE', 'expected development, demo or connected'),
};
