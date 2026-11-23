part of 'links_repository.dart';

/// One link made by [LinksRepository.linkNotesForUndo]: its row id, its
/// project, and the rows its pair had before (empty when it had none).
class LinkChange {
  const LinkChange({required this.linkId, required this.projectId, required this.before});
  final String linkId;
  final String projectId;
  final List<NoteLink> before;
}

sealed class PairCommandResult {
  const PairCommandResult();
}

class PairCommandStale extends PairCommandResult {
  const PairCommandStale();
}

/// What [LinksRepository.acceptPairForUndo] or
/// [LinksRepository.dismissPairForUndo] changed: the pair's rows right before
/// and right after, in [projectId], so [LinksRepository.undoPairChange] can put
/// the pair back exactly.
class PairChange extends PairCommandResult {
  const PairChange({
    required this.projectId,
    required this.a,
    required this.b,
    required this.before,
    required this.after,
  });
  final String projectId;
  final String a, b;
  final List<NoteLink> before;
  final List<NoteLink> after;
}
