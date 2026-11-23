part of 'container_transform.dart';

/// A card's paint-only fade during a container transform. Keeps its layout,
/// widget state and text scale unchanged; [CardOrigin.fromContext] captures it.
class ContainerTransformSource extends SingleChildRenderObjectWidget {
  const ContainerTransformSource({super.key, required super.child});

  @override
  RenderOpacity createRenderObject(BuildContext context) => _CardSource();
}

class _CardSource extends RenderOpacity {
  _CardSource() : super(opacity: 1);
}
