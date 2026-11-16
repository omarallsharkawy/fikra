import 'dart:convert';

import '../processing/transcription_engine.dart';
import 'remote_request.dart';
import 'service_config.dart';

Uri serviceEndpoint(TranscriptionService service, String suffix) =>
    Uri.parse('${service.baseUrl.replaceAll(RegExp(r'/+$'), '')}/$suffix');

Future<RemoteRequest> buildTranscriptionRequest(
  TranscriptionService service,
  String key,
  AudioUpload audio,
  String language, {
  String boundary = 'fikra-audio-boundary',
}) async {
  service.validate();
  final hint = service.language ?? (language == 'auto' ? null : language);
  final bearer = {'Authorization': 'Bearer $key'};
  final multipart = {'Content-Type': 'multipart/form-data; boundary=$boundary'};
  switch (service.type) {
    case TranscriptionServiceType.openAi:
      // https://developers.openai.com/api/docs/guides/speech-to-text
      // https://developers.openai.com/api/reference/resources/audio/subresources/transcriptions/methods/create
      return RemoteRequest.multipart(
        serviceEndpoint(service, 'audio/transcriptions'),
        {...bearer, ...multipart},
        {
          'model': service.model,
          'response_format': 'json',
          (service.model == 'gpt-transcribe' ? 'languages[]' : 'language'): ?hint,
        },
        audio,
        boundary,
      );
    case TranscriptionServiceType.elevenLabs:
      // https://elevenlabs.io/docs/api-reference/speech-to-text/convert
      // https://elevenlabs.io/docs/overview/capabilities/speech-to-text
      return RemoteRequest.multipart(
        serviceEndpoint(service, 'speech-to-text'),
        {'xi-api-key': key, ...multipart},
        {
          'model_id': service.model,
          'language_code': ?hint,
          'tag_audio_events': 'false',
          'diarize': 'false',
          'timestamps_granularity': 'none',
        },
        audio,
        boundary,
      );
    case TranscriptionServiceType.gemini:
      // https://aistudio.google.com/api-reference/generate-content
      // https://aistudio.google.com/docs/audio (M4A: audio/m4a, AAC: audio/aac)
      return RemoteRequest.json(
        serviceEndpoint(service, 'models/${Uri.encodeComponent(service.model)}:generateContent'),
        {'x-goog-api-key': key, 'Content-Type': 'application/json'},
        {
          'contents': [
            {
              'role': 'user',
              'parts': [
                {
                  'text':
                      'Transcribe the speech verbatim in its original language. Return only the transcript, '
                      'without commentary, headings, translation or timestamps. Preserve mixed Arabic and English. '
                      'Return an empty string if there is no speech.${hint == null ? '' : ' Language hint: $hint.'}',
                },
                {
                  'inlineData': {
                    'mimeType': audio.mime == 'audio/mp4' ? 'audio/m4a' : audio.mime,
                    'data': base64Encode(await audio.readBytes()),
                  },
                },
              ],
            },
          ],
        },
      );
    case TranscriptionServiceType.qwen:
      // https://help.aliyun.com/en/model-studio/qwen-asr-api-reference
      // Compatible audio uses chat/completions, NOT audio/transcriptions.
      // Legacy international/mainland hosts still work; docs recommend the
      // user's workspace-specific Singapore/Beijing host (editable base URL).
      return RemoteRequest.json(
        serviceEndpoint(service, 'chat/completions'),
        {...bearer, 'Content-Type': 'application/json'},
        {
          'model': service.model,
          'stream': false,
          'messages': [
            {
              'role': 'user',
              'content': [
                {
                  'type': 'input_audio',
                  'input_audio': {'data': 'data:${audio.mime};base64,${base64Encode(await audio.readBytes())}'},
                },
              ],
            },
          ],
          'asr_options': {'enable_itn': false, 'language': ?hint},
        },
      );
  }
}

String parseTranscriptionResponse(TranscriptionServiceType type, String body) {
  try {
    final json = jsonDecode(body) as Map<String, dynamic>;
    final Object? text;
    switch (type) {
      case TranscriptionServiceType.openAi || TranscriptionServiceType.elevenLabs:
        text = json['text'];
      case TranscriptionServiceType.qwen:
        final choice = (json['choices'] as List).first as Map;
        if (choice['finish_reason'] != null && choice['finish_reason'] != 'stop') {
          throw const FormatException();
        }
        text = (choice['message'] as Map)['content'];
      case TranscriptionServiceType.gemini:
        final candidate = (json['candidates'] as List).first as Map;
        if (candidate['finishReason'] != null && candidate['finishReason'] != 'STOP') {
          throw const FormatException();
        }
        text = ((candidate['content'] as Map)['parts'] as List)
            .whereType<Map>()
            .where((part) => part['thought'] != true)
            .map((part) => part['text'] as String? ?? '')
            .join('');
    }
    if (text is! String) throw const FormatException();
    return text.trim();
  } catch (_) {
    // Never include provider JSON: it can echo the key, prompt or recording.
    throw const TranscriptionFailure(TranscriptionFailureReason.unexpectedResponse);
  }
}

TranscriptionFailureReason responseFailure(RemoteResponse response) => switch (response.status) {
  401 || 403 => TranscriptionFailureReason.keyRejected,
  429 => TranscriptionFailureReason.rateLimited,
  413 => TranscriptionFailureReason.tooLarge,
  >= 500 => TranscriptionFailureReason.serviceError,
  400 || 422
      when RegExp(
        r'(too.{0,20}(large|long)|maximum.{0,30}(duration|size)|duration.{0,45}(limit|exceed|within|minutes|seconds)|audio.{0,20}length.{0,25}(exceed|limit)|size_limit|audio_too_long)',
        caseSensitive: false,
      ).hasMatch(response.body) =>
    TranscriptionFailureReason.tooLarge,
  _ => TranscriptionFailureReason.unexpectedResponse,
};

bool rejectedAudioFormat(RemoteResponse response) =>
    response.status == 415 ||
    (response.status == 400 &&
        RegExp(
          r'((unsupported|unrecogni[sz]ed).{0,35}(audio|format|mime)|invalid.{0,15}(audio format|file format|mime))',
          caseSensitive: false,
        ).hasMatch(response.body));
