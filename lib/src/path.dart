/// Result of a pathfinding query.
///
/// [nodes] is ordered from source to target.  [weight] is the total cost
/// along the path (sum of [edgeWeight] values).  If source == target,
/// [nodes] contains a single element and [weight] is `0.0`.
class Path {
  final List<Object> nodes;
  final double weight;

  const Path(this.nodes, this.weight);

  /// The first node in the path (the source).
  Object get source => nodes.first;

  /// The last node in the path (the target).
  Object get target => nodes.last;

  /// Number of edges traversed.
  int get length => nodes.length - 1;

  /// `true` when [length] == 0 (source and target are the same node).
  bool get isTrivial => length == 0;

  @override
  String toString() => 'Path(${nodes.join(' -> ')}, weight: $weight)';
}
