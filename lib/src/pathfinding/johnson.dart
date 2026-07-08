import '../model/graph_kind.dart';
import '../model/roles.dart';
import 'dijkstra.dart';
import 'strategy.dart';

/// Result of a Johnson all-pairs shortest-path query.
///
/// * **Success** — [distances] contains the full matrix and
///   [hasNegativeCycle] is `false`.
/// * **Negative cycle** — [distances] is `null` and [hasNegativeCycle] is
///   `true`.
///
/// Use [distance] for convenient lookups.
class JohnsonResult {
  /// Distance matrix mapping `(from, to)` to shortest distance.
  /// `null` when a negative cycle was detected.
  final Map<(int, int), double>? distances;

  /// `true` when a negative-weight cycle exists in the graph.
  final bool hasNegativeCycle;

  const JohnsonResult._({this.distances, required this.hasNegativeCycle});

  /// Successful query with a valid distance matrix.
  factory JohnsonResult.success(Map<(int, int), double> distances) =>
      JohnsonResult._(distances: distances, hasNegativeCycle: false);

  /// A negative cycle was detected; the distance matrix is undefined.
  factory JohnsonResult.negativeCycle() =>
      const JohnsonResult._(hasNegativeCycle: true);

  /// Returns the shortest distance from [from] to [to], or `null` when
  /// no path exists or a negative cycle was detected.
  double? distance(int from, int to) => distances?[(from, to)];

  @override
  String toString() {
    if (hasNegativeCycle) return 'JohnsonResult(negativeCycle)';
    return 'JohnsonResult(${distances?.length} entries)';
  }
}

/// Reweighted view of a graph used during Johnson's algorithm.
///
/// Delegates every query to the underlying graph except [edgeWeight],
/// which applies the Johnson reweighting formula
/// `w'(u, v) = w(u, v) + h(u) - h(v)`.
class _ReweightedGraph<N, E> implements WeightedWalkable<N, E> {
  final WeightedWalkable<N, E> _graph;
  final Map<int, double> _potentials;
  final double Function(double, double) _add;
  final double Function(double, double) _subtract;
  final double _zero;

  _ReweightedGraph(
    this._graph,
    this._potentials,
    this._add,
    this._subtract,
    this._zero,
  );

  @override
  GraphKind get kind => _graph.kind;

  @override
  bool get isEmpty => _graph.isEmpty;

  @override
  int get nodeCount => _graph.nodeCount;

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
    final weight = _graph.edgeWeight(from, to);
    final hFrom = _potentials[from] ?? _zero;
    final hTo = _potentials[to] ?? _zero;
    // w'(u, v) = w(u, v) + h(u) - h(v)
    return _add(weight, _subtract(hFrom, hTo));
  }
}

/// Johnson's algorithm for all-pairs shortest paths.
///
/// Computes shortest paths between every pair of nodes by reweighting the
/// graph to eliminate negative edges, then running Dijkstra's algorithm from
/// every node.  Best suited for sparse graphs where Floyd-Warshall's
/// O(V³) cost would be prohibitive.
///
/// ```dart
/// final result = Johnson.allPairs(graph);
/// if (!result.hasNegativeCycle) {
///   print(result.distance(0, 5)); // shortest 0→5 distance
/// }
/// ```
///
/// The optional [subtract] function is used during reweighting.  It defaults
/// to numeric subtraction and should be the inverse of [add] for the
/// reweighting to be valid.
abstract final class Johnson {
  Johnson._();

  /// Computes shortest paths between all pairs of nodes.
  ///
  /// Returns a [JohnsonResult] containing the full distance matrix,
  /// or indicating a negative cycle.
  ///
  /// **Time complexity:** O(V × E log V)
  ///
  /// **Space complexity:** O(V²)
  static JohnsonResult allPairs<N, E>(
    WeightedWalkable<N, E> graph, {
    double zero = 0.0,
    double Function(double, double)? add,
    double Function(double, double)? subtract,
    int Function(double, double)? compare,
  }) {
    final addFn = add ?? defaultAdd;
    final subtractFn = subtract ?? _defaultSubtract;
    final compareFn = compare ?? defaultCompare;

    final nodes = graph.nodeIds.toList();
    final nodeCount = nodes.length;

    if (nodeCount == 0) {
      return JohnsonResult.success(const {});
    }

    final potentials = _computePotentials(graph, nodes, zero, addFn, compareFn);
    if (potentials == null) {
      return JohnsonResult.negativeCycle();
    }

    final reweighted = _ReweightedGraph<N, E>(
      graph,
      potentials,
      addFn,
      subtractFn,
      zero,
    );

    final distances = <(int, int), double>{};

    for (final source in nodes) {
      final reweightedDistances = Dijkstra.singleSourceDistances(
        reweighted,
        source,
        zero: zero,
        add: add,
        compare: compare,
      );

      final hSource = potentials[source] ?? zero;

      for (final MapEntry(key: dest, value: reweightedDist)
          in reweightedDistances.entries) {
        final hDest = potentials[dest] ?? zero;
        // dist(u, v) = dist'(u, v) - h(u) + h(v)
        final adjusted = addFn(subtractFn(reweightedDist, hSource), hDest);
        distances[(source, dest)] = adjusted;
      }
    }

    return JohnsonResult.success(distances);
  }

  /// Returns `true` when the graph contains a negative-weight cycle.
  ///
  /// This is cheaper than running the full algorithm — it stops after the
  /// Bellman-Ford potential-computation phase.
  static bool hasNegativeCycle<N, E>(
    WeightedWalkable<N, E> graph, {
    double zero = 0.0,
    double Function(double, double)? add,
    int Function(double, double)? compare,
  }) {
    final addFn = add ?? defaultAdd;
    final compareFn = compare ?? defaultCompare;

    final nodes = graph.nodeIds.toList();
    return _computePotentials(graph, nodes, zero, addFn, compareFn) == null;
  }

  /// Computes Johnson's node potentials using Bellman-Ford from a virtual
  /// source connected to every node with a zero-weight edge.
  ///
  /// Returns `null` when a negative cycle is detected.
  static Map<int, double>? _computePotentials<N, E>(
    WeightedWalkable<N, E> graph,
    List<int> nodes,
    double zero,
    double Function(double, double) add,
    int Function(double, double) compare,
  ) {
    final nodeCount = nodes.length;
    final distances = <int, double>{};

    // The virtual source gives every real node an initial distance of zero.
    for (final node in nodes) {
      distances[node] = zero;
    }

    final edges = <(int from, int to, double weight)>[];
    for (final u in nodes) {
      for (final v in graph.successors(u)) {
        edges.add((u, v, graph.edgeWeight(u, v)));
      }
    }

    // V - 1 relaxation passes with early termination.
    for (var i = 0; i < nodeCount - 1; i++) {
      var changed = false;
      for (final (u, v, weight) in edges) {
        final distU = distances[u];
        if (distU == null) continue;

        final newDist = add(distU, weight);
        final currentDist = distances[v];
        if (currentDist == null || compare(newDist, currentDist) < 0) {
          distances[v] = newDist;
          changed = true;
        }
      }
      if (!changed) break;
    }

    // One more pass to detect negative cycles.
    for (final (u, v, weight) in edges) {
      final distU = distances[u];
      if (distU == null) continue;

      final newDist = add(distU, weight);
      final currentDist = distances[v];
      if (currentDist == null || compare(newDist, currentDist) < 0) {
        return null;
      }
    }

    return distances;
  }

  static double _defaultSubtract(double a, double b) => a - b;
}
