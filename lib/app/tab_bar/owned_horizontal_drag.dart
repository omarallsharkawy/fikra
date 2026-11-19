import 'package:flutter/gestures.dart';

/// Only the first enabled pointer can own a horizontal slide.
class OwnedHorizontalDragRecognizer extends HorizontalDragGestureRecognizer {
  OwnedHorizontalDragRecognizer(this.ownsPointer);
  final bool Function(int pointer) ownsPointer;

  @override
  void addPointer(PointerDownEvent event) {
    if (ownsPointer(event.pointer)) super.addPointer(event);
  }
}
