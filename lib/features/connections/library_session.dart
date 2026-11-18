import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only, per-project choice. Every project's first visit opens Map.
final linksSegmentProvider = NotifierProvider<LinksSegment, Map<String, int>>(LinksSegment.new);

class LinksSegment extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};
  void select(String project, int segment) => state = {...state, project: segment};
}
