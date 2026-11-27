import 'package:fikra/data/product/local_ui_store.dart';
import 'package:fikra/features/account/profile_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('local name survives verified login and is isolated from other accounts', () async {
    final store = MemoryLocalUiStore();
    final first = ProfileController(store);
    addTearDown(first.dispose);
    expect(await first.stageRegistration(' OWNER@example.invalid ', '  علاء  '), isTrue);
    await first.bind('owner', 'owner@example.invalid');
    expect(first.name, 'علاء');
    expect(first.initial, 'ع');
    expect(first.needsNamePrompt, isFalse);
    await first.bind(null, '');
    expect(first.name, isNull);
    await first.bind('other', 'other@example.invalid');
    expect(first.name, isNull);
    expect(first.needsNamePrompt, isTrue);
    expect(await first.claimNamePrompt(), isTrue);
    expect(await first.claimNamePrompt(), isFalse);
    final restarted = ProfileController(store);
    addTearDown(restarted.dispose);
    await restarted.bind('other', 'other@example.invalid');
    expect(restarted.needsNamePrompt, isFalse);
    await restarted.bind('owner', 'owner@example.invalid');
    expect(restarted.name, 'علاء');
    expect(await restarted.setName('  alice  '), isTrue);
    expect(restarted.initial, 'A');
    final record = await store.read('registration:owner@example.invalid');
    expect(record['display_name'], isNull);
  });
  test('name validation trims and counts grapheme clusters without restricting language', () {
    expect(ProfileController.validName('  '), isFalse);
    expect(ProfileController.validName('ع' * 40), isTrue);
    expect(ProfileController.validName('ع' * 41), isFalse);
    expect(ProfileController.validName(' e\u0301 '), isTrue);
    expect(ProfileController.validName('李明'), isTrue);
  });
  test('serialized device updates preserve independent presentation fields', () async {
    final store = MemoryLocalUiStore();
    await Future.wait([
      store.update('account:a', (r) => r['display_name'] = 'Owner'),
      store.update(
        'account:a',
        (r) => r['drafts'] = {
          'project': {'content': 'Private thought'},
        },
      ),
      store.update('account:b', (r) => r['display_name'] = 'Other'),
    ]);
    final record = await store.read('account:a');
    expect(record['display_name'], 'Owner');
    expect(record['drafts'], isNotNull);
    record.clear();
    expect((await store.read('account:a'))['display_name'], 'Owner');
    expect((await store.read('account:b'))['drafts'], isNull);
  });
}
