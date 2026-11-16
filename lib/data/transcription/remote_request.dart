import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class AudioUpload {
  const AudioUpload({required this.name, required this.length, this.path, this.bytes});
  final String name;
  final int length;
  final String? path;
  final Uint8List? bytes;
  static Future<AudioUpload> open(String path) async =>
      AudioUpload(name: path.split('/').last, path: path, length: await File(path).length());
  String get mime => switch (name.split('.').last.toLowerCase()) {
    'm4a' || 'mp4' => 'audio/mp4',
    'aac' => 'audio/aac',
    'wav' => 'audio/wav',
    'mp3' => 'audio/mpeg',
    'flac' => 'audio/flac',
    'ogg' => 'audio/ogg',
    'webm' => 'audio/webm',
    _ => 'application/octet-stream',
  };
  Stream<List<int>> stream() => bytes != null ? Stream.value(bytes!) : File(path!).openRead();
  Future<Uint8List> readBytes() async => bytes ?? await File(path!).readAsBytes();
}

class RemoteRequest {
  RemoteRequest.json(this.uri, this.headers, this.json)
    : fields = const {},
      audio = null,
      boundary = '',
      method = 'POST';
  RemoteRequest.multipart(this.uri, this.headers, this.fields, this.audio, this.boundary)
    : json = null,
      method = 'POST';
  RemoteRequest.get(this.uri, this.headers)
    : fields = const {},
      audio = null,
      boundary = '',
      json = null,
      method = 'GET';
  final Uri uri;
  final String method;
  final Map<String, String> headers, fields;
  final Map<String, Object?>? json;
  final AudioUpload? audio;
  final String boundary;

  List<int> _prefix() => utf8.encode(
    [
      for (final field in fields.entries)
        '--$boundary\r\nContent-Disposition: form-data; name="${field.key}"\r\n\r\n${field.value}\r\n',
      '--$boundary\r\nContent-Disposition: form-data; name="file"; filename="recording.${audio!.name.split('.').last.replaceAll(RegExp(r'[^a-zA-Z0-9]'), '')}"\r\nContent-Type: ${audio!.mime}\r\n\r\n',
    ].join(),
  );
  List<int> _suffix() => utf8.encode('\r\n--$boundary--\r\n');
  List<int>? _encoded;
  int get contentLength => method == 'GET'
      ? 0
      : json != null
      ? (_encoded ??= utf8.encode(jsonEncode(json))).length
      : _prefix().length + audio!.length + _suffix().length;
  Stream<List<int>> body() async* {
    if (method == 'GET') return;
    if (json != null) {
      yield _encoded ??= utf8.encode(jsonEncode(json));
    } else {
      yield _prefix();
      yield* audio!.stream();
      yield _suffix();
    }
  }

  // Avoid accidentally printing credentials or the base64 audio in diagnostics.
  @override
  String toString() => 'Remote transcription request';
}

class RemoteResponse {
  const RemoteResponse(this.status, this.body);
  final int status;
  final String body;
  @override
  String toString() => 'Remote transcription response ($status)';
}
