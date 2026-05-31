/// Metadata provided during [foldWalk] / [implicitFold] traversal.
///
/// [P] is the type of the parent node identifier. For materialised graphs
/// this is `int`; for implicit graphs it may be any type.
class WalkMetadata<P> {
  /// Distance from the start node (number of edges traversed).
  final int depth;

  /// The parent node that led to this node (`null` for the start node).
  final P? parent;

  const WalkMetadata({required this.depth, this.parent});
}
