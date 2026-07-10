/// An edge in a Minimum Spanning Tree result.
class MstEdge<E> {
  final int from;
  final int to;
  final E weight;

  const MstEdge(this.from, this.to, this.weight);

  @override
  String toString() => 'MstEdge($from -> $to, weight: $weight)';
}
