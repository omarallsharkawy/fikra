/// Caps a label at 80 UTF-16 code units without splitting a surrogate pair.
String capLinkLabel(String label) {
  if (label.length <= 80) return label;
  var end = 80;
  final before = label.codeUnitAt(end - 1);
  final after = label.codeUnitAt(end);
  if (before >= 0xd800 && before <= 0xdbff && after >= 0xdc00 && after <= 0xdfff) {
    end--;
  }
  return label.substring(0, end);
}
