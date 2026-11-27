import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/redesign_tokens.dart';
import '../../core/widgets/redesign_widgets.dart';
import '../../data/product/models.dart';

abstract interface class NoteSharing {
  bool get available;
  Future<void> share(Uint8List bytes, {required String filename, required String mime});
}

class DeviceNoteSharing implements NoteSharing {
  static const _channel = MethodChannel('fikrah/share');
  @override
  bool get available => !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  @override
  Future<void> share(Uint8List bytes, {required String filename, required String mime}) async {
    if (!available) throw const ProductFailure(FailureKind.unavailable);
    try {
      await _channel.invokeMethod<void>('file', {'bytes': bytes, 'filename': filename, 'mime': mime});
    } catch (_) {
      throw const ProductFailure(FailureKind.unavailable);
    }
  }
}

final noteSharingProvider = Provider<NoteSharing>((ref) => DeviceNoteSharing());

/// The shared image uses real content; long notes have an explicit ellipsis.
/// Full unabridged content remains available through the account export.
Future<Uint8List> noteCardPng(
  BuildContext context, {
  required String title,
  required String content,
  required String timestamp,
  required List<String> tags,
}) async {
  final colors = context.rd;
  TextPainter text(String value, double size, FontWeight weight, {int? maxLines}) => TextPainter(
    text: TextSpan(
      text: value,
      style: RdTokens.style(context, size: size, weight: weight),
    ),
    textDirection: rdDirection(value, Directionality.of(context)),
    maxLines: maxLines,
    ellipsis: maxLines == null ? null : '…',
  )..layout(minWidth: 696, maxWidth: 696);
  final heading = text(title, 48, FontWeight.w600, maxLines: 3),
      body = text(content, 34, FontWeight.w400, maxLines: 30);
  final meta = text(timestamp, 26, FontWeight.w400, maxLines: 2),
      category = text(tags.join(' · '), 24, FontWeight.w400, maxLines: 2);
  final height = (164 + heading.height + 24 + body.height + 32 + category.height + 20 + meta.height + 40).ceil();
  final recorder = ui.PictureRecorder(), canvas = Canvas(recorder);
  canvas.drawRect(Rect.fromLTWH(0, 0, 760, height.toDouble()), Paint()..color = colors.bg);
  final logo = RRect.fromRectAndRadius(
    Rect.fromLTWH(Directionality.of(context) == TextDirection.rtl ? 660 : 32, 32, 68, 68),
    const Radius.circular(20),
  );
  canvas.drawRRect(logo, Paint()..color = colors.lime);
  final mark = TextPainter(
    text: TextSpan(
      text: 'f.',
      style: TextStyle(fontFamily: 'Inter', fontSize: 32, fontWeight: FontWeight.w700, color: colors.onLime),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  mark.paint(canvas, Offset(logo.left + (68 - mark.width) / 2, 32 + (68 - mark.height) / 2));
  var y = 140.0;
  for (final (p, gap) in [(heading, 24.0), (body, 32.0), (category, 20.0), (meta, 40.0)]) {
    p.paint(canvas, Offset(32, y));
    y += p.height + gap;
  }
  final picture = recorder.endRecording(), image = await picture.toImage(760, height);
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  image.dispose();
  picture.dispose();
  heading.dispose();
  body.dispose();
  category.dispose();
  meta.dispose();
  mark.dispose();
  return bytes!.buffer.asUint8List();
}
