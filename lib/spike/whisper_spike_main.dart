import 'dart:async';
import 'dart:convert';
import 'dart:io';

// Read timing from the FFmpeg dependency already brought by whisper_ggml.
// ignore: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit_config.dart';
// ignore: depend_on_referenced_packages
import 'package:ffmpeg_kit_flutter_new_min/ffmpeg_kit.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:whisper_ggml/whisper_ggml.dart';

import 'whisper_metrics.dart';
import 'whisper_models.dart';
import 'whisper_recordings.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    MaterialApp(
      title: 'FIKRA Whisper spike',
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'NotoSansArabic',
        textTheme: const TextTheme(bodyMedium: TextStyle(fontSize: 18), bodyLarge: TextStyle(fontSize: 20)),
      ),
      home: const WhisperSpikeScreen(),
    ),
  );
}

class WhisperSpikeScreen extends StatefulWidget {
  const WhisperSpikeScreen({super.key});
  @override
  State<WhisperSpikeScreen> createState() => _WhisperSpikeScreenState();
}

class _WhisperSpikeScreenState extends State<WhisperSpikeScreen> {
  final _recorder = AudioRecorder();
  final _clock = Stopwatch();
  final _history = <String>[];
  final _sizes = <String, int>{};
  SpikeModelStore? _models;
  RecordingStore? _recordings;
  List<SpikeRecording> _clips = [];
  SpikeRecording? _clip;
  SpikeModel _model = spikeModels.first;
  String _language = 'ar';
  int _threads = 4;
  String _status = 'Opening private spike storage…';
  String _text = '';
  String _codecStatus = 'FFmpeg capabilities not checked';
  final _codecInfo = <String, Object?>{};
  String? _error;
  String? _format;
  bool _busy = true;
  bool _recording = false;
  bool _downloading = false;
  int _received = 0;
  int _total = -1;
  Timer? _timer;
  WhisperLiveSession? _live;
  StreamSubscription<dynamic>? _audioSub;
  StreamSubscription<String>? _partialSub;
  Map<String, Object?>? _liveRun;
  Stopwatch? _liveWall;
  int _liveBytes = 0;
  String? _liveError;

  bool get _idle => !_busy && !_recording && !_downloading && _liveRun == null;

  @override
  void initState() {
    super.initState();
    unawaited(_init());
  }

  void _update(VoidCallback action) {
    if (mounted) setState(action);
  }

  void _fail(Object error) => _update(() => _error = error.toString());

  Future<void> _init() async {
    try {
      final support = await getApplicationSupportDirectory();
      final root = Directory('${support.path}/fikra_whisper_spike');
      await root.create(recursive: true);
      _models = SpikeModelStore(Directory('${root.path}/models'));
      _recordings = RecordingStore(Directory('${root.path}/recordings'));
      final interrupted = await _models!.clearInterruptedDownloads();
      if (interrupted.isNotEmpty) {
        _error = 'Interrupted model download cleared: ${interrupted.join(', ')}. Download again to restart.';
      }
      _clips = await _recordings!.load();
      _clip = _clips.firstOrNull;
      await _refreshSizes();
      _status = 'Ready. Start with tiny-q5_1. Keep this screen open during tests.';
      // Probe the shipped binary, since the pub cache does not include FFmpeg's
      // native build configuration or codec source.
      try {
        final version = await FFmpegKitConfig.getFFmpegVersion();
        final decoders = await FFmpegKit.execute('-hide_banner -decoders');
        final demuxers = await FFmpegKit.execute('-hide_banner -demuxers');
        final decoderText = await decoders.getOutput() ?? '';
        final demuxerText = await demuxers.getOutput() ?? '';
        final aac = RegExp(r'^\s*A\S*\s+aac\s', multiLine: true).hasMatch(decoderText);
        final m4a = RegExp(r'^\s*D\S*\s+\S*mov,mp4,m4a', multiLine: true).hasMatch(demuxerText);
        if ((await decoders.getReturnCode())?.getValue() != 0 || (await demuxers.getReturnCode())?.getValue() != 0) {
          throw StateError('FFmpeg capability probe failed. Try an AAC recording to inspect conversion errors.');
        }
        _codecInfo.addAll({'ffmpeg_version': version, 'aac_decoder': aac, 'm4a_demuxer': m4a});
        _codecStatus = 'FFmpeg $version · AAC decoder: $aac · M4A demuxer: $m4a';
        if (!aac || !m4a) {
          _error = 'AAC / M4A support not found in FFmpeg capability output. Try WAV and inspect the AAC run.';
        }
      } catch (e) {
        _codecStatus = 'FFmpeg probe failed: $e';
        _codecInfo['probe_error'] = e.toString();
        _fail(_codecStatus);
      }
    } catch (e) {
      _fail(e);
    } finally {
      _update(() => _busy = false);
    }
  }

