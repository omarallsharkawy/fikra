import 'package:fikra/data/ai/demo_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('detects concepts and cluster', () async {
    final c = await DemoAiService.detectConcepts('الـrag بيستخدم embedding مع llm');
    expect(c, containsAll(['RAG', 'Embeddings', 'LLM']));
    expect(await DemoAiService.clusterFor('flutter و riverpod'), 'تطوير التطبيقات');
    expect(await DemoAiService.clusterFor('كلام عام'), 'أفكار عامة');
  });

  test('english keys match whole words only', () async {
    expect(await DemoAiService.detectConcepts('rapid'), isNot(contains('APIs'))); // left boundary
    expect(await DemoAiService.detectConcepts('apiary'), isNot(contains('APIs'))); // right boundary
    expect(await DemoAiService.detectConcepts('ragtime'), isNot(contains('RAG')));
    expect(await DemoAiService.detectConcepts('build'), isNot(contains('تصميم الواجهات')));
    expect(await DemoAiService.detectConcepts('the API is up'), contains('APIs'));
  });

  test('improve expands terms and ends with punctuation', () {
    final out = DemoAiService.improve('الـrag   بيجيب النتايج');
    expect(out, contains('RAG (Retrieval-Augmented Generation)'));
    expect(out.endsWith('.'), isTrue);
    expect(DemoAiService.improve('تمام.'), 'تمام.');
  });
}
