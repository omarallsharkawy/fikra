import '../../data/settings_repository.dart';
import 'whisper_models.dart';

/// Restore only installed models. Prefer quantised weights within each family.
SpikeModel preferredVoiceTextModel(Map<String, int> sizes, {String? stored}) {
  bool installed(SpikeModel m) => (sizes[m.modelName] ?? 0) > 0;
  final saved = allSpikeModels.where((m) => m.modelName == stored && installed(m)).firstOrNull;
  if (saved != null) return saved;
  final preferred = [
    egyptianModel,
    ...spikeModels.where((m) => m.family == 'small'),
    ...spikeModels.where((m) => m.family == 'base'),
    ...spikeModels.where((m) => m.family == 'tiny'),
  ];
  return preferred.where(installed).firstOrNull ?? spikeModels.first;
}

class VoiceTextPreferences {
  VoiceTextPreferences(this.settings);
  final VoiceTextSettings settings;
  SpikeModel model = spikeModels.first;
  String language = 'ar';
  bool loaded = false;

  Future<void> restore(Map<String, int> sizes) async {
    final saved = await settings.readVoiceTextChoices();
    final selected = preferredVoiceTextModel(sizes, stored: saved.modelName);
    if (saved.modelName != selected.modelName) await settings.setVoiceTextModel(selected.modelName);
    final lang = const ['ar', 'en', 'auto'].contains(saved.language) ? saved.language! : 'ar';
    if (saved.language != lang) await settings.setVoiceTextLanguage(lang);
    model = selected;
    language = lang;
    loaded = true;
  }

  Future<void> recoverMissing(Map<String, int> sizes) async => chooseModel(preferredVoiceTextModel(sizes));

  Future<void> chooseModel(SpikeModel value) async {
    await settings.setVoiceTextModel(value.modelName);
    model = value;
  }

  Future<void> chooseLanguage(String value) async {
    await settings.setVoiceTextLanguage(value);
    language = value;
  }
}
