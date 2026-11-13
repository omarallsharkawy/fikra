import 'package:characters/characters.dart';

/// Longest link reason, counted in user-perceived characters (grapheme
/// clusters): the same unit as the reason field's limit and its counter.
const linkLabelMaxLength = 80;

/// Caps a label at [linkLabelMaxLength] grapheme clusters, so an emoji (even a
/// joined sequence) is kept or dropped whole and never split.
String capLinkLabel(String label) {
  final characters = label.characters;
  if (characters.length <= linkLabelMaxLength) return label;
  return characters.take(linkLabelMaxLength).toString();
}
