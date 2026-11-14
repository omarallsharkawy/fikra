import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'graph_layout.dart';

/// Session-only, per-project folds. The provider container owns the lifetime;
/// switching projects clears transient navigation but restores that project's folds.
final graphCollapsedGroupsProvider = Provider((ref) => <String, Set<String>>{});

/// The screen keeps latest-input acceptance separate from the worker's lifetime.
final graphLayoutWorkerProvider = Provider<Future<GraphLayout> Function(GraphInput)>(
  (ref) =>
      (input) => compute(GraphLayout.fromInput, input, debugLabel: 'links-layout'),
);
