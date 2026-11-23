import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Fakeable native boundary. One subscription per provider container.
abstract interface class GlassPowerSource {
  Stream<bool> watchPowerSaveMode();
}

class AndroidGlassPowerSource implements GlassPowerSource {
  static const _channel = MethodChannel('fikra/glass_power');

  @override
  Stream<bool> watchPowerSaveMode() {
    late final StreamController<bool> controller;
    var revision = 0;
    controller = StreamController<bool>(
      onListen: () async {
        _channel.setMethodCallHandler((call) async {
          if (call.method == 'powerSaveModeChanged') {
            revision++;
            controller.add(call.arguments == true);
          }
        });
        final requestedRevision = revision;
        try {
          final value = await _channel.invokeMethod<bool>('isPowerSaveMode') ?? false;
          if (!controller.isClosed && revision == requestedRevision) controller.add(value);
        } on MissingPluginException {
          if (!controller.isClosed) controller.add(false);
        } on PlatformException {
          // Unknown power state takes the cheap, conservative path.
          if (!controller.isClosed) controller.add(true);
        }
      },
      onCancel: () => _channel.setMethodCallHandler(null),
    );
    return controller.stream;
  }
}

final glassPowerSourceProvider = Provider<GlassPowerSource>((ref) => AndroidGlassPowerSource());
final glassPowerSaveProvider = StreamProvider<bool>((ref) => ref.watch(glassPowerSourceProvider).watchPowerSaveMode());
