import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../data/local/database.dart';

typedef MeStats = ({int notes, int links, int activeDays});

/// One aggregation over shared project streams, never a query per tile.
final meStatsProvider = Provider.autoDispose<AsyncValue<MeStats>>((ref) {
  final now = ref.watch(appClockProvider)().toLocal();
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  final refresh = Timer(tomorrow.difference(now), ref.invalidateSelf);
  ref.onDispose(refresh.cancel);
  final notes = ref.watch(selectedNotesProvider);
  final links = ref.watch(selectedLinksProvider);
  if (notes.hasError) return AsyncError(notes.error!, notes.stackTrace!);
  if (links.hasError) return AsyncError(links.error!, links.stackTrace!);
  if (!notes.hasValue || !links.hasValue) return const AsyncLoading();
  final ids = notes.requireValue.map((n) => n.id).toSet();
  final pairs = <(String, String)>{};
  for (final link in links.requireValue) {
    if (link.dismissed ||
        link.origin != LinkOrigin.user ||
        link.sourceId == link.targetId ||
        !ids.contains(link.sourceId) ||
        !ids.contains(link.targetId)) {
      continue;
    }
    final a = link.sourceId, b = link.targetId;
    pairs.add(a.compareTo(b) < 0 ? (a, b) : (b, a));
  }
  final start = DateTime(now.year, now.month, now.day - 6);
  final days = <DateTime>{};
  for (final note in notes.requireValue) {
    final date = note.createdAt.toLocal();
    if (!date.isBefore(start) && date.isBefore(tomorrow)) days.add(DateTime(date.year, date.month, date.day));
  }
  return AsyncData((notes: ids.length, links: pairs.length, activeDays: days.length));
});
