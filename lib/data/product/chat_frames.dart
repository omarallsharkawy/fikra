import 'dart:convert';

/// Framing only, with no HTTP connection, endpoint or automatic replay. A later
/// transport maps these payloads to typed feature events after DTO validation.
class ChatFrame {
  const ChatFrame(this.event, this.payload);
  final String event;
  final Map<String, dynamic> payload;
}

const _maxFrameChars = 2 * 1024 * 1024;

/// Splits UTF-8 text chunks into lines while bounding buffered line length so an
/// unterminated multi-megabyte line cannot grow unboundedly before line framing.
Stream<String> _boundedLines(Stream<List<int>> bytes) async* {
  final buffer = StringBuffer();
  var pendingCr = false;
  await for (final chunk in bytes.transform(utf8.decoder)) {
    var start = 0;
    if (pendingCr) {
      pendingCr = false;
      if (chunk.isNotEmpty && chunk.codeUnitAt(0) == 0x0A) start = 1;
    }
    for (var i = start; i < chunk.length; i++) {
      final code = chunk.codeUnitAt(i);
      if (code == 0x0A || code == 0x0D) {
        if (i > start) buffer.write(chunk.substring(start, i));
        yield buffer.toString();
        buffer.clear();
        if (code == 0x0D) {
          if (i + 1 < chunk.length && chunk.codeUnitAt(i + 1) == 0x0A) {
            i++;
          } else if (i + 1 == chunk.length) {
            pendingCr = true;
          }
        }
        start = i + 1;
      }
    }
    if (start < chunk.length) {
      buffer.write(chunk.substring(start));
      if (buffer.length > _maxFrameChars) throw const FormatException('Chat frame too large');
    }
  }
  if (buffer.isNotEmpty) yield buffer.toString();
}

Stream<ChatFrame> decodeChatFrames(Stream<List<int>> bytes) async* {
  var event = 'message';
  final data = <String>[];
  var frameChars = 0;
  var firstLine = true;
  await for (var line in _boundedLines(bytes)) {
    if (firstLine) {
      firstLine = false;
      if (line.startsWith('\uFEFF')) line = line.substring(1);
    }
    if (line.isEmpty) {
      if (data.isNotEmpty) {
        final payload = jsonDecode(data.join('\n'));
        if (payload is! Map<String, dynamic>) throw const FormatException('Invalid chat frame');
        yield ChatFrame(event, payload);
      }
      event = 'message';
      data.clear();
      frameChars = 0;
    } else if (!line.startsWith(':')) {
      final separator = line.indexOf(':');
      final field = separator < 0 ? line : line.substring(0, separator);
      var value = separator < 0 ? '' : line.substring(separator + 1);
      if (value.startsWith(' ')) value = value.substring(1);
      if (field == 'event') event = value;
      if (field == 'data') {
        frameChars += value.length;
        if (frameChars > _maxFrameChars) throw const FormatException('Chat frame too large');
        data.add(value);
      }
    }
  }
  // EOF never dispatches an unterminated frame or confirms an exchange.
}
