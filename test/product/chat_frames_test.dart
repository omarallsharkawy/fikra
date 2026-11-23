import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:fikra/data/product/chat_frames.dart';

void main() {
  test('split UTF-8, CRLF and multiple frames preserve Arabic text', () async {
    final bytes = utf8.encode(
      ': comment\r\nevent: delta\r\ndata: {"content":"أهلاً"}\r\n\r\nevent: complete\r\ndata: {"confirmed":true}\r\n\r\n',
    );
    final frames = await decodeChatFrames(
      Stream.fromIterable([
        for (final byte in bytes) [byte],
      ]),
    ).toList();
    expect(frames.map((e) => e.event), ['delta', 'complete']);
    expect(frames.first.payload['content'], 'أهلاً');
    expect(frames.last.payload['confirmed'], isTrue);
  });
  test('multiline data and absent event names follow frame boundaries', () async {
    final frames = await decodeChatFrames(
      Stream.value(utf8.encode('data: {"content":\ndata: "Hello"}\n\nevent: delta\ndata: {"content":"next"}\n\n')),
    ).toList();
    expect(frames.first.event, 'message');
    expect(frames.first.payload['content'], 'Hello');
    expect(frames.last.event, 'delta');
  });
  test('partial trailing frames do not become saved completion events', () async {
    final frames = await decodeChatFrames(
      Stream.value(utf8.encode('event: delta\ndata: {"content":"preview"}\n\nevent: complete\ndata: {"saved":true}\n')),
    ).toList();
    expect(frames.length, 1);
    expect(frames.single.event, 'delta');
  });
  test('malformed frames fail instead of inventing successful output', () async {
    await expectLater(
      decodeChatFrames(Stream.value(utf8.encode('event: complete\ndata: invalid\n\n'))).toList(),
      throwsFormatException,
    );
  });
}
