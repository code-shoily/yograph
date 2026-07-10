import '../model/graph_kind.dart';
import '../model/roles.dart';
import '../model/weight_algebra.dart';

/// Result of a Johnson all-pairs shortest-path query.
class JohnsonResult {
  /// Distance matrix mapping `(from, to)` to shortest distance as `double`.
  /// `null` when a negative cycle was detected.
  final Map<(int, int), double>? distances;
  final bool hasNegativeCycle;

  const JohnsonResult._({this.distances, required this.hasNegativeCycle});

  factory JohnsonResult.success(Map<(int, int), double> distances) =>
      JohnsonResult._(distances: distances, hasNegativeCycle: false);

  factory JohnsonResult.negativeCycle() =>
      const JohnsonResult._(hasNegativeCycle: true);

  double? distance(int from, int to) => distances?[(from, to)];

  @override
  String toString() {
    if (hasNegativeCycle) return 'JohnsonResult(negativeCycle)';
    return 'JohnsonResult(${distances?.length} entries)';
  }
}

/// Reweighted view of a graph used during Johnson's algorithm.
///
/// Applies the Johnson reweighting formula using [WeightAlgebra]:
/// `w'(u, v) = w(u, v) + h(u) - h(v)`
class _ReweightedGraph<N, E> implements WeightedWalkable<N, E> {
  final WeightedWalkable<N, E> _graph;
  final Map<int, double> _potentials;
  final WeightAlgebra<E> _algebra;

  _ReweightedGraph(this._graph, this._potentials, this._algebra);

  @override
  GraphKind get kind => _graph.kind;

  @override
  bool get isEmpty => _graph.isEmpty;

  @override
  bool get isNotEmpty => _graph.isNotEmpty;

  @override
  int get nodeCount => _graph.nodeCount;

  @override
  int get edgeCount => _graph.edgeCount;

  @override
  Iterable<int> get nodeIds => _graph.nodeIds;

  @override
  Iterable<int> successors(int id) => _graph.successors(id);

  @override
  bool hasNode(int id) => _graph.hasNode(id);

  @override
  N? nodeData(int id) => _graph.nodeData(id);

  @override
  bool hasEdge(int from, int to) => _graph.hasEdge(from, to);

  @override
  E? edgeData(int from, int to) => _graph.edgeData(from, to);

  @override
  double edgeWeight(int from, int to) {
    final raw = edgeValue(_graph, from, to, _algebra);
    final hFrom = _potentials[from] ?? 0.0;
    final hTo = _potentials[to] ?? 0.0;
    // w'(u, v) = w(u, v) + h(u) - h(v)
    return _algebra.toDouble(raw) + hFrom - hTo;
  }
}

/// Johnson's algorithm for all-pairs shortest paths.
///
/// Works with any edge type [E] through [WeightAlgebra<E>].
/// The distance matrix is always returned as `double` (via [WeightAlgebra.toDouble])
/// since it is used for reweighting arithmetic internally.
///
/// ```dart
/// final result = Johnson.allPairs(graph);
/// if (!result.hasNegativeCycle) {
///   print(result.distance(0, 5));
/// }
/// ```
abstract final class Johnson {
  Johnson._();

  /// Computes shortest paths between all pairs of nodes.
  ///
  /// **Time complexity:** O(V × E log V)
  static JohnsonResult allPairs<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = _resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();

    if (nodes.isEmpty) {
      return JohnsonResult.success(const {});
    }

    final potentials = _computePotentials(graph, nodes, alg);
    if (potentials == null) {
      return JohnsonResult.negativeCycle();
    }

    final reweighted = _ReweightedGraph<N, E>(graph, potentials, alg);
    final distances = <(int, int), double>{};

    // Use internal double-based Dijkstra on the reweighted graph.
    // edgeWeight is overridden in _ReweightedGraph to return reweighted doubles.
    for (final source in nodes) {
      final reweightedDists = _dijkstraDoubles(reweighted, source);
      final hSource = potentials[source] ?? 0.0;

      for (final MapEntry(key: dest, value: reweightedDist)
          in reweightedDists.entries) {
        final hDest = potentials[dest] ?? 0.0;
        // dist(u, v) = dist'(u, v) - h(u) + h(v)
        distances[(source, dest)] = reweightedDist - hSource + hDest;
      }
    }

    return JohnsonResult.success(distances);
  }

  /// Returns `true` when the graph contains a negative-weight cycle.
  static bool hasNegativeCycle<N, E>(
    WeightedWalkable<N, E> graph, {
    WeightAlgebra<E>? algebra,
  }) {
    final alg = _resolveAlgebra<E>(algebra);
    final nodes = graph.nodeIds.toList();
    return _computePotentials(graph, nodes, alg) == null;
  }

  /// Computes Johnson's node potentials using Bellman-Ford from a virtual
  /// source with zero-weight edges to every real node.
  ///
  /// Returns `null` when a negative cycle is detected.
  static Map<int, double>? _computePotentials<N, E>(
    WeightedWalkable<N, E> graph,
    List<int> nodes,
    WeightAlgebra<E> alg,
  ) {
    final distances = <int, double>{};
    for (final node in nodes) {
      distances[node] = alg.toDouble(alg.zero);
    }

    final edges = <(int, int, double)>[];
    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        edges.add((u, v, alg.toDouble(edgeValue(graph, u, v, alg))));
      }
    }

    for (var i = 0; i < nodes.length - 1; i++) {
      var changed = false;
      for (final (u, v, weight) in edges) {
        final distU = distances[u];
        if (distU == null) continue;
        final newDist = distU + weight;
        final cur = distances[v];
        if (cur == null || newDist < cur) {
          distances[v] = newDist;
          changed = true;
        }
      }
      if (!changed) break;
    }

    for (final (u, v, weight) in edges) {
      final distU = distances[u];
      if (distU == null) continue;
      final newDist = distU + weight;
      final cur = distances[v];
      if (cur == null || newDist < cur) return null;
    }

    return distances;
  }

  /// Internal double-based Dijkstra that reads via `edgeWeight` (double).
  /// Used on the reweighted graph where edgeWeight already applies h(u)-h(v).
  static Map<int, double> _dijkstraDoubles<N, E>(
    WeightedWalkable<N, E> graph,
    int source,
  ) {
    // Inline simple Dijkstra over doubles using edgeWeight.
    final pq = <(double, int)>[];
    void push(double d, int n) {
      pq.add((d, n));
      pq.sort((a, b) => a.$1.compareTo(b.$1));
    }

    push(0.0, source);
    final dist = <int, double>{source: 0.0};

    while (pq.isNotEmpty) {
      final (d, u) = pq.removeAt(0);
      if (d > (dist[u] ?? double.infinity)) continue;
      for (final v in graph.successors(u)) {
        final w = graph.edgeWeight(u, v);
        final nd = d + w;
        if (nd < (dist[v] ?? double.infinity)) {
          dist[v] = nd;
          push(nd, v);
        }
      }
    }
    return dist;
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
