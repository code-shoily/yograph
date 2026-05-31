import '../disjoint_set.dart';
import '../internal/priority_queue.dart';
import '../model/graph_kind.dart';
import '../model/roles.dart';
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
  static MstResult kruskal<N, E>(WeightedWalkable<N, E> graph) {
    _requireUndirected(graph);

    final edges = _extractUniqueEdges(graph);
    edges.sort((a, b) => a.weight.compareTo(b.weight));

    final dsu = DisjointSet<int>();
    final mstEdges = <MstEdge>[];

    for (final edge in edges) {
      if (!dsu.connected(edge.from, edge.to)) {
        dsu.union(edge.from, edge.to);
        mstEdges.add(edge);
      }
    }

    return MstResult.fromEdges(mstEdges, 'kruskal', graph.nodeCount);
  }

  /// Finds the Maximum Spanning Tree using Kruskal's algorithm.
  ///
  /// Same as [kruskal] but selects the heaviest edges first.
  ///
  /// **Time Complexity:** O(E log E)
  static MstResult kruskalMax<N, E>(WeightedWalkable<N, E> graph) {
    _requireUndirected(graph);

    final edges = _extractUniqueEdges(graph);
    edges.sort((a, b) => b.weight.compareTo(a.weight));

    final dsu = DisjointSet<int>();
    final mstEdges = <MstEdge>[];

    for (final edge in edges) {
      if (!dsu.connected(edge.from, edge.to)) {
        dsu.union(edge.from, edge.to);
        mstEdges.add(edge);
      }
    }

    return MstResult.fromEdges(mstEdges, 'kruskal_max', graph.nodeCount);
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
  static MstResult prim<N, E>(
    WeightedWalkable<N, E> graph, {
    int? from,
  }) {
    _requireUndirected(graph);

    if (graph.isEmpty) {
      return MstResult.fromEdges([], 'prim', 0);
    }

    final start = from ?? graph.nodeIds.first;
    if (!graph.hasNode(start)) {
      return MstResult.fromEdges([], 'prim', graph.nodeCount);
    }

    final pq = PriorityQueue<MstEdge>(
      (a, b) => a.weight.compareTo(b.weight),
    );

    final visited = <int>{start};
    final mstEdges = <MstEdge>[];

    // Seed the PQ with edges from the start node.
    for (final to in graph.successors(start)) {
      pq.push(MstEdge(start, to, graph.edgeWeight(start, to)));
    }

    while (pq.isNotEmpty) {
      final edge = pq.pop()!;

      if (visited.contains(edge.to)) continue;

      visited.add(edge.to);
      mstEdges.add(edge);

      for (final next in graph.successors(edge.to)) {
        if (!visited.contains(next)) {
          pq.push(MstEdge(edge.to, next, graph.edgeWeight(edge.to, next)));
        }
      }
    }

    return MstResult.fromEdges(mstEdges, 'prim', graph.nodeCount);
  }

  /// Finds the Maximum Spanning Tree using Prim's algorithm.
  ///
  /// Same as [prim] but selects the heaviest edges first.
  ///
  /// **Time Complexity:** O(E log V)
  static MstResult primMax<N, E>(
    WeightedWalkable<N, E> graph, {
    int? from,
  }) {
    _requireUndirected(graph);

    if (graph.isEmpty) {
      return MstResult.fromEdges([], 'prim_max', 0);
    }

    final start = from ?? graph.nodeIds.first;
    if (!graph.hasNode(start)) {
      return MstResult.fromEdges([], 'prim_max', graph.nodeCount);
    }

    final pq = PriorityQueue<MstEdge>(
      (a, b) => b.weight.compareTo(a.weight),
    );

    final visited = <int>{start};
    final mstEdges = <MstEdge>[];

    for (final to in graph.successors(start)) {
      pq.push(MstEdge(start, to, graph.edgeWeight(start, to)));
    }

    while (pq.isNotEmpty) {
      final edge = pq.pop()!;

      if (visited.contains(edge.to)) continue;

      visited.add(edge.to);
      mstEdges.add(edge);

      for (final next in graph.successors(edge.to)) {
        if (!visited.contains(next)) {
          pq.push(MstEdge(edge.to, next, graph.edgeWeight(edge.to, next)));
        }
      }
    }

    return MstResult.fromEdges(mstEdges, 'prim_max', graph.nodeCount);
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
  static List<MstEdge> _extractUniqueEdges<N, E>(WeightedWalkable<N, E> graph) {
    final edges = <MstEdge>[];
    for (final from in graph.nodeIds) {
      for (final to in graph.successors(from)) {
        if (from < to) {
          edges.add(MstEdge(from, to, graph.edgeWeight(from, to)));
        }
      }
    }
    return edges;
  }
}
