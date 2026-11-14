import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Session-only, per-project folds. The provider container owns the lifetime;
/// switching projects clears transient navigation but restores that project's folds.
final graphCollapsedGroupsProvider = Provider((ref) => <String, Set<String>>{});
