/// Network health and structural quality metrics.
///
/// These metrics measure the overall "health" and structural properties
/// of your graph, including size, compactness, and connectivity patterns.
library;

import 'dart:math' as math;

import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import '../pathfinding/a_star.dart';
import '../pathfinding/dijkstra.dart';
import '../simple_graph.dart';

/// Static container for all health metrics.
///
/// Every method is a pure function: it reads from the graph but never
/// mutates it.
abstract final class Health {
  const Health._();

  // ========================================================================
  // Distance Metrics
  // ========================================================================

  /// The diameter is the maximum eccentricity (longest shortest path).
  ///
  /// Returns `null` if the graph is disconnected or empty.
  ///
  /// Custom edge-weight semantics may be supplied via [algebra].
  ///
  /// Time complexity: **O(V × (E log V))**.
  static double? diameter<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return null;

    final eccentricities = <E>[];

    for (final node in nodes) {
      final ecc = _eccentricityE(graph, node, algebra: alg);
      if (ecc == null) return null;
      eccentricities.add(ecc);
    }

    final maxEcc = eccentricities.reduce((max, ecc) {
      return alg.compare(ecc, max) > 0 ? ecc : max;
    });
    return alg.toDouble(maxEcc);
  }

  /// The radius is the minimum eccentricity.
  ///
  /// Returns `null` if the graph is disconnected or empty.
  ///
  /// Time complexity: **O(V × (E log V))**.
  static double? radius<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return null;

    final eccentricities = <E>[];

    for (final node in nodes) {
      final ecc = _eccentricityE(graph, node, algebra: alg);
      if (ecc == null) return null;
      eccentricities.add(ecc);
    }

    final minEcc = eccentricities.reduce((min, ecc) {
      return alg.compare(ecc, min) < 0 ? ecc : min;
    });
    return alg.toDouble(minEcc);
  }

  /// Eccentricity is the maximum distance from a node to all other nodes.
  ///
  /// Returns `null` if the node cannot reach all other nodes.
  /// For a single-node graph returns the zero weight.
  ///
  /// Time complexity: **O((V + E) log V)**.
  static double? eccentricity<N, E>(
    WeightedWalkable<N, E> graph,
    int node, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final ecc = _eccentricityE(graph, node, algebra: alg);
    if (ecc == null) return null;
    return alg.toDouble(ecc);
  }

  static E? _eccentricityE<N, E>(
    WeightedWalkable<N, E> graph,
    int node, {
    required WeightAlgebra<E> algebra,
  }) {
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) return algebra.zero;

    final distances = Dijkstra.singleSourceDistances(
      graph,
      node,
      algebra: algebra,
    );

    if (distances.length < n) return null;

    return distances.values.reduce((max, dist) {
      return algebra.compare(dist, max) > 0 ? dist : max;
    });
  }

  // ========================================================================
  // Structural Metrics
  // ========================================================================

  /// Assortativity coefficient measures degree correlation (homophily).
  ///
  /// Returns a value in `[-1, 1]` where:
  /// * **Positive** — high-degree nodes connect to other high-degree nodes
  /// * **Negative** — high-degree nodes connect to low-degree nodes
  /// * **Zero** — random mixing or regular graph
  ///
  /// For directed graphs the out-degree is used.
  ///
  /// Time complexity: **O(V + E)**.
  static double assortativity<N, E>(Bidirectional<N, E> graph) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return 0.0;

    final degrees = <int, int>{};
    for (final node in nodes) {
      degrees[node] = graph.successors(node).length;
    }

    var sumJk = 0.0;
    var sumJ = 0.0;
    var sumK = 0.0;
    var sumJ2 = 0.0;
    var sumK2 = 0.0;
    var m = 0;

    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        final j = degrees[u]!.toDouble();
        final k = degrees[v]!.toDouble();
        sumJk += j * k;
        sumJ += j;
        sumK += k;
        sumJ2 += j * j;
        sumK2 += k * k;
        m++;
      }
    }

    if (m == 0) return 0.0;

    final meanJ = sumJ / m;
    final meanK = sumK / m;
    final numerator = sumJk / m - meanJ * meanK;

    final denomJ = sumJ2 / m - meanJ * meanJ;
    final denomK = sumK2 / m - meanK * meanK;
    final denominator = math.sqrt(denomJ * denomK);

    if (denominator <= 0) return 0.0;
    return numerator / denominator;
  }

  // ========================================================================
  // Path Metrics
  // ========================================================================

  /// Average shortest path length across all node pairs.
  ///
  /// Returns `null` if the graph is disconnected, empty, or has a single
  /// node.
  ///
  /// Time complexity: **O(V × (E log V))**.
  static double? averagePathLength<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) return null;

    var total = 0.0;
    for (final source in nodes) {
      final distances = Dijkstra.singleSourceDistances(
        graph,
        source,
        algebra: alg,
      );
      if (distances.length < n) return null;

      for (final entry in distances.entries) {
        total += alg.toDouble(entry.value);
      }
    }

    final zeroDistances = n * alg.toDouble(alg.zero);
    final numPairs = n * (n - 1);
    return (total - zeroDistances) / numPairs;
  }

  // ========================================================================
  // Efficiency Metrics
  // ========================================================================

  /// Efficiency between two nodes.
  ///
  /// The efficiency is the inverse of the shortest path distance.
  /// Returns `0.0` if no path exists or if [from] == [to].
  ///
  /// Time complexity: **O((V + E) log V)**.
  static double efficiency<N, E>(
    WeightedWalkable<N, E> graph,
    int from,
    int to, {
    WeightAlgebra<E>? algebra,
  }) {
    if (from == to) return 0.0;
    final alg = resolveAlgebra<E>(algebra);

    final distances = Dijkstra.singleSourceDistances(graph, from, algebra: alg);

    final dist = distances[to];
    if (dist == null) return 0.0;
    final distD = alg.toDouble(dist);
    if (distD == 0.0) return 0.0;
    return 1.0 / distD;
  }

  /// Global efficiency of the graph.
  ///
  /// The average efficiency over all ordered pairs of distinct nodes.
  /// Unlike [averagePathLength], this is well-defined for disconnected
  /// graphs: unreachable pairs simply contribute `0.0`.
  ///
  /// Time complexity: **O(V × (E log V))**.
  static double globalEfficiency<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    final n = nodes.length;
    if (n <= 1) return 0.0;

    var total = 0.0;
    for (final source in nodes) {
      final distances = Dijkstra.singleSourceDistances(
        graph,
        source,
        algebra: alg,
      );

      for (final target in nodes) {
        if (target == source) continue;
        final dist = distances[target];
        if (dist != null) {
          final distD = alg.toDouble(dist);
          if (distD != 0.0) {
            total += 1.0 / distD;
          }
        }
      }
    }

    return total / (n * (n - 1));
  }

  /// Local efficiency of a single node.
  ///
  /// Computes the [globalEfficiency] of the subgraph induced by the
  /// node's neighbors. For directed graphs the neighbourhood includes
  /// both successors and predecessors.
  ///
  /// Returns `0.0` if the node has fewer than 2 neighbors.
  ///
  /// Time complexity: **O(d² × (d + E') log d)** where *d* is the node
  /// degree and *E'* is the number of edges in the neighbourhood subgraph.
  static double localEfficiency<N, E>(
    Bidirectional<N, E> graph,
    int node, {
    WeightAlgebra<E>? algebra,
  }) {
    final neighbors = _neighborIds(graph, node);
    if (neighbors.length <= 1) return 0.0;

    final subgraph = graph.kind == GraphKind.undirected
        ? SimpleGraph<N, E>.undirected()
        : SimpleGraph<N, E>.directed();

    for (final u in neighbors) {
      subgraph.addNode(u);
      for (final v in neighbors) {
        if (graph.hasEdge(u, v)) {
          final data = graph.edgeData(u, v);
          subgraph.addEdge(u, v, data: data);
        }
      }
    }

    return globalEfficiency(subgraph, algebra: algebra);
  }

  /// Average local efficiency over all nodes.
  ///
  /// This is the mean of [localEfficiency] for every node in the graph.
  ///
  /// Time complexity: **O(V × d² × (d + E') log d)**.
  static double averageLocalEfficiency<N, E>(
    Bidirectional<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final nodes = graph.nodeIds.toList();
    if (nodes.isEmpty) return 0.0;

    var total = 0.0;
    for (final node in nodes) {
      total += localEfficiency(graph, node, algebra: algebra);
    }

    return total / nodes.length;
  }

  // ========================================================================
  // Helpers
  // ========================================================================

  static Set<int> _neighborIds<N, E>(Bidirectional<N, E> graph, int node) {
    final neighbors = <int>{};
    for (final s in graph.successors(node)) {
      neighbors.add(s);
    }
    if (graph.kind == GraphKind.directed) {
      for (final p in graph.predecessors(node)) {
        neighbors.add(p);
      }
    }
    return neighbors;
  }
}