  Future<void> _refreshSizes() async {
    for (final model in spikeModels) {
      final file = _models!.file(model);
      _sizes[model.modelName] = await file.exists() ? await file.length() : 0;
    }
    _update(() {});
  }

  Future<void> _download() async {
    final model = _model;
    _update(() {
      _downloading = true;
      _error = null;
      _received = 0;
      _total = -1;
      _status = 'Downloading ${model.filename}';
    });
    final progressClock = Stopwatch()..start();
    try {
      await _models!.download(model, (received, total) {
        if (received != 0 && received != total && progressClock.elapsedMilliseconds < 120) return;
        progressClock.reset();
        _update(() {
          _received = received;
          _total = total;
        });
      });
      _status = 'Downloaded ${model.filename}';
    } catch (e) {
      _status = 'Download did not complete. Retry to restart, or choose another model.';
      _fail(e);
    } finally {
      try {
        await _refreshSizes();
      } catch (e) {
        _fail(e);
      }
      _update(() => _downloading = false);
    }
  }

  Future<void> _delete() async {
    _update(() => _busy = true);
    try {
      await _models!.delete(_model);
      await _refreshSizes();
      _status = 'Model deleted';
    } catch (e) {
      _fail(e);
    } finally {
      _update(() => _busy = false);
    }
  }

  void _startClock() {
    _clock
      ..reset()
      ..start();
    _timer = Timer.periodic(const Duration(milliseconds: 200), (_) => _update(() {}));
  }

  void _stopClock() {
    _clock.stop();
    _timer?.cancel();
  }

  Future<void> _startRecording(bool aac) async {
    _update(() {
      _busy = true;
      _error = null;
    });
    try {
      if (!await _recorder.hasPermission()) {
        throw StateError('Microphone permission denied. Allow Microphone in Android app settings and retry.');
      }
      _format = aac ? 'aac_lc_m4a_64k_mono' : 'wav_pcm16_16khz_mono';
      final path = await _recordings!.newPath(aac ? 'm4a' : 'wav');
      await _recorder.start(
        aac
            ? const RecordConfig(encoder: AudioEncoder.aacLc, numChannels: 1, bitRate: 64000)
            : const RecordConfig(encoder: AudioEncoder.wav, sampleRate: 16000, numChannels: 1),
        path: path,
      );
      _startClock();
      _recording = true;
      _status = aac ? 'Recording app-format AAC / M4A' : 'Recording 16 kHz mono PCM16 WAV';
    } catch (e) {
      _fail(e);
      try {
        await _recorder.cancel();
      } catch (cleanup) {
        _fail('$e; recorder cleanup: $cleanup');
      }
    } finally {
      _update(() => _busy = false);
    }
  }

  Future<void> _stopRecording() async {
    _update(() => _busy = true);
    _stopClock();
    try {
      final path = await _recorder.stop();
      if (path == null) throw StateError('Recording interrupted: no file returned. Record again.');
      final file = File(path);
      if (await file.length() == 0 || _clock.elapsedMilliseconds < 250) {
        throw StateError('Empty recording. Record at least a short phrase and retry.');
      }
      final seconds = _format!.startsWith('wav') ? await wavSeconds(file) : _clock.elapsedMilliseconds / 1000;
      final clip = SpikeRecording(path, _format!, seconds);
      _clips = await _recordings!.add(clip, _clips);
      _clip = clip;
      _status = 'Recording saved. Choose a model and Transcribe.';
    } catch (e) {
      _fail(e);
      try {
        await _recorder.cancel();
      } catch (cleanup) {
        _fail('$e; recorder cleanup: $cleanup');
      }
    } finally {
      _update(() {
        _recording = false;
        _busy = false;
      });
    }
  }

  Map<String, Object?> _newRun(String format, double seconds, String mode) => {
    'timestamp': DateTime.now().toUtc().toIso8601String(),
    'mode': mode,
    'model': _model.filename,
    'model_bytes': _sizes[_model.modelName],
    'model_url': modelUrl(_model),
    'ffmpeg': Map<String, Object?>.of(_codecInfo),
    'language': _language,
    'threads': _threads,
    'source_format': format,
    'audio_seconds': seconds,
    'audio_duration_source': format.startsWith('aac') ? 'recording_clock_estimate' : 'pcm_samples',
    'wall_ms': 0,
    'rtf': null,
    'conversion_ms': null,
    'transcription_wall_ms_estimate': null,
    'model_load_ms': null,
    'rss_before_mb': memoryMb(ProcessInfo.currentRss),
    'max_rss_before_mb': memoryMb(ProcessInfo.maxRss),
    'text': '',
    'error': null,
  };

