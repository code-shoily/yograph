/// Result of a pathfinding query.
///
/// [nodes] is ordered from source to target.  [weight] is the total
/// accumulated cost along the path as computed by the algorithm's
/// [WeightAlgebra].  For the default [DoubleAlgebra] this is equivalent to
/// the sum of [edgeWeight] values; custom algebras may interpret it
/// differently.
///
/// If source == target, [nodes] contains a single element and [weight] is
/// `algebra.zero`.
class Path<E> {
  final List<int> nodes;
  final E weight;

  const Path(this.nodes, this.weight);

  /// The first node in the path (the source).
  int get source => nodes.first;

  /// The last node in the path (the target).
  int get target => nodes.last;

  /// Number of edges traversed.
  int get length => nodes.length - 1;

  /// `true` when [length] == 0 (source and target are the same node).
  bool get isTrivial => length == 0;

  @override
  String toString() => 'Path(${nodes.join(' -> ')}, weight: $weight)';
}
