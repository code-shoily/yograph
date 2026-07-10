import '../disjoint_set.dart';
import '../internal/priority_queue.dart';
import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';
import 'mst_edge.dart';
import 'mst_result.dart';

/// Minimum Spanning Tree (MST) algorithms.
///
/// MST algorithms find a subset of edges that connects all nodes in an
/// **undirected** weighted graph with the minimum possible total edge weight.
///
/// Passing a directed graph to [kruskal] or [prim] throws [ArgumentError].
///
/// ```dart
/// final graph = SimpleGraph<String, int>.undirected()
///   ..addEdge(0, 1, data: 2)
///   ..addEdge(1, 2, data: 3)
///   ..addEdge(0, 2, data: 1);
///
/// final result = MST.kruskal(graph);
/// print(result.totalWeight); // 3
/// ```
class MST {
  MST._();

  // =============================================================================
  // Kruskal's Algorithm
  // =============================================================================

  /// Finds the Minimum Spanning Tree using Kruskal's algorithm.
  ///
  /// **Time Complexity:** O(E log E)
  ///
  /// Throws [ArgumentError] if [graph] is directed.
  static MstResult<E> kruskal<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    _requireUndirected(graph);
    final alg = _resolveAlgebra<E>(algebra);

    final edges = _extractUniqueEdges<N, E>(graph, alg);
    edges.sort((a, b) => alg.compare(a.weight, b.weight));

    final dsu = DisjointSet<int>();
    final mstEdges = <MstEdge<E>>[];

    for (final edge in edges) {
      if (!dsu.connected(edge.from, edge.to)) {
        dsu.union(edge.from, edge.to);
        mstEdges.add(edge);
      }
    }

    return MstResult.fromEdges(mstEdges, 'kruskal', graph.nodeCount, alg);
  }

  /// Finds the Maximum Spanning Tree using Kruskal's algorithm.
  ///
  /// Same as [kruskal] but selects the heaviest edges first.
  ///
  /// **Time Complexity:** O(E log E)
  static MstResult<E> kruskalMax<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    _requireUndirected(graph);
    final alg = _resolveAlgebra<E>(algebra);

    final edges = _extractUniqueEdges<N, E>(graph, alg);
    edges.sort((a, b) => alg.compare(b.weight, a.weight));

    final dsu = DisjointSet<int>();
    final mstEdges = <MstEdge<E>>[];

    for (final edge in edges) {
      if (!dsu.connected(edge.from, edge.to)) {
        dsu.union(edge.from, edge.to);
        mstEdges.add(edge);
      }
    }

    return MstResult.fromEdges(mstEdges, 'kruskal_max', graph.nodeCount, alg);
  }

  // =============================================================================
  // Prim's Algorithm
  // =============================================================================

  /// Finds the Minimum Spanning Tree using Prim's algorithm.
  ///
  /// Starts growing the tree from [from] if provided, otherwise from the
  /// first node in the graph.
  ///
  /// **Time Complexity:** O(E log V)
  ///
  /// Throws [ArgumentError] if [graph] is directed.
  static MstResult<E> prim<N, E>(
    WeightedWalkable<N, E> graph, {
    int? from,
    WeightAlgebra<E>? algebra,
  }) {
    _requireUndirected(graph);
    final alg = _resolveAlgebra<E>(algebra);

    if (graph.isEmpty) {
      return MstResult.fromEdges([], 'prim', 0, alg);
    }

    final start = from ?? graph.nodeIds.first;
    if (!graph.hasNode(start)) {
      return MstResult.fromEdges([], 'prim', graph.nodeCount, alg);
    }

    final pq = PriorityQueue<MstEdge<E>>(
      (a, b) => alg.compare(a.weight, b.weight),
    );

    final visited = <int>{start};
    final mstEdges = <MstEdge<E>>[];

    // Seed the PQ with edges from the start node.
    for (final to in graph.successors(start)) {
      final w = edgeValue(graph, start, to, alg);
      pq.push(MstEdge(start, to, w));
    }

    while (pq.isNotEmpty) {
      final edge = pq.pop()!;

      if (visited.contains(edge.to)) continue;

      visited.add(edge.to);
      mstEdges.add(edge);

      for (final next in graph.successors(edge.to)) {
        if (!visited.contains(next)) {
          final w = edgeValue(graph, edge.to, next, alg);
          pq.push(MstEdge(edge.to, next, w));
        }
      }
    }

    return MstResult.fromEdges(mstEdges, 'prim', graph.nodeCount, alg);
  }

  /// Finds the Maximum Spanning Tree using Prim's algorithm.
  ///
  /// Same as [prim] but selects the heaviest edges first.
  ///
  /// **Time Complexity:** O(E log V)
  static MstResult<E> primMax<N, E>(
    WeightedWalkable<N, E> graph, {
    int? from,
    WeightAlgebra<E>? algebra,
  }) {
    _requireUndirected(graph);
    final alg = _resolveAlgebra<E>(algebra);

    if (graph.isEmpty) {
      return MstResult.fromEdges([], 'prim_max', 0, alg);
    }

    final start = from ?? graph.nodeIds.first;
    if (!graph.hasNode(start)) {
      return MstResult.fromEdges([], 'prim_max', graph.nodeCount, alg);
    }

    final pq = PriorityQueue<MstEdge<E>>(
      (a, b) => alg.compare(b.weight, a.weight),
    );

    final visited = <int>{start};
    final mstEdges = <MstEdge<E>>[];

    for (final to in graph.successors(start)) {
      final w = edgeValue(graph, start, to, alg);
      pq.push(MstEdge(start, to, w));
    }

    while (pq.isNotEmpty) {
      final edge = pq.pop()!;

      if (visited.contains(edge.to)) continue;

      visited.add(edge.to);
      mstEdges.add(edge);

      for (final next in graph.successors(edge.to)) {
        if (!visited.contains(next)) {
          final w = edgeValue(graph, edge.to, next, alg);
          pq.push(MstEdge(edge.to, next, w));
        }
      }
    }

    return MstResult.fromEdges(mstEdges, 'prim_max', graph.nodeCount, alg);
  }

  // =============================================================================
  // Helpers
  // =============================================================================

  static void _requireUndirected(WeightedWalkable graph) {
    if (graph.kind == GraphKind.directed) {
      throw ArgumentError(
        'MST algorithms only work on undirected graphs. '
        'Use a directed MST algorithm (e.g. Edmonds\') for directed graphs.',
      );
    }
  }

  /// Extracts each undirected edge exactly once.
  static List<MstEdge<E>> _extractUniqueEdges<N, E>(
    WeightedWalkable<N, E> graph,
    WeightAlgebra<E> alg,
  ) {
    final edges = <MstEdge<E>>[];
    for (final from in graph.nodeIds) {
      for (final to in graph.successors(from)) {
        if (from < to) {
          final w = edgeValue(graph, from, to, alg);
          edges.add(MstEdge(from, to, w));
        }
      }
    }
    return edges;
  }
}

WeightAlgebra<E> _resolveAlgebra<E>(WeightAlgebra<E>? algebra) {
  if (algebra != null) return algebra;
  if (E == double || E == dynamic || E == Null || E.toString() == 'void') {
    return DoubleAlgebra.instance as WeightAlgebra<E>;
  }
  if (E == int) {
    return IntAlgebra.instance as WeightAlgebra<E>;
  }
  throw ArgumentError(
    'A WeightAlgebra<$E> must be supplied for non-double edge types.',
  );
}
