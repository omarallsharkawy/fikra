import 'package:fikra/data/product/local_ui_store.dart';
import 'package:fikra/features/workspace/local_tags_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user categories persist independently of concepts, names and other accounts', () async {
    final store = MemoryLocalUiStore();
    final a = LocalTagsController(store);
    addTearDown(a.dispose);
    await a.bind('a');
    expect(a.tags, isEmpty);
    final tag = await a.create('  جامعة  ', color: 2);
    expect(tag!.label, 'جامعة');
    expect((await a.create('جامعة'))!.id, tag.id);
    expect(await a.assign('note-a', {tag.id, 'unknown-id'}), isTrue);
    expect(a.forNote('note-a').single.id, tag.id);
    await store.update('account:a', (r) => r['display_name'] = 'Owner');
    expect(await a.rename(tag.id, 'دراسة', color: 1), isTrue);
    expect(a.forNote('note-a').single.label, 'دراسة');
    final restarted = LocalTagsController(store);
    addTearDown(restarted.dispose);
    await restarted.bind('a');
    expect(restarted.forNote('note-a').single.color, 1);
    expect((await store.read('account:a'))['display_name'], 'Owner');
    await restarted.bind('b');
    expect(restarted.tags, isEmpty);
    expect(restarted.forNote('note-a'), isEmpty);
    await a.assign('note-a', {});
    expect(a.forNote('note-a'), isEmpty);
  });
}
