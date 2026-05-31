import '../simple_graph.dart';

/// Represents the result of a maximum flow computation.
class MaxFlowResult<N> {
  /// The maximum flow value from source to sink.
  final double maxFlow;

  /// The residual graph after flow computation.
  final SimpleGraph<N, double> residualGraph;

  /// The source node ID.
  final int source;

  /// The sink node ID.
  final int sink;

  /// The algorithm used to calculate the flow.
  final String algorithm;

  MaxFlowResult({
    required this.maxFlow,
    required this.residualGraph,
    required this.source,
    required this.sink,
    required this.algorithm,
  });
}
