import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects concepts and cluster', () {
    final c = DemoAiService.detectConcepts('الـrag بيستخدم embedding مع llm');
    expect(c, containsAll(['RAG', 'Embeddings', 'LLM']));
    expect(DemoAiService.clusterFor('flutter و riverpod'), 'تطوير التطبيقات');
    expect(DemoAiService.clusterFor('كلام عام'), 'أفكار عامة');
  });

  test('english keys match whole words only', () {
    expect(DemoAiService.detectConcepts('rapid'), isNot(contains('APIs'))); // left boundary
    expect(DemoAiService.detectConcepts('apiary'), isNot(contains('APIs'))); // right boundary
    expect(DemoAiService.detectConcepts('ragtime'), isNot(contains('RAG')));
    expect(DemoAiService.detectConcepts('build'), isNot(contains('تصميم الواجهات')));
    expect(DemoAiService.detectConcepts('the API is up'), contains('APIs'));
  });

  test('improve expands terms and ends with punctuation', () {
    final out = DemoAiService.improve('الـrag   بيجيب النتايج');
    expect(out, contains('RAG (Retrieval-Augmented Generation)'));
    expect(out.endsWith('.'), isTrue);
    expect(DemoAiService.improve('تمام.'), 'تمام.');
  });

  test('upload fails for large files', () async {
    expect(
      DemoUploader().upload(path: 'x', name: 'a.pdf', bytes: DemoUploader.maxBytes + 1).toList(),
      throwsA(isA<Exception>()),
    );
  });
}
