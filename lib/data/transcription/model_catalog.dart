import 'service_config.dart';

enum TranscriptionMode { batch, live }

enum ModelStatus { recommended, other, legacy }

enum ArabicSuitability { multilingual, generative }

class CatalogModel {
  const CatalogModel(
    this.type,
    this.id,
    this.label, {
    this.status = ModelStatus.other,
    this.mode = TranscriptionMode.batch,
    this.shutdown,
    this.supported = true,
    this.arabic = ArabicSuitability.multilingual,
    this.groqOnly = false,
  });
  final TranscriptionServiceType type;
  final String id, label;
  final TranscriptionMode mode;
  final ModelStatus status;
  final String? shutdown;
  final bool supported, groqOnly;
  final ArabicSuitability arabic;
}

// Verified 2026-11-16 against official docs. Availability is account-specific;
// language support does not establish Egyptian accuracy (owner must test it).
// https://developers.openai.com/api/docs/guides/transcription
// https://developers.openai.com/api/docs/deprecations
// https://console.groq.com/docs/speech-to-text
// https://aistudio.google.com/docs/models (all four generateContent models)
// https://aistudio.google.com/docs/models/gemini-3.5-transcribe (/interactions only)
// https://elevenlabs.io/docs/overview/models/
// https://elevenlabs.io/docs/api-reference/speech-to-text/convert
// https://help.aliyun.com/en/model-studio/qwen-asr-api-reference
// Qwen native qwen-audio-3.1 and live adapters are intentionally not offered.
const transcriptionCatalog = <CatalogModel>[
  CatalogModel(TranscriptionServiceType.openAi, 'gpt-transcribe', 'GPT Transcribe', status: ModelStatus.recommended),
  CatalogModel(
    TranscriptionServiceType.openAi,
    'whisper-1',
    'Whisper 1',
    status: ModelStatus.legacy,
    shutdown: '2027-02-26',
  ),
  CatalogModel(
    TranscriptionServiceType.openAi,
    'gpt-4o-transcribe',
    'GPT-4o Transcribe',
    status: ModelStatus.legacy,
    shutdown: '2027-02-26',
  ),
  CatalogModel(
    TranscriptionServiceType.openAi,
    'gpt-4o-mini-transcribe',
    'GPT-4o mini Transcribe',
    status: ModelStatus.legacy,
    shutdown: '2027-02-26',
  ),
  CatalogModel(
    TranscriptionServiceType.openAi,
    'gpt-4o-transcribe-diarize',
    'GPT-4o Transcribe Diarize',
    status: ModelStatus.legacy,
    shutdown: '2027-02-26',
  ),
  CatalogModel(
    TranscriptionServiceType.openAi,
    'whisper-large-v3-turbo',
    'Whisper large v3 turbo',
    status: ModelStatus.recommended,
    groqOnly: true,
  ),
  CatalogModel(TranscriptionServiceType.openAi, 'whisper-large-v3', 'Whisper large v3', groqOnly: true),
  CatalogModel(
    TranscriptionServiceType.gemini,
    'gemini-3.5-flash-lite',
    'Gemini 3.5 Flash-Lite',
    status: ModelStatus.recommended,
    arabic: ArabicSuitability.generative,
  ),
  CatalogModel(
    TranscriptionServiceType.gemini,
    'gemini-3.8-flash',
    'Gemini 3.8 Flash',
    arabic: ArabicSuitability.generative,
  ),
  CatalogModel(
    TranscriptionServiceType.gemini,
    'gemini-3.6-flash',
    'Gemini 3.6 Flash',
    arabic: ArabicSuitability.generative,
  ),
  CatalogModel(
    TranscriptionServiceType.gemini,
    'gemini-3.1-flash-lite',
    'Gemini 3.1 Flash-Lite',
    arabic: ArabicSuitability.generative,
  ),
  CatalogModel(TranscriptionServiceType.gemini, 'gemini-3.5-transcribe', 'Gemini 3.5 Transcribe', supported: false),
  CatalogModel(TranscriptionServiceType.elevenLabs, 'scribe_v3', 'Scribe v3', status: ModelStatus.recommended),
  CatalogModel(TranscriptionServiceType.elevenLabs, 'scribe_v2', 'Scribe v2'),
  // v1 remains a legacy option; no official shutdown date was found.
  CatalogModel(TranscriptionServiceType.elevenLabs, 'scribe_v1', 'Scribe v1', status: ModelStatus.legacy),
  CatalogModel(TranscriptionServiceType.qwen, 'qwen3-asr-flash', 'Qwen3 ASR Flash', status: ModelStatus.recommended),
];

bool isGroqUrl(String url) => Uri.tryParse(url)?.host.toLowerCase() == 'api.groq.com';
List<CatalogModel> catalogFor(TranscriptionServiceType type, String url) => [
  for (final m in transcriptionCatalog)
    if (m.type == type &&
        m.mode == TranscriptionMode.batch &&
        (type != TranscriptionServiceType.openAi || m.groqOnly == isGroqUrl(url)))
      m,
];
String catalogDefault(TranscriptionServiceType type, {String url = ''}) =>
    catalogFor(type, url).firstWhere((m) => m.status == ModelStatus.recommended && m.supported).id;
String? catalogLiveDefault(TranscriptionServiceType type) => null; // Reserved; no live engine in this phase.

CatalogModel? transcriptionCatalogMatch(TranscriptionServiceType type, String id) =>
    transcriptionCatalog.where((m) => m.type == type && m.id == id).firstOrNull;