  Future<void> _finishRun(Map<String, Object?> run, int wallMs) async {
    run.addAll({
      'wall_ms': wallMs,
      'rtf': realTimeFactor(wallMs, (run['audio_seconds'] as num).toDouble()),
      'rss_after_mb': memoryMb(ProcessInfo.currentRss),
      'rss_max_mb': memoryMb(ProcessInfo.maxRss),
    });
    var line = whisperLogLine(run);
    try {
      await _recordings!.appendRun(line);
    } catch (e) {
      run['history_storage_error'] = e.toString();
      _fail('Could not persist run history: $e');
      line = whisperLogLine(run);
    }
    // Intentionally unthrottled: one JSON line per run, including failures.
    // ignore: avoid_print
    print(line);
    _update(() {
      _history.insert(0, line);
      _text = run['text'] as String;
      if (run['error'] != null) _error = run['error'].toString();
    });
  }

  Future<void> _transcribe() async {
    final clip = _clip!;
    final model = _model;
    final run = _newRun(clip.format, clip.seconds, 'file');
    final wall = Stopwatch();
    int? previousSession;
    _update(() {
      _busy = true;
      _error = null;
      _text = '';
      _status = 'Transcribing ${model.modelName}…';
    });
    try {
      await _models!.validate(model);
      if (clip.format.startsWith('wav')) run['audio_seconds'] = await wavSeconds(File(clip.path));
      previousSession = (await FFmpegKitConfig.getLastSession())?.getSessionId();
      wall.start();
      final result = await Whisper(model: WhisperModel.tiny).transcribe(
        modelPath: _models!.file(model).path,
        transcribeRequest: TranscribeRequest(
          audio: clip.path,
          language: _language,
          threads: _threads,
          isNoTimestamps: true,
          keepModelLoaded: false,
        ),
        onProgress: (percent) => _update(() => _status = 'Transcribing ${model.modelName}: $percent%'),
      );
      run['text'] = result.text;
    } catch (e) {
      run['error'] = e.toString();
    } finally {
      wall.stop();
      // The public API always converts, including WAV. The FFmpeg session
      // duration excludes Dart/platform setup; the subtraction is an estimate.
      try {
        final session = await FFmpegKitConfig.getLastSession();
        if (wall.elapsedMicroseconds > 0 &&
            session != null &&
            session.getSessionId() != previousSession &&
            (session.getArguments()?.contains(clip.path) ?? false)) {
          final conversionMs = await session.getDuration();
          run['conversion_ms'] = conversionMs;
          run['transcription_wall_ms_estimate'] = (wall.elapsedMilliseconds - conversionMs).clamp(0, 1 << 62);
          final code = await session.getReturnCode();
          if (code == null || code.getValue() != 0) {
            run['error'] = '${run['error'] ?? ''} FFmpeg conversion failed: ${code?.getValue()}';
          } else {
            try {
              run['audio_seconds'] = await wavSeconds(File('${clip.path}.wav'));
              run['audio_duration_source'] = 'converted_wav_header';
            } catch (e) {
              run['error'] = '${run['error'] ?? ''} Invalid/empty converted audio: $e';
            }
          }
        }
      } catch (e) {
        run['timing_error'] = e.toString();
        _fail('Conversion timing/duration unavailable: $e');
      }
      try {
        final converted = File('${clip.path}.wav');
        if (await converted.exists()) await converted.delete();
      } catch (e) {
        run['cleanup_error'] = e.toString();
        _fail('Converted WAV cleanup failed: $e');
      }
      await _finishRun(run, wall.elapsedMilliseconds);
      _update(() {
        _busy = false;
        _status = 'Run complete. Load time is included; not separately exposed by one-shot API.';
      });
    }
  }

