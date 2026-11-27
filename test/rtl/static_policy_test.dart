import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all editable controls use shared direction, no physical text alignment', () {
    final defects = <String>[];
    for (final file in Directory(
      'lib',
    ).listSync(recursive: true).whereType<File>().where((f) => f.path.endsWith('.dart'))) {
      final source = file.readAsStringSync();
      if (RegExp(r'TextAlign\.(left|right)\b').hasMatch(source)) defects.add('${file.path}: physical text alignment');
      if (!file.path.endsWith('/smart_input.dart') &&
          RegExp(r'\b(?:TextField|TextFormField|EditableText)\(').hasMatch(source)) {
        defects.add('${file.path}: editable control bypasses SmartInput');
      }
      if (RegExp(r'EdgeInsets\.only\([^)]*\b(?:left|right):', dotAll: true).hasMatch(source)) {
        defects.add('${file.path}: physical padding');
      }
      if (RegExp(
        r'Directionality\(\s*textDirection:\s*TextDirection\.ltr,\s*child:\s*(FikraField|SmartInput)',
        dotAll: true,
      ).hasMatch(source)) {
        defects.add('${file.path}: identifier direction leaks into input chrome');
      }
      // Raw visible literal text must be localized. Numeric interpolation and
      // unit/API identifiers are data, not new English/Arabic UI copy.
      for (final match in RegExp(r'''\b(?:SmartText|RdText)\(\s*['"]([^'"\n]+)['"]''').allMatches(source)) {
        final value = match[1]!;
        if (!value.contains(r'$') && RegExp(r'[A-Za-z\u0620-\u064a]').hasMatch(value)) {
          defects.add('${file.path}: unlocalized visible literal "$value"');
        }
      }
    }
    expect(defects, isEmpty, reason: defects.join('\n'));
  });
}
