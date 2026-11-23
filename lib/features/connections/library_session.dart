import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only, per-project choice. Every project's first visit opens Map.
final linksSegmentProvider = NotifierProvider<LinksSegment, Map<String, int>>(LinksSegment.new);

abstract final class LinksLibrarySegment {
  static const map = 0;
  static const browse = 1;
  static const suggestions = 2;

  static ValueKey<String> key(int segment) => ValueKey('links-segment-$segment');

  static ValueKey<String> listKey(String projectId, int segment) => ValueKey('links-list-$projectId-$segment');
}

class LinksSegment extends Notifier<Map<String, int>> {
  @override
  Map<String, int> build() => const {};
  void select(String project, int segment) => state = {...state, project: segment};
}
