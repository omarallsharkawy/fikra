import 'dart:convert';
import 'dart:io';

import 'whisper_metrics.dart';

Future<double> wavSeconds(File file) async {
  final length = await file.length();
  final handle = await file.open();
  try {
    return parseWavHeader(await handle.read(65536), length).seconds;
  } finally {
    await handle.close();
  }
}

class SpikeRecording {
  const SpikeRecording(this.path, this.format, this.seconds);
  final String path;
  final String format;
  final double seconds;
  String get name => path.split('/').last;
  Map<String, Object> toJson() => {'path': path, 'format': format, 'seconds': seconds};
}

class RecordingStore {
  RecordingStore(this.directory);
  final Directory directory;
  File get _index => File('${directory.path}/index.json');

  Future<String> newPath(String extension) async {
    await directory.create(recursive: true);
    return '${directory.path}/rec_${DateTime.now().microsecondsSinceEpoch}.$extension';
  }

  Future<List<SpikeRecording>> load() async {
    await directory.create(recursive: true);
    if (!await _index.exists()) return [];
    final json = jsonDecode(await _index.readAsString()) as List<dynamic>;
    final clips = <SpikeRecording>[];
    for (final entry in json.cast<Map<String, dynamic>>()) {
      final clip = SpikeRecording(
        entry['path'] as String,
        entry['format'] as String,
        (entry['seconds'] as num).toDouble(),
      );
      if (!await File(clip.path).exists()) {
        throw FileSystemException('Saved recording missing. Record another clip.', clip.path);
      }
      clips.add(clip);
    }
    return clips;
  }

  Future<List<SpikeRecording>> add(SpikeRecording clip, List<SpikeRecording> previous) async {
    final all = [clip, ...previous];
    final kept = all.take(10).toList();
    final temporary = File('${_index.path}.part');
    await temporary.writeAsString(jsonEncode(kept.map((c) => c.toJson()).toList()), flush: true);
    await temporary.rename(_index.path);
    for (final old in all.skip(10)) {
      final file = File(old.path);
      if (await file.exists()) await file.delete();
    }
    return kept;
  }

  Future<List<SpikeRecording>> remove(SpikeRecording clip, List<SpikeRecording> previous) async {
    final kept = previous.where((c) => c.path != clip.path).toList();
    final temporary = File('${_index.path}.part');
    await temporary.writeAsString(jsonEncode(kept.map((c) => c.toJson()).toList()), flush: true);
    await temporary.rename(_index.path);
    final file = File(clip.path);
    if (await file.exists()) await file.delete();
    return kept;
  }

  Future<void> appendRun(String line) async {
    await directory.create(recursive: true);
    await File('${directory.path}/runs.jsonl').writeAsString('$line\n', mode: FileMode.append, flush: true);
  }
}
