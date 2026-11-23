import 'dart:convert';

/// Framing only, with no HTTP connection, endpoint or automatic replay. A later
/// transport maps these payloads to typed feature events after DTO validation.
class ChatFrame {
  const ChatFrame(this.event, this.payload);
  final String event;
  final Map<String, dynamic> payload;
}

Stream<ChatFrame> decodeChatFrames(Stream<List<int>> bytes) async* {
  var event = 'message';
  final data = <String>[];
  await for (final line in bytes.transform(utf8.decoder).transform(const LineSplitter())) {
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        final payload = jsonDecode(data.join('\n'));
        if (payload is! Map<String, dynamic>) throw const FormatException('Invalid chat frame');
        yield ChatFrame(event, payload);
      }
      event = 'message';
      data.clear();
    } else if (!line.startsWith(':')) {
      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'event') event = value;
      if (field == 'data') data.add(value);
    }
  }
  // EOF never dispatches an unterminated frame or confirms an exchange.
}
