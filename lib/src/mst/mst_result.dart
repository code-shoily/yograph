import 'mst_edge.dart';

/// Result of a Minimum Spanning Tree computation.
class MstResult {
  final List<MstEdge> edges;
  final double totalWeight;
  final int nodeCount;
  final int edgeCount;
  final String algorithm;

  MstResult._({
    required this.edges,
    required this.nodeCount,
    required this.algorithm,
  })  : totalWeight = edges.fold(0.0, (sum, e) => sum + e.weight),
        edgeCount = edges.length;

  factory MstResult.fromEdges(
    List<MstEdge> edges,
    String algorithm,
    int nodeCount,
  ) {
    return MstResult._(
      edges: edges,
      nodeCount: nodeCount,
      algorithm: algorithm,
    );
  }
}
