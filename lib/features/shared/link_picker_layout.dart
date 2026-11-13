part of 'link_picker.dart';

/// Lays out the picker form as [top, list, bottom]: the controls take their
/// natural height, and the list fills what is left of [height], but never less
/// than [minListHeight]. The result is taller than [height] only then, so the
/// enclosing scroll view scrolls only when the controls can't fit.
class _PickerLayout extends MultiChildRenderObjectWidget {
  const _PickerLayout({required this.height, required this.minListHeight, required super.children})
    : assert(children.length == 3);
  final double height;
  final double minListHeight;

  @override
  RenderObject createRenderObject(BuildContext context) => _RenderPickerLayout(height, minListHeight);

  @override
  void updateRenderObject(BuildContext context, _RenderPickerLayout renderObject) => renderObject
    ..height = height
    ..minListHeight = minListHeight;
}

class _PickerLayoutData extends ContainerBoxParentData<RenderBox> {}

class _RenderPickerLayout extends RenderBox
    with
        ContainerRenderObjectMixin<RenderBox, _PickerLayoutData>,
        RenderBoxContainerDefaultsMixin<RenderBox, _PickerLayoutData> {
  _RenderPickerLayout(this._height, this._minListHeight);

  double _height;
  set height(double value) {
    if (value == _height) return;
    _height = value;
    markNeedsLayout();
  }

  double _minListHeight;
  set minListHeight(double value) {
    if (value == _minListHeight) return;
    _minListHeight = value;
    markNeedsLayout();
  }

  @override
  void setupParentData(RenderBox child) {
    if (child.parentData is! _PickerLayoutData) child.parentData = _PickerLayoutData();
  }

  @override
  void performLayout() {
    final top = firstChild!;
    final list = childAfter(top)!;
    final bottom = childAfter(list)!;
    final width = constraints.maxWidth;
    final natural = BoxConstraints.tightFor(width: width);
    top.layout(natural, parentUsesSize: true);
    bottom.layout(natural, parentUsesSize: true);
    final listHeight = math.max(_minListHeight, _height - top.size.height - bottom.size.height);
    list.layout(BoxConstraints.tightFor(width: width, height: listHeight));
    (top.parentData! as _PickerLayoutData).offset = Offset.zero;
    (list.parentData! as _PickerLayoutData).offset = Offset(0, top.size.height);
    (bottom.parentData! as _PickerLayoutData).offset = Offset(0, top.size.height + listHeight);
    size = constraints.constrain(Size(width, top.size.height + listHeight + bottom.size.height));
  }

  @override
  void paint(PaintingContext context, Offset offset) => defaultPaint(context, offset);

  @override
  bool hitTestChildren(BoxHitTestResult result, {required Offset position}) =>
      defaultHitTestChildren(result, position: position);
}
