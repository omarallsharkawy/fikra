import 'package:fikra/features/voice_text/voice_text_backend.dart';
import 'package:fikra/features/voice_text/voice_text_controller.dart';
import 'package:fikra/features/voice_text/voice_text_preferences.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_voice_text_backend.dart';

void main() {
  VoiceTextController controller(FakeVoiceTextBackend backend, FakeVoiceTextSettings settings) {
    final c = VoiceTextController(backend, settings: settings, claimMicrophone: () => true, releaseMicrophone: () {});
    addTearDown(c.dispose);
    return c;
  }

  test('stored installed model and speech language override the automatic preference', () async {
    final backend = FakeVoiceTextBackend()
      ..seed()
      ..egyptianFilePresent = true;
    final settings = FakeVoiceTextSettings(modelName: 'tiny-q5_1', language: 'en');
    final c = controller(backend, settings);
    await c.initialize();
    expect(c.model.modelName, 'tiny-q5_1');
    expect(c.language, 'en');
  });

  test('Egyptian is chosen and persisted when present with no saved choice', () async {
    final c = controller(
      FakeVoiceTextBackend()
        ..seed()
        ..egyptianFilePresent = true,
      FakeVoiceTextSettings(),
    );
    await c.initialize();
    expect(c.model, egyptianModel);
    expect((await c.choices.settings.readVoiceTextChoices()).modelName, egyptianModel.modelName);
  });

  test('missing stored model is replaced in priority order; none offers Tiny download', () async {
    for (final installed in [
      <String, int>{'small-egy-cs-q5_1': 1, 'small-q5_1': 1, 'base-q5_1': 1, 'tiny-q5_1': 1},
      <String, int>{'small-q5_1': 1, 'base-q5_1': 1, 'tiny-q5_1': 1},
      <String, int>{'base-q5_1': 1, 'tiny-q5_1': 1},
      <String, int>{'tiny-q5_1': 1},
      <String, int>{},
    ]) {
      final settings = FakeVoiceTextSettings(modelName: 'deleted', language: 'auto');
      final choices = VoiceTextPreferences(settings);
      await choices.restore(installed);
      expect(choices.model.modelName, installed.keys.firstOrNull ?? 'tiny-q5_1');
      expect(settings.modelName, choices.model.modelName);
      expect(choices.language, 'auto');
    }
  });

  test('choosing writes immediately; reopening restores both values', () async {
    final backend = FakeVoiceTextBackend()..seed();
    backend.sizes['base-q5_1'] = 123;
    final settings = FakeVoiceTextSettings();
    final c = controller(backend, settings);
    await c.initialize();
    await c.chooseModel(spikeModels[1]);
    await c.chooseLanguage('auto');
    expect(settings.modelName, 'base-q5_1');
    expect(settings.language, 'auto');
    final freshBackend = FakeVoiceTextBackend()..seed();
    freshBackend.sizes['base-q5_1'] = 123;
    final reopened = controller(freshBackend, settings);
    await reopened.initialize();
    expect(reopened.model, spikeModels[1]);
    expect(reopened.language, 'auto');
  });

  test('deleting the selected model repairs the saved value and falls back', () async {
    final backend = FakeVoiceTextBackend()..seed();
    backend.sizes['small-q5_1'] = 123;
    backend.sizes['base-q5_1'] = 123;
    final settings = FakeVoiceTextSettings(modelName: 'small-q5_1');
    final c = controller(backend, settings);
    await c.initialize();
    await c.deleteModel();
    expect(c.model.modelName, 'base-q5_1');
    expect(settings.modelName, 'base-q5_1');
  });
}
