# Android activity

MainActivity retains FlutterActivity plugin registration. The experimental voice-to-text feature adds one read-only MethodChannel: `fikra/voice_text_storage`, method `availableBytes`. It returns StatFs(applicationInfo.dataDir).availableBytes as a long so Dart can check the private-storage filesystem before downloading a model. Exceptions return a storage error; unknown calls are not implemented. No permissions, recording settings, database, model engine or build configuration change.

Verify with the Android build and a phone download attempt, including insufficient storage. Widget tests fake the feature's backend; Android StatFs needs device verification.