  Future<void> _startLive() async {
    final run = _newRun('live_pcm16_16khz_mono', 0, 'live');
    _liveRun = run;
    _liveWall = Stopwatch()..start();
    _liveBytes = 0;
    _liveError = null;
    _update(() {
      _busy = true;
      _error = null;
      _text = '';
      _status = 'Loading live model…';
    });
    try {
      await _models!.validate(_model);
      if (!await _recorder.hasPermission()) throw StateError('Microphone permission denied. Allow it in app settings.');
      final load = Stopwatch()..start();
      _live = await startWhisperLiveSession(modelPath: _models!.file(_model).path, lang: _language, threads: _threads);
      load.stop();
      run['model_load_ms'] = load.elapsedMilliseconds;
      run['model_load_note'] = 'Live startup includes isolate + native context initialization';
      _partialSub = _live!.partials.listen(
        (text) => _update(() => _text = text),
        onError: (Object e) {
          _liveError = e.toString();
          _fail(e);
          if (!_busy) unawaited(_stopLive());
        },
      );
      final stream = await _recorder.startStream(
        const RecordConfig(encoder: AudioEncoder.pcm16bits, sampleRate: 16000, numChannels: 1),
      );
      _audioSub = stream.listen(
        (bytes) {
          _liveBytes += bytes.length;
          _live?.feed(bytes);
        },
        onError: (Object e) {
          _liveError = e.toString();
          _fail(e);
          if (!_busy) unawaited(_stopLive());
        },
        onDone: () {
          if (!_busy && _liveRun != null) unawaited(_stopLive());
        },
      );
      _startClock();
      _update(() {
        _busy = false;
        _status = 'LIVE: speak now. Partials replace earlier text. Stop to finalize.';
      });
      if (_liveError != null) await _stopLive();
    } catch (e) {
      _liveError = e.toString();
      await _stopLive();
    }
  }

