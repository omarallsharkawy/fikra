import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

class SpikeModel {
  const SpikeModel(this.family, this.quantized);
  final String family;
  final bool quantized;
  String get modelName => '$family${quantized ? '-q5_1' : ''}';
  String get filename => 'ggml-$modelName.bin';
}

const spikeModels = [
  SpikeModel('tiny', true),
  SpikeModel('tiny', false),
  SpikeModel('base', true),
  SpikeModel('base', false),
  SpikeModel('small', true),
  SpikeModel('small', false),
];

String modelUrl(SpikeModel model) =>
    'https://huggingface.co/ggerganov/whisper.cpp/resolve/main/ggml-${model.modelName}.bin';

/// A separate downloader supplies cancellation, idle timeout and length checks
/// missing from the package downloader. Inference uses whisper_ggml with modelPath.
class SpikeModelStore {
  SpikeModelStore(this.directory);

  final Directory directory;
  HttpClient? _client;
  bool _cancelled = false;

  File file(SpikeModel model) => File('${directory.path}/${model.filename}');
  File _receipt(SpikeModel model) => File('${file(model).path}.json');

  void cancelDownload() {
    _cancelled = true;
    _client?.close(force: true);
  }

  Future<void> delete(SpikeModel model) async {
    for (final f in [file(model), _receipt(model), File('${file(model).path}.part')]) {
      if (await f.exists()) await f.delete();
    }
  }

  /// Structural checks, not a cryptographic integrity guarantee. Native loading
  /// checks tensor layout; same-length corruption of weights can go undetected.
  Future<void> validate(SpikeModel model, {File? candidate}) async {
    final f = candidate ?? file(model);
    if (!await f.exists()) throw StateError('Model missing. Download ${model.modelName} first.');
    final size = await f.length();
    if (size < 1024 * 1024) throw const FormatException('Corrupt model: file too small. Delete and download again.');
    final handle = await f.open();
    late final Uint8List header;
    try {
      header = await handle.read(48);
    } finally {
      await handle.close();
    }
    final data = ByteData.sublistView(header);
    // GGML_FILE_MAGIC 0x67676d6c is stored little endian (not ASCII "ggml").
    final layers = switch (model.family) {
      'tiny' => 4,
      'base' => 6,
      _ => 12,
    };
    final width = switch (model.family) {
      'tiny' => 384,
      'base' => 512,
      _ => 768,
    };
    if (header.length != 48 ||
        data.getUint32(0, Endian.little) != 0x67676d6c ||
        data.getInt32(4, Endian.little) != 51865 ||
        data.getInt32(8, Endian.little) != 1500 ||
        data.getInt32(12, Endian.little) != width ||
        data.getInt32(20, Endian.little) != layers ||
        data.getInt32(24, Endian.little) != 448 ||
        data.getInt32(28, Endian.little) != width ||
        data.getInt32(36, Endian.little) != layers ||
        data.getInt32(40, Endian.little) != 80 ||
        data.getInt32(44, Endian.little) % 1000 != (model.quantized ? 9 : 1)) {
      throw FormatException('Corrupt or wrong ${model.modelName} multilingual GGML model. Delete and download again.');
    }
    if (candidate == null && await _receipt(model).exists()) {
      final receipt = jsonDecode(await _receipt(model).readAsString()) as Map<String, dynamic>;
      if (receipt['bytes'] != size) throw const FormatException('Corrupt model: size changed since download.');
    }
  }

  /// A killed process cannot run finally; report and clear its partial files.
  Future<List<String>> clearInterruptedDownloads() async {
    final interrupted = <String>[];
    for (final model in spikeModels) {
      final partial = File('${file(model).path}.part');
      if (await partial.exists()) {
        interrupted.add(model.modelName);
        await partial.delete();
      }
    }
    return interrupted;
  }

  Future<void> download(SpikeModel model, void Function(int, int) progress) async {
    _cancelled = false;
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 30);
    _client = client;
    final part = File('${file(model).path}.part');
    RandomAccessFile? output;
    try {
      await directory.create(recursive: true);
      final request = await client.getUrl(Uri.parse(modelUrl(model))).timeout(const Duration(seconds: 30));
      final response = await request.close().timeout(const Duration(seconds: 30));
      if (response.statusCode != 200) throw HttpException('Model download HTTP ${response.statusCode}');
      output = await part.open(mode: FileMode.write);
      var received = 0;
      progress(0, response.contentLength);
      await for (final chunk in response.timeout(const Duration(seconds: 45))) {
        if (_cancelled) throw StateError('Download cancelled. Retry to restart.');
        await output.writeFrom(chunk);
        received += chunk.length;
        progress(received, response.contentLength);
      }
      await output.close();
      output = null;
      if (_cancelled) throw StateError('Download cancelled.');
      if (response.contentLength > 0 && received != response.contentLength) {
        throw const FormatException('Download interrupted: byte count does not match Content-Length. Retry.');
      }
      await validate(model, candidate: part);
      await part.rename(file(model).path);
      await _receipt(model).writeAsString(jsonEncode({'bytes': received, 'url': modelUrl(model)}), flush: true);
    } catch (error) {
      if (_cancelled) throw StateError('Download cancelled. Retry to restart.');
      rethrow;
    } finally {
      client.close(force: true);
      _client = null;
      try {
        await output?.close();
      } finally {
        if (await part.exists()) await part.delete();
      }
    }
  }
}
