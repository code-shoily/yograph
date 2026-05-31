/// An edge in a Minimum Spanning Tree result.
class MstEdge {
  final int from;
  final int to;
  final double weight;

  const MstEdge(this.from, this.to, this.weight);

  @override
  String toString() => 'MstEdge($from -> $to, weight: $weight)';
}
