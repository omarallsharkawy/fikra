import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart' show Bidi;

import 'unicode_bidi_ranges.dart';

/// UI direction and user-content direction are deliberately independent.
TextDirection contentDirection(String text, [TextDirection fallback = TextDirection.ltr]) {
  var isolateDepth = 0;
  for (final rune in text.runes) {
    if (rune >= 0x2066 && rune <= 0x2068) {
      isolateDepth++;
      continue;
    }
    if (rune == 0x2069) {
      if (isolateDepth > 0) isolateDepth--;
      continue;
    }
    if (isolateDepth > 0) continue;
    var low = 0, high = strongBidiRanges.length ~/ 3 - 1;
    while (low <= high) {
      final mid = (low + high) ~/ 2, at = mid * 3;
      if (rune < strongBidiRanges[at]) {
        high = mid - 1;
      } else if (rune > strongBidiRanges[at + 1]) {
        low = mid + 1;
      } else {
        return strongBidiRanges[at + 2] < 0 ? TextDirection.rtl : TextDirection.ltr;
      }
    }
  }
  return fallback;
}

String bidiIsolate(String value) => '\u2068$value\u2069';

/// Presentation only. Never insert bidi controls into editable values or API data.
/// Keep opposite-script phrases/addresses together inside mixed paragraphs.
String isolateMixedText(String value, TextDirection base) {
  if (!Bidi.hasAnyRtl(value) || !Bidi.hasAnyLtr(value)) return value;
  // Existing interpolations already explicitly isolate their dynamic fragments.
  final parts = value.split(RegExp(r'([\u2066-\u2069])'));
  if (parts.length != 1) return value;
  final opposite = base == TextDirection.rtl
      ? RegExp(
          r'(?:https?://|www\.)[^\s\u0600-\u06ff]+|[A-Za-z0-9_.+\-]+@[A-Za-z0-9.\-]+|[#@]?[A-Za-z0-9][A-Za-z0-9_./:%+\-]*(?:[ \t]+[A-Za-z0-9][A-Za-z0-9_./:%+\-]*)*',
        )
      : RegExp(
          r'[\u0620-\u063f\u0641-\u064a\u066e-\u06d3\u06fa-\u06fc][\u0620-\u065f\u066e-\u06d3\u06fa-\u06fc]*(?:[ \t]+[\u0620-\u065f\u066e-\u06d3\u06fa-\u06fc]+)*',
        );
  return value.replaceAllMapped(opposite, (m) {
    final token = m[0]!;
    // Keep sentence punctuation outside URL isolates.
    final end = RegExp(r'[.!?:;,\)\]\}]+$').firstMatch(token)?.start ?? token.length;
    return '${bidiIsolate(token.substring(0, end))}${token.substring(end)}';
  });
}
