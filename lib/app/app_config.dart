/// Build-time environment. Connected is the default mobile client.
/// Use FIKRA_MODE=development for volatile fixtures, or demo for legacy local data.
enum AppMode { development, demo, connected }

final AppMode appMode = _parse(const String.fromEnvironment('FIKRA_MODE', defaultValue: 'connected'));
const apiOrigin = String.fromEnvironment(
  'FIKRA_API_URL',
  defaultValue: 'https://fikrah-api-23107c84.austriaeast.cloudapp.azure.com',
);
bool get isDemo => appMode != AppMode.connected;
AppMode _parse(String raw) => switch (raw) {
  'development' => AppMode.development,
  'demo' => AppMode.demo,
  'connected' => AppMode.connected,
  _ => throw ArgumentError.value(raw, 'FIKRA_MODE', 'expected development, demo or connected'),
};
