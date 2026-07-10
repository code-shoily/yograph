import '../model/weight_algebra.dart';
import 'mst_edge.dart';

/// Result of a Minimum Spanning Tree computation.
class MstResult<E> {
  final List<MstEdge<E>> edges;
  final E totalWeight;
  final int nodeCount;
  final int edgeCount;
  final String algorithm;

  MstResult._({
    required this.edges,
    required this.totalWeight,
    required this.nodeCount,
    required this.algorithm,
  }) : edgeCount = edges.length;

  factory MstResult.fromEdges(
    List<MstEdge<E>> edges,
    String algorithm,
    int nodeCount,
    WeightAlgebra<E> algebra,
  ) {
    final total = edges.fold(
      algebra.zero,
      (sum, e) => algebra.add(sum, e.weight),
    );
    return MstResult._(
      edges: edges,
      totalWeight: total,
      nodeCount: nodeCount,
      algorithm: algorithm,
    );
  }
}