  Future<void> _stopLive() async {
    final run = _liveRun;
    if (run == null) return;
    _update(() {
      _busy = true;
      _status = 'Finalizing live audio; queued inference may take time…';
    });
    _stopClock();
    final finalize = Stopwatch()..start();
    try {
      await _recorder.stop();
    } catch (e) {
      _liveError = '${_liveError ?? ''} Recorder stop: $e';
    }
    try {
      await _audioSub?.cancel();
      _audioSub = null;
      run['text'] = await _live?.stop() ?? _text;
      await _partialSub?.cancel();
      _partialSub = null;
    } catch (e) {
      _liveError = '${_liveError ?? ''} Live finalization: $e';
    }
    finalize.stop();
    _liveWall!.stop();
    run['audio_seconds'] = _liveBytes / 32000;
    run['finalization_ms'] = finalize.elapsedMilliseconds;
    run['error'] = _liveError ?? (_liveBytes == 0 ? 'Empty live recording: no microphone audio received.' : null);
    await _finishRun(run, _liveWall!.elapsedMilliseconds);
    _update(() {
      _live = null;
      _liveRun = null;
      _busy = false;
      _status = 'Live complete. Wall time includes listening, startup and finalization; RTF is not decode speed.';
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _models?.cancelDownload();
    unawaited(_audioSub?.cancel());
    unawaited(_partialSub?.cancel());
    // Closing the screen cannot cancel a native decode; stop drains live work.
    unawaited(_live?.stop());
    unawaited(_recorder.dispose());
    super.dispose();
  }

  Widget _heading(String text) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 12),
    child: Text(text, style: Theme.of(context).textTheme.titleLarge),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('FIKRA · Whisper test')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text(_status),
            SelectableText(_codecStatus, style: const TextStyle(fontSize: 14)),
            if (_busy) const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: LinearProgressIndicator()),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: SelectableText(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
              ),
            _heading('Model · multilingual Arabic + English'),
            DropdownButtonFormField<SpikeModel>(
              initialValue: _model,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Model file', border: OutlineInputBorder()),
              items: spikeModels.map((m) {
                final bytes = _sizes[m.modelName] ?? 0;
                return DropdownMenuItem(
                  value: m,
                  child: Text(
                    '${m.modelName} · ${bytes == 0 ? 'not downloaded' : '${memoryMb(bytes).toStringAsFixed(1)} MiB'}',
                  ),
                );
              }).toList(),
              onChanged: _idle ? (m) => setState(() => _model = m!) : null,
            ),
            if (_models != null) SelectableText(_models!.file(_model).path, style: const TextStyle(fontSize: 14)),
            Wrap(
              spacing: 12,
              children: [
                FilledButton(onPressed: _idle ? _download : null, child: const Text('Download model')),
                OutlinedButton(onPressed: _idle ? _delete : null, child: const Text('Delete model')),
                if (_downloading) TextButton(onPressed: _models!.cancelDownload, child: const Text('Cancel download')),
              ],
            ),
            if (_downloading) ...[
              LinearProgressIndicator(value: _total > 0 ? _received / _total : null),
              Text(
                '${memoryMb(_received).toStringAsFixed(1)} / ${_total > 0 ? memoryMb(_total).toStringAsFixed(1) : '?'} MiB',
              ),
            ],
            _heading('Decode settings'),
            DropdownButtonFormField<String>(
              initialValue: _language,
              decoration: const InputDecoration(labelText: 'Language', border: OutlineInputBorder()),
              items: const [
                DropdownMenuItem(value: 'ar', child: Text('Arabic · العربية (ar)')),
                DropdownMenuItem(value: 'en', child: Text('English (en)')),
                DropdownMenuItem(value: 'auto', child: Text('Auto detect')),
              ],
              onChanged: _idle ? (value) => setState(() => _language = value!) : null,
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<int>(
              initialValue: _threads,
              decoration: const InputDecoration(labelText: 'CPU threads', border: OutlineInputBorder()),
              items: [2, 4, 6].map((n) => DropdownMenuItem(value: n, child: Text('$n threads'))).toList(),
              onChanged: _idle ? (value) => setState(() => _threads = value!) : null,
            ),
            _heading('Record once, compare models'),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                FilledButton(onPressed: _idle ? () => _startRecording(false) : null, child: const Text('Record WAV')),
                FilledButton(
                  onPressed: _idle ? () => _startRecording(true) : null,
                  child: const Text('Record app AAC'),
                ),
                if (_recording)
                  FilledButton(onPressed: !_busy ? _stopRecording : null, child: const Text('Stop recording')),
              ],
            ),
            if (_recording || _liveRun != null)
              Text('Elapsed: ${(_clock.elapsedMilliseconds / 1000).toStringAsFixed(1)} s'),
            if (_clips.isEmpty) const Text('No recordings yet. The last 10 are kept across launches.'),
            for (final clip in _clips)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(identical(_clip, clip) ? Icons.radio_button_checked : Icons.radio_button_unchecked),
                title: Text(
                  '${clip.seconds.toStringAsFixed(1)} s · ${clip.format.startsWith('wav') ? 'WAV' : 'AAC / M4A'}',
                ),
                subtitle: Text(clip.name, style: const TextStyle(fontSize: 14)),
                onTap: _idle ? () => setState(() => _clip = clip) : null,
              ),
            FilledButton(
              onPressed: _idle && _clip != null ? _transcribe : null,
              child: const Text('Transcribe selected recording'),
            ),
            _heading('Live session'),
            const Text('Live uses 16 kHz PCM16. Stop waits for queued work. Its RTF includes time spent listening.'),
            FilledButton(
              onPressed: _idle ? _startLive : (_liveRun != null && !_busy ? _stopLive : null),
              child: Text(_liveRun != null ? 'Stop live + finalize' : 'Start live microphone'),
            ),
            if (_liveRun != null && !_busy) const LinearProgressIndicator(),
            _heading('Transcript / live partial'),
            SelectableText(
              _text.isEmpty ? 'No text yet / لم يظهر نص بعد' : _text,
              textDirection: containsArabic(_text) ? TextDirection.rtl : TextDirection.ltr,
              style: const TextStyle(fontSize: 24, height: 1.6),
            ),
            _heading('Run history · newest first'),
            const Text(
              'wall_ms includes FFmpeg, model load and inference. conversion_ms is FFmpeg session duration. '
              'RSS is whole-process memory; max RSS is the lifetime peak. Raw JSON is saved beside recordings.',
            ),
            for (final line in _history) ...[
              const Divider(height: 32),
              Text(runSummary(line), style: const TextStyle(fontSize: 18)),
              SelectableText(line, style: const TextStyle(fontSize: 14)),
            ],
          ],
        ),
      ),
    );
  }
}

String runSummary(String line) {
  final run = jsonDecode(line.substring('FIKRA_WHISPER '.length)) as Map<String, dynamic>;
  String n(String key) => run[key] is num ? (run[key] as num).toStringAsFixed(2) : 'unavailable';
  return '${run['model']} · ${run['language']} · ${run['threads']} threads\n'
      'Audio ${n('audio_seconds')} s · wall ${run['wall_ms']} ms · RTF ${n('rtf')}\n'
      'FFmpeg ${n('conversion_ms')} ms · transcription + load ≈ ${n('transcription_wall_ms_estimate')} ms\n'
      'Model startup ${n('model_load_ms')} ms\n'
      'RSS ${n('rss_before_mb')} → ${n('rss_after_mb')} MiB · peak ${n('rss_max_mb')} MiB';
}
