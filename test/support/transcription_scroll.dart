import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Only the page's outer scroll view, excluding SelectableText internals and
/// nested viewports. The keyed target can safely be absent in a lazy list.
Finder transcriptionScrollable(Type screen) => find.byElementPredicate((element) {
  if (element.widget is! Scrollable) return false;
  var owns = false;
  var nested = false;
  element.visitAncestorElements((parent) {
    if (parent.widget.runtimeType == screen) {
      owns = true;
      return false;
    }
    if (parent.widget is Scrollable || parent.widget is EditableText) nested = true;
    return true;
  });
  return owns && !nested;
});

Future<void> revealTranscription(WidgetTester tester, Type screen, Key key) async {
  final scrollable = transcriptionScrollable(screen);
  tester.state<ScrollableState>(scrollable).position.jumpTo(0);
  await tester.pump();
  final target = find.byKey(key);
  await tester.scrollUntilVisible(target, 160, scrollable: scrollable);
  await Scrollable.ensureVisible(tester.element(target), alignment: 0.5);
  await tester.pump(const Duration(milliseconds: 600));
}
