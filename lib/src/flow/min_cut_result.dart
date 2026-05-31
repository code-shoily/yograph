/// Represents the result of a minimum cut computation.
class MinCutResult {
  /// Total weight of the minimum cut.
  final double cutValue;

  /// Set of node IDs on the source side of the cut partition.
  final Set<int> sourceSide;

  /// Set of node IDs on the sink side of the cut partition.
  final Set<int> sinkSide;

  /// Name of the algorithm used.
  final String algorithm;

  MinCutResult({
    required this.cutValue,
    this.sourceSide = const {},
    this.sinkSide = const {},
    required this.algorithm,
  });

  /// Helper to get the size of the source side partition.
  int get sourceSideSize => sourceSide.length;

  /// Helper to get the size of the sink side partition.
  int get sinkSideSize => sinkSide.length;
}
