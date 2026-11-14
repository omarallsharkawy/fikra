import 'database.dart';

/// Allocate inside the caller's transaction. Keep request order even when an
/// older note is queued after a newer one, or the process dies mid-job.
Future<int> nextTranscriptionOrder(FikraDatabase db) async =>
    (await db
            .customSelect('SELECT COALESCE(MAX(transcription_order), 0) + 1 AS next_order FROM note_attachments')
            .getSingle())
        .read<int>('next_order');
