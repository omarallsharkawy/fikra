import 'package:fikra/features/workspace/word_diff.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final pair in [
    ('', ''),
    ('', 'New thought'),
    ('Old thought', ''),
    ('Same words', 'Same words'),
    ('I work here.', 'I study here.'),
    ('هو شغال في مصر', 'هو بيدرس دلوقتي في مصر'),
    ('الـ Deep Learning\n  مهم.', 'الـ Machine Learning\n  مهم جدًا!'),
    ('A👋B', 'A👋C'),
    ('e\u0301 is useful', 'e\u0301 is very useful'),
    ('A ' * 4000, 'B ' * 4000),
  ]) {
    test('word diff preserves exact before/after (${pair.$1.length}/${pair.$2.length})', () {
      final diff = wordDiff(pair.$1, pair.$2);
      expect(diff.where((c) => c.kind != DiffKind.added).map((c) => c.text).join(), pair.$1);
      expect(diff.where((c) => c.kind != DiffKind.removed).map((c) => c.text).join(), pair.$2);
      if (pair.$1 == pair.$2) expect(diff.where((c) => c.kind != DiffKind.same), isEmpty);
    });
  }
  test('unchanged words remain outside edits', () {
    final diff = wordDiff('I work here.', 'I study here.');
    expect(diff.where((c) => c.kind == DiffKind.removed).single.text, 'work');
    expect(diff.where((c) => c.kind == DiffKind.added).single.text, 'study');
  });
}
